'use strict'

window.IndexCtrl = ($scope, $location, SessionManager) ->
  user_id = SessionManager.get 'user_id'
  if user_id
    $location.path '/main'
    return

window.MainCtrl = ($scope, $location, SessionManager) ->
  user_id = SessionManager.get 'user_id'
  if not user_id
    $location.path '/user/login'
    return

window.UserLoginCtrl = ($scope, $location, SessionManager, UserManager) ->
  $scope.$watch 'user', (newValue, oldValue) ->
    $scope.credentialsInvalid = false unless angular.equals newValue, oldValue
  , true

  $scope.login = ->
    d = UserManager.login $scope.user.email, $scope.user.password
    d.success (res) ->
      user_id = ~~res
      if user_id > 0
        SessionManager.set 'user_id', user_id
        $location.path '/main'
      else
        $scope.credentialsInvalid = true

window.UserLogoutCtrl = ($scope, $location, SessionManager) ->
  user_id = SessionManager.get 'user_id'
  if not user_id
    $location.path '/user/login'
    return

window.CampaignCtrl = ($scope, SessionManager, CampaignManager, AuctionManager) ->
  user_id = SessionManager.get 'user_id'
  if not user_id
    $location.path '/user/login'
    return

  # campaigns can be opened/created and deleted

window.CampaignCreateCtrl = ($scope, SessionManager, CampaignManager, AuctionManager) ->
  campaign_id = SessionManager.get 'campaign_id'
  auction_id = SessionManager.get 'auction_id'

  auction_id = 99

  if campaign_id
    campaign = CampaignManager.get campaign_id
    auction = AuctionManager.get campaign.auction_id
  else if auction_id
    auction = AuctionManager.get auction_id
    campaign = CampaignManager.create auction.id
    SessionManager.set 'campaign_id', campaign.id

  $scope.auction = auction
  $scope.campaign = campaign

  $scope.getActiveSlots = ->
    _.filter campaign.slots, (slot) -> slot.active or slot.forced

  $scope.$watch 'campaign.restrictions', (newValue, oldValue) ->
    campaign.applyRestrictions()
  , true


window.CampaignCreateCalendarCtrl = ($scope, $location, SessionManager, CampaignManager, AuctionManager) ->
  #auction = $scope.auction = AuctionManager.get 99
  #campaign = $scope.campaign = CampaignManager.create auction.id
  #SessionManager.set 'campaign_id', campaign.id
  user_id = SessionManager.get 'user_id'
  if not user_id
    $location.path '/user/login'
    return
  
  campaign_id = SessionManager.get 'campaign_id'
  if not campaign_id
    $location.path('/campaign')
    return

  campaign = $scope.campaign = CampaignManager.get campaign_id
  auction = $scope.auction = AuctionManager.get campaign.auction_id

window.CampaignCreateTargetTweakCtrl = ($scope, $location, SessionManager, CampaignManager, AuctionManager) ->
  #auction = $scope.auction = AuctionManager.get 99
  #campaign = $scope.campaign = CampaignManager.create auction.id
  #SessionManager.set 'campaign_id', campaign.id
  user_id = SessionManager.get 'user_id'
  if not user_id
    $location.path '/user/login'
    return

  campaign_id = SessionManager.get 'campaign_id'
  if not campaign_id
    $location.path('/campaign')
    return

  campaign = $scope.campaign = CampaignManager.get campaign_id
  auction = $scope.auction = AuctionManager.get campaign.auction_id
  



UserLoginCtrl.$inject = ['$scope', '$location', 'SessionManager', 'UserManager']
CampaignCreateCtrl.$inject = ['$scope', 'SessionManager', 'CampaignManager','AuctionManager']
CampaignCreateCalendarCtrl.$inject = ['$scope', '$location', 'SessionManager', 'CampaignManager','AuctionManager']
CampaignCreateTargetTweakCtrl.$inject = ['$scope', '$location', 'SessionManager', 'CampaignManager','AuctionManager']
