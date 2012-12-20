'use strict'

mockCampaign =
  id: 1
  user_id: 1
  auction_id: 1
  budget: 100
  target:
    type: 'reach'
    quantity: 303
  restrictions:
    timeframe:
      active: 0
      entries: []
    auction:
      active: 0
      categories: []
  advert:
    name: 'my advert'
    thumb: '/img/example_advert.jpg'
    duration: 45
    tags: [
      'owls'
      'animals'
    ]
  content:
    slots: []

mockAuction =
  id: 1
  from: new Date("2012-01-02 00:00:00")
  to: new Date("2012-01-16 00:00:00")
  categories: [
    'reality'
    'comedy'
    'action'
    'cartoon'
    'documentary'
    'thriller'
    'mystery'
    'animals'
    'historic'
    'romance'
    'sitcom'
    'adult'
  ]
  slots: []

slot_baseline = 100000
slot_price_baseline = 1.0
slot_dates = d3.time.hours(mockAuction.from, mockAuction.to)[0...-1]
slot_reach = (date) ->
  x = (date.getHours()-3)*Math.PI/12
  return -0.2*Math.cos(x)

slot_type = (date, slot_nr) ->
  pr1 = 13
  pr2 = 17
  categoriesRaw = [
    mockAuction.categories[slot_nr % pr1 % mockAuction.categories.length]
    mockAuction.categories[slot_nr % pr2 % mockAuction.categories.length]
  ]
  categories = _.uniq(_.filter categoriesRaw, (cat) ->
    if cat == 'adult' and (date.getHours() < 21 and date.getHours() > 6)
      false
    else
      true
  )



mockAuction.slots = _.map slot_dates, (slot_date, nr) ->
  modifier = slot_reach slot_date, nr
  reach = Math.round(slot_baseline*(1+modifier))
  price = 0.01*Math.round(100*slot_price_baseline*(1+(if modifier>=0 then 1 else -1)*Math.sqrt(Math.abs(modifier))))
  return {
    id: nr
    date: slot_date
    duration: 120
    categories: slot_type(slot_date, nr)
    reach: reach
    price: price
  }


# 
# tvAuction.services
#
module = angular.module 'tvAuction.services' , []

module.factory 'UuidManager' , ['$log', ($log) ->
  uuid = {v4: `function(a,b){for(b=a='';a++<36;b+=a*51&52?(a^15?8^Math.random()*(a^20?16:4):4).toString(16):'-');return b}`} # https://gist.github.com/1308368
  return uuid
]

module.factory 'UserManager', ['$http','$q','$log', ($http, $q, $log) ->
  return {
    # logs the user in, i.e. returns it's user id and a session token
    login: (email, password) ->
      return $http.post 'user/login', {email:email, password: password}
    # checks if the user is still logged in, returning his user id
    logout: ->
      return $http.get 'user/logout'
    check: ->
      return $http.get 'user/check'
  }

]
module.factory 'CacheManager', ['$http', '$q', '$log', ($http, $q, $log) ->
  _cache = {}
  return {
    get: (key) ->
      _cache[key]
    set: (key, obj) ->
      _cache[key] = obj
  }
]

module.factory 'AuctionManager', ['$http', '$q', '$log', ($http, $q, $log) ->
  class Auction
    constructor: (@id) ->
  Auction.prototype.__proto__ = mockAuction

  $log.log 'initializing AuctionManager'
  _cache = window._auctionCache = {}
  return {
    list: () ->
      d = $q.defer()
      req = $http.get '/auction'
      req.success (res) ->
        d.resolve res
      req.error (res, status) ->
        $log.log status, res
        d.reject (res)
      return d.promise
    get: (auction_id, use_cache) ->
      d = $q.defer()
      if auction_id and use_cache != false and auction_id of _cache
        $log.log 'loading auction from cache:', auction_id
        d.resolve _cache[auction_id]
      else
        $log.log 'loading auction from server:', auction_id
        req = $http.get "/auction/#{auction_id}"
        req.success (res) ->
          res.auction.content = JSON.parse res.auction.content
          _.each res.auction.content.slots, (slot) ->
            slot.date = new Date(slot.date)
          _.each res.reaches, (reach) ->
            reach.content = JSON.parse reach.content
          _cache[auction_id] = res if use_cache != false
          d.resolve res
        req.error (res, status) ->
          $log.log status, res
          d.reject res
      return d.promise
  }
]


module.factory 'CampaignManager', ['AuctionManager', 'UuidManager', '$http', '$q', '$log', (AuctionManager, uuid, $http, $q, $log) ->
  class Campaign
    constructor: (@auction_id) ->
      @id = 0
      @content = {slots: []}
    minBudget: ->
      slot_min_avg = 1
      @advert.duration*slot_min_avg*@target.quantity
    suggestedBudget: ->
      slot_sug_avg = 2
      @advert.duration*slot_sug_avg*@target.quantity
    buildSlots: (auction_slots) ->
      @content.slots[..] = _.map auction_slots, (auction_slot) ->
          _.extend
            active: true
            forced: false
            target: 1
          , auction_slot
    updateReaches: (reaches) ->
      for slot,i in @content.slots
        slot.target = reaches[i]
    applyTimeRestrictions: (chain) ->
      restrictions = if ~~@restrictions.timeframe.active then @restrictions.timeframe.entries else false
      for slot in @content.slots
        continue if chain and not slot.active
        slot.active = restrictions == false or not _.find restrictions, (restriction) ->
          restriction[0] == slot.date.getHours() and restriction[1] == slot.date.getDay()
    applyCategoryRestrictions: (chain) ->
      restrictions = if ~~@restrictions.auction.active==1 then @restrictions.auction.categories else false
      for slot in @content.slots
        continue if chain and not slot.active
        slot.active = restrictions == false or _.find restrictions, (restriction) ->
          restriction in slot.categories
    applyRestrictions: ->
      @applyTimeRestrictions false
      @applyCategoryRestrictions true


  Campaign.prototype.__proto__ = mockCampaign

  $log.log 'initializing CampaignManager'
  _cache = {}
  return {
    create: (auction_id, use_cache) ->
      campaign = new Campaign auction_id
      _cache[auction_id] = campaign if use_cache != false
      return campaign

    list: (params) ->
      d = $q.defer()
      req = $http.get 'campaign', params
      req.success (res) ->
        campaign = new Campaign()
        _.extend campaign, res
        d.resolve campaign
      req.error (res, status) ->
        $log.log status, res
        d.reject res
      return d.promise

    get: (auction_id, use_cache) ->
      d = $q.defer()
      if auction_id and use_cache != false and auction_id of _cache
        $log.log 'loading campaign from cache:', auction_id
        d.resolve _cache[auction_id]
      else
        $log.log 'loading campaign from server:', auction_id
        req = $http.get "campaign/#{auction_id}"
        req.success (res) ->
          campaign = new Campaign auction_id
          _.extend campaign, res
          _cache[auction_id] = res if use_cache != false
          d.resolve res
        req.error (res, status) ->
          $log.log status, res if status != 404
          d.reject res
      return d.promise

    save: (campaign) ->
      d = $q.defer()
      if not campaign.id
        req = $http.post "campaign/#{campaign.auction_id}", campaign
      else
        req = $http.put "campaign/#{campaign.auction_id}", campaign
      req.success (campaign_id) ->
        campaign.id = campaign_id
        d.resolve campaign_id
      req.error (res, status) ->
        $log.log status, res
        d.reject res
      return d.promise

    delete: (auction_id) ->
      d = $q.defer()
      req = $http.delete "campaign/#{campaign.auction_id}"
      req.success (rows) ->
        d.resolve rows
      req.error (res, status) ->
        $log.log status, res
        d.reject res
      return d.promise
  }
]

module.factory 'CampaignLoader', ['$q','$log','AuctionManager','CampaignManager', ($q, $log, AuctionManager, CampaignManager) ->
  return {
    'get': (auction_id, user_id) ->
      d = $q.defer()
      req = AuctionManager.get auction_id
      req.then (res) ->
        auction = res.auction
        reaches = res.reaches
        req = CampaignManager.get auction_id, user_id
        req.then(
          (res) ->
            $log.log 'campaign loaded'
            campaign = res
            d.resolve [campaign, auction, reaches]
          , ->
            $log.log 'creating new campaign object'
            campaign = CampaignManager.create auction_id
            campaign.buildSlots auction.content.slots
            d.resolve [campaign, auction, reaches]
        )
        return d.promise      
  }
]

module.value 'version','0.1'

