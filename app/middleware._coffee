'use strict'


__ = require 'underscore'
zmq = require 'zmq'


class AuctionModel
  @get_and_look_query = 'SELECT id, state, `from`, to FROM auction WHERE state = "searching" ORDER BY deadline'
  @change_status_query = 'UPDATE auction SET state = ? WHERE state = ? AND id = ?'
  constructor: (@db) ->
  getAndLock: (_) ->
    auctions_data = @db.query AuctionModel.get_and_look_query, _
    # if there is no auction that needs solving return
    return null unless auctions_data.length
    for auction_data in auctions_data
      changed = @changeStatus auction_data.id, 'searching', 'solving', _
      return auction_data if changed # only return the auction if we could change state
    return null

  getOptions: (id) ->
    # TODO implement custom settings or at least db-bound settings
    return {}

  changeStatus: (id, from, to, _) ->
    res = @db.query AuctionModel.change_status_query, [from, to, id], _
    return res.changedRows
    
  saveResult: (id, data, _) ->
    @db.query 'INSERT INTO auction_data (auction_id, content) VALUES (?,?)', [id, data], _
    return rows.length

  transform: (auction_data) ->
    # Slot = namedtuple('Slot', ('id','price','length'))
    slots = []
    auction_content = JSON.parse auction_data.content
    for slot_data in auction_content.slots
      slot = [slot_data.id, slot_data.price, slot_data.duration]
      slots.push slot
    return slots


class CampaignModel
  constructor: (@db) ->
  getAll: (auction_id, _) ->
    campaigns_data = @db.query 'SELECT * from campaign WHERE auction_id = ? AND published = 1', [auction_id], _
    return campaigns_data

  transformSingle: (campaign_data) ->
    # BidderInfo = namedtuple('BidderInfo', ('id','length','bids','attrib_values'))
    # bids: [price, min_attrib], attrib_values = {slot_id: value}
    campaign_content = JSON.parse campaign.content
    bidder_info = [
      campaign_data.user_id
      campaign_content.advert.duration
      [bid.target, bid.quantity] for bid in campaign_content.targets
    ]
    attrib_values = {}
    for slot in campaign_content.slots
      attrib_values[slot.id] = qty if slot.active || slot.forced
    bidder_info.push attrib_values
    return bidder_info

  transform: (campaigns_data) ->
    bidder_infos = []
    for campaign_data in campaigns_data
      bidder_infos.push @transformSingle(campaign_data)
    return bidder_infos

class Middleware
  constructor: (@auction_m, @campaign_m, @socket_pub, @socket_rr) ->
    # bind onMessage method to the req/rep socket
    @socket_rr.on 'message', @onMessage

  onMessage: (data, _) ->
    [action, error, auction_id, params...] = JSON.parse data

    if error and action == 'solve'
      #put auction status on searching again
      @auction_m.changeStatus auction_id, 'solving', 'searching', _

    if error
      console.error "Error: #{action} (#{params}) - #{error}" # FIXME logging
      return

    if action == 'is_free' and auction_id
      auction_data = @auction_m.getAndLock _
      if not auction_data
        socket_rr.send()
      else
        options = @auction_m.getOptions auction_id
        campaign_data = @campaign_m.getAll auction_id, _
        slots = @auction_m.transform auction_data
        bidder_infos = @campaign_m.transform campaign_data
        scenario = [slots, bidder_infos]
        socket_rr.send JSON.stringify(['solve', auction_id, scenario, options])
    else if action == 'solve'
      @auction_m.changeStatus auction_id, 'solving', 'solved', _
      @auction_m.saveResult auction_id, params, _
      #put auction status on solved, save results
      socket.send()

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

