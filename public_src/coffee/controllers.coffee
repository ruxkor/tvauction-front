'use strict'

# set global object for coffeescript
global = window if typeof global == 'undefined'


global.IndexCtrl = ($scope, $location, CacheManager) ->
  user_id = CacheManager.get 'user_id'
  if user_id
    $location.path '/main'
    return

global.MainCtrl = ($scope, $location, CacheManager) ->
  user_id = CacheManager.get 'user_id'
  if not user_id
    $location.path '/user/login'
    return

global.HelpCtrl = ($scope, $location) ->


global.UserLoginCtrl = ($scope, $location, CacheManager, UserManager) ->
  $scope.$watch 'user', (newValue, oldValue) ->
    $scope.credentialsInvalid = false unless angular.equals newValue, oldValue
  , true

  $scope.login = ->
    d = UserManager.login $scope.user.email, $scope.user.password
    d.success (res) ->
      user_id = ~~res
      if user_id > 0
        CacheManager.set 'user_id', user_id
        $location.path '/auction'
      else
        $scope.credentialsInvalid = true

global.UserLogoutCtrl = ($scope, $location, UserManager) ->
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


global.AuctionCtrl = ($scope, $window, UserManager, AuctionManager) ->
  d = UserManager.check()
  d.success (user_id) ->
    if not user_id
      $location.path '/user/login'
      return

    $scope.now = new Date()

    d = AuctionManager.list()
    d.then (auctions) ->
      $scope.auctions = auctions

global.AuctionViewCtrl = ($scope, $routeParams, $window, UserManager, AuctionManager) ->
  d = UserManager.check()
  d.success (user_id) ->
    if not user_id
      $location.path '/user/login'
      return

    auction_id = ~~$routeParams.auction_id
    d = AuctionManager.get auction_id
    d.then (res) ->
      $scope.auction = res.auction
      $scope.reaches = res.reaches
      $scope.reach_active = res.reaches[0]

global.CampaignCtrl = ($scope, $window, UserManager, CampaignManager, AuctionManager) ->
  d = UserManager.check()
  d.success (user_id) ->
    if not user_id
      $location.path '/user/login'
      return

    # $window.onbeforeunload = null

    d = CampaignManager.list()
    d.then (campaigns) ->
      $scope.campaigns = campaigns

global.CampaignDetailCtrl = ($scope, $routeParams, $log, $location, $window, UserManager, CampaignLoader, CampaignManager, AuctionManager) ->
  d = UserManager.check()
  d.success (user_id) ->
    if not user_id
      $location.path '/'
      return

    # $window.onbeforeunload = -> 'All entered data will be lost if you did not save your data.'
    auction_id = ~~$routeParams.auction_id

    d = CampaignLoader.get auction_id, user_id
    d.then (res) -> 
      [$scope.campaign, $scope.auction, $scope.reaches] = res

  $scope.getActiveSlots = ->
    if $scope.campaign then _.filter $scope.campaign.content.slots, (slot) -> slot.active or slot.forced else []

  $scope.$watch 'campaign.restrictions', (newValue, oldValue) ->
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
    d.then (res) -> $scope.campaign.published = 1

  $scope.unpublishCampaign = ->    
    campaign_reduced = _.pick $scope.campaign, ['id', 'auction_id', 'user_id']
    campaign_reduced.published = 0
    d = CampaignManager.save campaign_reduced
    d.then (res) -> $scope.campaign.published = 0

  $scope.deleteCampaign = ->
    auction_id = $scope.campaign.auction_id
    d = CampaignManager.delete auction_id
    d.then (res) ->
      $log.log 'successfully deleted'
      $scope.campaign = CampaignManager.create auction_id

  
  $scope.incrementTarget = ->
    $scope.campaign.content.targets.push {quantity:0, budget: 0}

  $scope.decrementTarget = ->
    $scope.campaign.content.targets.pop()

global.CampaignDetailCalendarCtrl = ($scope, $routeParams, $log, $location, $window, UserManager, CampaignLoader, CampaignManager, AuctionManager) ->
  d = UserManager.check()
  d.success (user_id) ->
    if not user_id
      $location.path '/user/login'
      return

    # $window.onbeforeunload = -> 'All entered data will be lost if you did not save your data.'
    auction_id = ~~$routeParams.auction_id

    d = CampaignLoader.get auction_id, user_id
    d.then (res) -> [$scope.campaign, $scope.auction, $scope.reaches] = res


global.CampaignDetailTargetTweakCtrl = ($scope, $routeParams, $log, $location, $window, UserManager, CampaignLoader, CampaignManager, AuctionManager) ->
  d = UserManager.check()
  d.success (user_id) ->
    if not user_id
      $location.path '/user/login'
      return

    # $window.onbeforeunload = -> 'All entered data will be lost if you did not save your data.'
    auction_id = ~~$routeParams.auction_id

    d = CampaignLoader.get auction_id, user_id
    d.then (res) -> 
      [$scope.campaign, $scope.auction, $scope.reaches] = res

    $scope.$watch 'reach_active', (newValue, oldValue) ->
      if newValue != oldValue
        if not oldValue and not confirm('do you want to reset your custom target values?')
          $scope.reach_active = null
        else
          $scope.campaign.updateReaches newValue.content.slot_reaches
    
    $scope.slotTrigger = true


# HelpCtrl.$inject = ['$scope', '$location']
# UserLoginCtrl.$inject = ['$scope', '$location', 'CacheManager', 'UserManager']
# UserLogoutCtrl.$inject = ['$scope', '$location', 'UserManager']
# CampaignDetailCtrl.$inject = ['$scope', '$q', '$routeParams', '$log', '$location', 'UserManager', 'CacheManager', 'CampaignManager','AuctionManager']
# CampaignDetailCalendarCtrl.$inject = ['$scope', '$location', 'UserManager', 'CacheManager', 'CampaignManager','AuctionManager']
# CampaignDetailTargetTweakCtrl.$inject = ['$scope', '$location', 'UserManager', 'CacheManager', 'CampaignManager','AuctionManager']
