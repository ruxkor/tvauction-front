'use strict'

CampaignCreateCtrl = ($scope, CampaignManager, AuctionManager) ->
  campaign_id = 10

  campaign = $scope.campaign = CampaignManager.get campaign_id
  auction = $scope.auction = AuctionManager.get campaign.auction_id
#  setTimeout ->
#    campaign.name = 'uiui'
#    $scope.$digest()
#  ,1000
#


CampaignCreateCalendarCtrl = ($scope, CampaignManager, AuctionManager) ->
  campaign_id = 10
  campaign = $scope.campaign = CampaignManager.get campaign_id
  auction = $scope.auction = AuctionManager.get campaign.auction_id



CampaignCreateCtrl.$inject = ['$scope', 'CampaignManager','AuctionManager']
CampaignCreateCalendarCtrl.$inject = ['$scope', 'CampaignManager','AuctionManager']
