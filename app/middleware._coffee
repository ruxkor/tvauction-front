'use strict'


__ = require 'underscore'
zmq = require 'zmq'

debug = require('debug')('tvauction:middleware')

MAX_DELAY = Math.pow(2,31)-1

class AuctionModel
  
  @get_and_lock_query = 'SELECT id, state, `from`, `to`, content FROM auction WHERE state = "searching" ORDER BY deadline'
  @change_status_query = 'UPDATE auction SET state = ? WHERE state = ? AND id = ?'

  constructor: (@db) ->

  getAndLock: (_) ->
    auctions_data = @db.query AuctionModel.get_and_lock_query, _
    # if there is no auction that needs solving return
    return null unless auctions_data.length
    for auction_data in auctions_data
      changed = @changeStatus auction_data.id, 'searching', 'solving', _
      return auction_data if changed # only return the auction if we could change state
    return null

  getAll: (_) ->
    auctions = @db.query 'SELECT id, state, deadline FROM auction WHERE state IN ("open","searching")', _
    return auctions

  getOptions: (id) ->
    # TODO implement custom settings or at least db-bound settings
    options =
      timeLimit: 20
      timeLimitGwd: 20
    return options

  changeStatus: (id, from, to, _) ->
    debug 'changeStatus - id: %d, from: %s, to: %s', id, from, to
    res = @db.query AuctionModel.change_status_query, [to, from, id], _
    return res.changedRows
    
  saveResult: (id, result, _) ->
    debug 'saveResult - id: %d', id
    revenue = (v for k,v of result.prices_final).reduce(((a,b) -> a+b),0)
    rows = @db.query 'INSERT INTO result (auction_id, revenue, content) VALUES (?,?,?)', [id, revenue, JSON.stringify(result)], _
    return rows.length

  transform: (auction_data) ->
    debug 'transform - auction_id: %d', auction_data.id
    # Slot = namedtuple('Slot', ('id','price','length'))
    slots = {}
    auction_content = JSON.parse auction_data.content
    for slot_data in auction_content.slots
      slots[slot_data.id] = 
        id: slot_data.id
        price: slot_data.price
        length: slot_data.duration
    return slots


class CampaignModel
  @get_published_query = 'SELECT * from campaign WHERE auction_id = ? AND published = 1'

  constructor: (@db) ->

  getAll: (auction_id, _) ->
    debug 'getAll - auction_id: %d', auction_id
    campaigns_data = @db.query CampaignModel.get_published_query, [auction_id], _
    return campaigns_data

  transformSingle: (campaign_data) ->
    # BidderInfo = namedtuple('BidderInfo', ('id','length','bids','attrib_values'))
    # bids: [price, min_attrib], attrib_values = {slot_id: value}
    debug 'transform single'
    campaign_content = JSON.parse campaign_data.content
    attrib_values = {}
    for slot in campaign_content.slots
      attrib_values[slot.id] = slot.target if (slot.active or slot.forced)
    bidder_info =
      id: campaign_data.user_id
      length: campaign_content.advert.duration
      bids: [bid.budget, bid.quantity] for bid in campaign_content.targets
      attrib_values: attrib_values
    return bidder_info

  transform: (campaigns_data) ->
    debug 'transform campaigns'
    bidder_infos = {}
    for campaign_data in campaigns_data
      bidder_infos[campaign_data.user_id] = @transformSingle(campaign_data)
    return bidder_infos

class Middleware
  @refresh_delay = 60000

  constructor: (@auction_m, @campaign_m, @socket_pub, @socket_rr) ->
    that = @
    @auction_timers = {}

    # bind onMessage method to the req/rep socket
    @socket_rr.on 'message', (data, _) -> that.handleMessage(data,_)

  handleMessage: (data, _) ->
    [action, error, param, params...] = JSON.parse data
    debug 'handleMessage - action: %s, param: %d, error: %s', action, param, error
    response = ''
    if error and action == 'solve'
      #put auction status on searching again
      @auction_m.changeStatus param, 'solving', 'searching', _

    else if error
      # TODO better logging
      console.error "Error: #{action} (#{params}) - #{error}"

    else if action == 'solve'
      @auction_m.changeStatus param, 'solving', 'solved', _
      @auction_m.saveResult param, params[0], _

    else if action == 'is_free' and param
      auction_data = @auction_m.getAndLock _
      if auction_data
        auction_id = auction_data.id
        options = @auction_m.getOptions auction_id
        campaigns_data = @campaign_m.getAll auction_id, _
        slots = @auction_m.transform auction_data
        bidder_infos = @campaign_m.transform campaigns_data
        scenario = [slots, bidder_infos]
        response = JSON.stringify ['solve', auction_id, scenario, options]
    @socket_rr.send response

  refresh: (_) ->
    debug 'refreshing'
    that = @

    clearTimeout @refresh_timer

    # get auctions from db and set up timers
    for auction_id,auction_timer of @auction_timers
      clearTimeout auction_timer

    auctions = @auction_m.getAll _
    now = new Date()
    for auction in auctions
      delay = auction.deadline-now
      continue if delay > MAX_DELAY
      @auction_timers[auction.id] = setTimeout(
        (id, state, _) -> that.closeAuction(id, state, _),
        delay, auction.id, auction.state
      )

    @refresh_timer = setTimeout(
      (_) -> that.refresh(_)
      Middleware.refresh_delay
    )

  closeAuction: (auction_id, auction_state, _) ->
    debug 'closing auction %d', auction_id
    @auction_m.changeStatus auction_id, 'open', 'searching', _ if auction_state == 'open'
    @socket_pub.send JSON.stringify(['is_free'])



exports.Middleware = Middleware
exports.AuctionModel = AuctionModel
exports.CampaignModel = CampaignModel

exports.init = (config, db) ->
  socket_pub = zmq.socket 'pub'
  socket_rr = zmq.socket 'rep'
  socket_pub.bindSync config.middleware.pub
  socket_rr.bindSync config.middleware.rr
  auction_m = new AuctionModel db
  campaign_m = new CampaignModel db
  middleware = new Middleware auction_m, campaign_m, socket_pub, socket_rr

