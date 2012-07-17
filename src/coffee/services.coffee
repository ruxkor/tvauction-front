# 'use strict'

mockCampaign =
  id: 1
  user_id: 1
  auction_id: 1
  target_type: 'reach'
  target: 300
  budget: 100
  restrictions:
    timeframe:
      active: 0
    auction:
      active: 1
  advert:
    name: 'my advert'
    thumb: 'img/example_advert.jpg'
    duration: 45
    tags: [
      'owls'
      'animals'
    ]
  slots: [
      id: 10
      active: true
      target: 100
    ,
      id: 12
      active: true
      target: 100
    ,
      id: 15
      active: true
      target: 100
  ]

mockAuction =
  id: 1
  from: new Date("2012-01-02 00:00:00")
  to: new Date("2012-01-16 00:00:00")
  slots: {id: i, duration: 120, reach: 1000} for i in [0...20]

module = angular.module 'tvAuction.services' , []

module.factory 'Slot', ->
  class Slot
    @$inject: ['$http','$q','$log']
    constructor: (@$http, @$q, $log) ->
      $log.log 'initializing Slot'
    get: (id) ->
      {
        id: id
        length: 120
        price: 1.0
      }


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


module.factory 'CampaignManager', ['$http', '$q', '$log', ($http, $q, $log) ->
  class Campaign
    constructor: (@id) ->
    minBudget: ->
      1000.00
    suggestedBudget: ->
      2000.00
    setSuggestedBudget: ->
      @budget = @suggestedBudget()
  Campaign.prototype.__proto__ = mockCampaign

  $log.log 'initializing CampaignManager'
  _cache = {}
  return {
    get: (id) ->
      if id not of _cache
        _cache[id] = new Campaign(id)
      return _cache[id]
  }
]


module.value 'version','0.1'

