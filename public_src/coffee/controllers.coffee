'use strict'

# set global object for coffeescript
global = window if typeof global == 'undefined'


global.IndexCtrl = ($scope, $location, UserManager) ->
  d = UserManager.check()
  d.then (user_id) ->
    $location.path '/auction' if user_id
    return

global.HelpCtrl = ($scope, $location) ->
  

global.UserLoginCtrl = ($scope, $location, CacheManager, UserManager) ->
  d = UserManager.checkRedirect(true)
  d.then (user_id) ->

    $scope.$watch 'user', (newValue, oldValue) ->
      $scope.credentialsInvalid = false unless angular.equals newValue, oldValue
    , true

    $scope.login = ->
      d = UserManager.login $scope.user.email, $scope.user.password
      d.then (res) ->
        user_id = ~~res
        if user_id > 0
          CacheManager.set 'user_id', user_id
          $location.path '/auction'
        else
          $scope.credentialsInvalid = true

global.UserLogoutCtrl = ($scope, $location, UserManager) ->
  d = UserManager.checkRedirect()
  d.then (user_id) ->
  
    $scope.successful = null

    d = UserManager.logout()
    d.then (res) ->
      $scope.successful = true
      setTimeout ->
        $location.path '/'
        $scope.$apply()
      , 1000
    , (res) ->
      $scope.successful = false


global.AuctionCtrl = ($scope, UserManager, AuctionManager) ->
  d = UserManager.checkRedirect()
  d.then (user_id) ->
    
    $scope.now = new Date()
    d = AuctionManager.list()
    d.then (auctions) ->
      $scope.auctions = auctions

global.AuctionViewCtrl = ($scope, $routeParams, UserManager, AuctionManager) ->
  d = UserManager.checkRedirect()
  d.then (user_id) ->

    auction_id = ~~$routeParams.auction_id
    d = AuctionManager.get auction_id
    d.then (res) ->
      $scope.auction = res.auction
      $scope.reaches = res.reaches
      $scope.reach_active = res.reaches[0]

global.CampaignCtrl = ($scope, $window, UserManager, CampaignManager, AuctionManager) ->
  d = UserManager.checkRedirect()
  d.then (user_id) ->

    # $window.onbeforeunload = null
    d = CampaignManager.list()
    d.then (campaigns) ->
      $scope.campaigns = campaigns

global.CampaignDetailCtrl = ($scope, $routeParams, $log, $location, $window, $dialog, UserManager, CampaignLoader, CampaignManager, AuctionManager) ->
  loadCampaign = (auction_id) ->
    d = CampaignLoader.get auction_id
    d.then (res) -> 
      [$scope.campaign, $scope.auction, $scope.reaches] = res

  d = UserManager.checkRedirect()
  d.then (user_id) ->

    auction_id = ~~$routeParams.auction_id  

    # $window.onbeforeunload = -> 'All entered data will be lost if you did not save your data.'
    loadCampaign auction_id

  $scope.getActiveSlots = ->
    if $scope.campaign then _.filter $scope.campaign.content.slots, (slot) -> slot.active or slot.forced else []

  $scope.$watch 'campaign.content.restrictions', (newValue, oldValue) ->
    $scope.campaign.applyRestrictions() if $scope.campaign
  , true

  $scope.saveCampaign = ->
    d = CampaignManager.save $scope.campaign
    d.then (res) ->
      $log.log 'successfully saved', res

  $scope.publishCampaign = ->
    campaign_reduced = _.pick $scope.campaign, ['id', 'auction_id', 'user_id']
    campaign_reduced.published = 1
    d = CampaignManager.save campaign_reduced
    d.then (res) -> 
      $scope.campaign.published = 1
      $log.log 'successfully published', res

  $scope.unpublishCampaign = ->    
    campaign_reduced = _.pick $scope.campaign, ['id', 'auction_id', 'user_id']
    campaign_reduced.published = 0
    d = CampaignManager.save campaign_reduced
    d.then (res) -> 
      $scope.campaign.published = 0
      $log.log 'successfully unpublished', res

  $scope.deleteCampaign = ->
    auction_id = $scope.campaign.auction_id
    d = CampaignManager.delete auction_id
    d.then (res) ->
      $log.log 'successfully deleted', res
      loadCampaign auction_id
      $dialog
        .messageBox('Cleared', 'The campaign was successfully cleared.', [{label:'continue',result:'continue'},{label:'return to campaigns',result:'return'}])
        .open()
        .then (res) ->
          $location.path '/campaign' if res == 'return'
  
  $scope.incrementTarget = ->
    $scope.campaign.content.targets.push {quantity:0, budget: 0}

  $scope.decrementTarget = ->
    $scope.campaign.content.targets.pop()

global.CampaignDetailCalendarCtrl = ($scope, $routeParams, $log, $window, UserManager, CampaignLoader, CampaignManager, AuctionManager) ->
  d = UserManager.checkRedirect()
  d.then (user_id) ->

    # $window.onbeforeunload = -> 'All entered data will be lost if you did not save your data.'
    auction_id = ~~$routeParams.auction_id

    d = CampaignLoader.get auction_id
    d.then (res) -> [$scope.campaign, $scope.auction, $scope.reaches] = res


global.CampaignDetailTargetTweakCtrl = ($scope, $routeParams, $log, $window, UserManager, CampaignLoader, CampaignManager, AuctionManager) ->
  d = UserManager.checkRedirect()
  d.then (user_id) ->

    # $window.onbeforeunload = -> 'All entered data will be lost if you did not save your data.'
    auction_id = ~~$routeParams.auction_id

    d = CampaignLoader.get auction_id
    d.then (res) -> 
      [$scope.campaign, $scope.auction, $scope.reaches] = res

    $scope.$watch 'reach_active', (newValue, oldValue) ->
      if newValue != oldValue
        if not oldValue and not confirm('Do you want to reset your custom target values?')
          $scope.reach_active = null
        else
          $scope.campaign.updateReaches newValue.content.slot_reaches
    
    $scope.slotTrigger = true

global.ResultCtrl = ($scope, $routeParams, $log, UserManager, ResultManager, CampaignLoader) ->
  d = UserManager.checkRedirect()
  d.then (user_id) ->

    auction_id = ~~$routeParams.auction_id

    d = CampaignLoader.get auction_id
    d.then (res) -> 
      [$scope.campaign, $scope.auction, $scope.reaches] = res

    d = ResultManager.get auction_id, user_id
    d.then (res) -> 
      $scope.result = res
    
  $scope.getWinningSlots = ->
    return unless $scope.campaign and $scope.result
    slots = {}
    for slot in $scope.campaign.content.slots
      slots[slot.id] = slot if slot.id in $scope.result.slots
    return slots