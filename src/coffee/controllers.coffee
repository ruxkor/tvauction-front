'use strict'

CampaignCreateCtrl = ($scope, SessionManager, CampaignManager, AuctionManager) ->
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


CampaignCreateCalendarCtrl = ($scope, $location, SessionManager, CampaignManager, AuctionManager) ->
  #auction = $scope.auction = AuctionManager.get 99
  #campaign = $scope.campaign = CampaignManager.create auction.id
  #SessionManager.set 'campaign_id', campaign.id
  
  campaign_id = SessionManager.get 'campaign_id'
  if not campaign_id
    $location.path('/campaign/create')
    return

  campaign = $scope.campaign = CampaignManager.get campaign_id
  auction = $scope.auction = AuctionManager.get campaign.auction_id

CampaignCreateTargetTweakCtrl = ($scope, $location, SessionManager, CampaignManager, AuctionManager) ->
  #auction = $scope.auction = AuctionManager.get 99
  #campaign = $scope.campaign = CampaignManager.create auction.id
  #SessionManager.set 'campaign_id', campaign.id

  campaign_id = SessionManager.get 'campaign_id'
  if not campaign_id
    $location.path('/campaign/create')
    return

  campaign = $scope.campaign = CampaignManager.get campaign_id 
  auction = $scope.auction = AuctionManager.get campaign.auction_id
  

MyTestCtrl = ($scope, $location, SessionManager, CampaignManager, AuctionManager) ->
  auction = $scope.auction = AuctionManager.get 99
  campaign = $scope.campaign = CampaignManager.create auction.id
  SessionManager.set 'campaign_id', campaign.id
  window.mySc = $scope
  $scope.slot = campaign.slots[0]

SlotPopupCtrl = ($scope, $location, SessionManager, CampaignManager) ->
  console.info arguments




CampaignCreateCtrl.$inject = ['$scope', 'SessionManager', 'CampaignManager','AuctionManager']
CampaignCreateCalendarCtrl.$inject = ['$scope', '$location', 'SessionManager', 'CampaignManager','AuctionManager']
CampaignCreateTargetTweakCtrl.$inject = ['$scope', '$location', 'SessionManager', 'CampaignManager','AuctionManager']
