'use strict'

window.IndexCtrl = ($scope, $location, CacheManager) ->
  user_id = CacheManager.get 'user_id'
  if user_id
    $location.path '/main'
    return

window.MainCtrl = ($scope, $location, CacheManager) ->
  user_id = CacheManager.get 'user_id'
  if not user_id
    $location.path '/user/login'
    return

window.HelpCtrl = ($scope, $location) ->


window.UserLoginCtrl = ($scope, $location, CacheManager, UserManager) ->
  $scope.$watch 'user', (newValue, oldValue) ->
    $scope.credentialsInvalid = false unless angular.equals newValue, oldValue
  , true

  $scope.login = ->
    d = UserManager.login $scope.user.email, $scope.user.password
    d.success (res) ->
      user_id = ~~res
      if user_id > 0
        CacheManager.set 'user_id', user_id
        $location.path '/main'
      else
        $scope.credentialsInvalid = true

window.UserLogoutCtrl = ($scope, $location, UserManager) ->
  $scope.successful = null

  d = UserManager.logout()
  d.then (res) ->
    $scope.successful = true
    setTimeout ->
      $location.path '/'
      $scope.$apply()
    , 3000
  , (res) ->
    $scope.successful = false


window.AuctionCtrl = ($scope, UserManager, AuctionManager) ->
  d = UserManager.check()
  d.success (user_id) ->
    if not user_id
      $location.path '/user/login'
      return
    d = AuctionManager.list()
    d.success (auctions) ->
      $scope.auctions = auctions

window.AuctionViewCtrl = ($scope, $routeParams, UserManager, AuctionManager) ->
  d = UserManager.check()
  d.success (user_id) ->
    if not user_id
      $location.path '/user/login'
      return

    auction_id = $routeParams.auction
    d = AuctionManager.get auction_id
    d.then (res) ->
      $scope.auction = res.auction
      $scope.reaches = res.reaches
      $scope.reach_active = res.reaches[0]
    $scope.$watch 'reach_active', (newValue, oldValue) ->
      console.info newValue,oldValue

window.CampaignCtrl = ($scope, UserManager, CampaignManager, AuctionManager) ->
  d = UserManager.check()
  d.success (user_id) ->
    if not user_id
      $location.path '/user/login'
      return
    d = CampaignManager.list()
    d.success (campaigns) ->
      $scope.campaigns = campaigns

  # campaigns can be opened/created and deleted

window.CampaignDetailCtrl = ($scope, $q, $routeParams, $log, $location, UserManager, CacheManager, CampaignManager, AuctionManager) ->
  # if the campaign_id is set, we are updating an auction
  d = UserManager.check()
  d.success (user_id) ->
    if not user_id
      $location.path '/'
      return

    campaign_id = ~~$routeParams.campaign
    auction_id = ~~$routeParams.auction

    $scope.campaign = CacheManager.get 'campaign'
    $scope.auction = CacheManager.get 'auction'
    $scope.reaches = CacheManager.get 'reaches'

    d = $q.defer()
    # load the auction if we are creating a new campaign
    if not campaign_id and auction_id and (not $scope.auction or $scope.auction.id != auction_id)
      campaign = CampaignManager.create()
      req = AuctionManager.get auction_id
      req.then (res) ->
        campaign.buildSlots res.auction.content.slots
        campaign.applyRestrictions()
        d.resolve [campaign, res.auction, res.reaches]
    # load the campaign if needed (and then the auction)
    else if campaign_id and (not $scope.campaign or $scope.campaign.id != campaign_id)
      req = CampaignManager.get campaign_id
      req.then (res) ->
        campaign = res
        req = AuctionManager.get campaign.auction_id
        req.then (res) ->
          d.resolve [campaign, res.auction, res.reaches]
    # this means we have valid data
    else
      d.reject()

    d.promise
      .then(
        (res) ->
          $log.log 'data loaded from server'
          [$scope.campaign, $scope.auction, $scope.reaches] = res
          CacheManager.set 'campaign', $scope.campaign
          CacheManager.set 'auction', $scope.auction
          CacheManager.set 'reaches', $scope.reaches
        , -> 
          $log.log 'loading data from cache')
      .then( ->
        if not $scope.campaign
          $location.path '/'
          return
      )

  $scope.getActiveSlots = ->
    if $scope.campaign then _.filter $scope.campaign.content.slots, (slot) -> slot.active or slot.forced else []

  $scope.$watch 'campaign.restrictions', (newValue, oldValue) ->
    $scope.campaign.applyRestrictions() if $scope.campaign
  , true


window.CampaignDetailCalendarCtrl = ($scope, $location, UserManager, CacheManager, CampaignManager, AuctionManager) ->
  d = UserManager.check()
  d.success (user_id) ->
    if not user_id
      $location.path '/user/login'
      return

    $scope.campaign = CacheManager.get 'campaign'
    $scope.auction = CacheManager.get 'auction'
    $scope.reaches = CacheManager.get 'reaches'

    if not $scope.campaign
      $location.path('/')
      return

window.CampaignDetailTargetTweakCtrl = ($scope, $location, UserManager, CacheManager, CampaignManager, AuctionManager) ->
  d = UserManager.check()
  d.success (user_id) ->
    if not user_id
      $location.path '/user/login'
      return

    $scope.campaign = CacheManager.get 'campaign'
    $scope.auction = CacheManager.get 'auction'
    $scope.reaches = CacheManager.get 'reaches'

    if not $scope.campaign
      $location.path('/')
      return
  



HelpCtrl.$inject = ['$scope', '$location']
UserLoginCtrl.$inject = ['$scope', '$location', 'CacheManager', 'UserManager']
UserLogoutCtrl.$inject = ['$scope', '$location', 'UserManager']
CampaignDetailCtrl.$inject = ['$scope', '$q', '$routeParams', '$log', '$location', 'UserManager', 'CacheManager', 'CampaignManager','AuctionManager']
CampaignDetailCalendarCtrl.$inject = ['$scope', '$location', 'UserManager', 'CacheManager', 'CampaignManager','AuctionManager']
CampaignDetailTargetTweakCtrl.$inject = ['$scope', '$location', 'UserManager', 'CacheManager', 'CampaignManager','AuctionManager']
