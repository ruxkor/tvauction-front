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
      active: 1
      entries: [
        [1,0]
        [1,1]
        [2,5]
      ]
    auction:
      active: 1
      categories: []
  advert:
    name: 'my advert'
    thumb: 'img/example_advert.jpg'
    duration: 45
    tags: [
      'owls'
      'animals'
    ]
  slots: []
  #slots: [
      #id: 10
      #active: true
      #target: 100
    #,
      #id: 12
      #active: true
      #target: 100
    #,
      #id: 15
      #active: true
      #target: 100
  #]

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
    check: ->
      return $http.post 'user/check'
  }

]
module.factory 'SessionManager', ['$http', '$q', '$log', ($http, $q, $log) ->
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
  _cache = {}
  return {
    get: (id) ->
      if id not of _cache
        _cache[id] = new Auction(id)
      return _cache[id]
  }
]


module.factory 'CampaignManager', ['AuctionManager', 'UuidManager', '$http', '$q', '$log', (AuctionManager, uuid, $http, $q, $log) ->
  class Campaign
    constructor: (@id) ->
    minBudget: ->
      slot_min_avg = 1
      @advert.duration*slot_min_avg*@target.quantity
    suggestedBudget: ->
      slot_sug_avg = 2
      @advert.duration*slot_sug_avg*@target.quantity
    buildSlots: (auction_slots) ->
      self = @
      @slots[..] = _.map auction_slots, (auction_slot) ->
          _.extend
            active: true
            forced: false
            target: if self.target.type=='reach' then auction_slot.reach else 1
          , auction_slot
    applyTimeRestrictions: (chain) ->
      restrictions = if parseInt(@restrictions.timeframe.active,10) then @restrictions.timeframe.entries else false
      for slot in @slots
        continue if chain and not slot.active
        slot.active = restrictions == false or ! _.find restrictions, (restriction) ->
          restriction[0] == slot.date.getHours() and restriction[1] == slot.date.getDay()
    applyCategoryRestrictions: (chain) ->
      restrictions = if parseInt(@restrictions.auction.active,10)==2 then @restrictions.auction.categories else false
      for slot in @slots
        continue if chain and not slot.active
        slot.active = restrictions == false or _.find restrictions, (restriction) ->
          restriction in slot.categories
      # TODO fix this and think about multiple restriction criteria
    applyRestrictions: ->
      @applyTimeRestrictions false
      @applyCategoryRestrictions true


  Campaign.prototype.__proto__ = mockCampaign

  $log.log 'initializing CampaignManager'
  _cache = {}
  return {
    get: (id) ->
      return _cache[id]
    create: (auction_id) ->
      auction = AuctionManager.get auction_id
      campaign = new Campaign(uuid.v4())
      campaign.buildSlots auction.slots
      campaign.applyTimeRestrictions()
      _cache[campaign.id] = campaign
      return campaign
  }
]


module.value 'version','0.1'

