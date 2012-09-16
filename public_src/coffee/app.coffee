'use strict'

angular
  .module('tvAuction', ['tvAuction.filters','tvAuction.services','tvAuction.directives','tvAuction.graphs'])
  .config ['$routeProvider', ($routeProvider) ->

    $routeProvider.when '/',
      templateUrl: 'partials/index.html'
      controller: IndexCtrl
    $routeProvider.when '/main',
      templateUrl: 'partials/main.html'
      controller: MainCtrl
    $routeProvider.when '/help',
      templateUrl: 'partials/help.html'
      controller: HelpCtrl

    $routeProvider.when '/user/login',
      templateUrl: 'partials/userLogin.html'
      controller: UserLoginCtrl
    $routeProvider.when '/user/logout',
      templateUrl: 'partials/userLogout.html'
      controller: UserLogoutCtrl

    $routeProvider.when '/auction',
      templateUrl: 'partials/auction.html'
      controller: AuctionCtrl
    $routeProvider.when '/auction/:auction',
      templateUrl: 'partials/auctionView.html'
      controller: AuctionViewCtrl

    $routeProvider.when '/campaign',
      templateUrl: 'partials/campaign.html'
      controller: CampaignCtrl
    $routeProvider.when '/campaign/resume',
      templateUrl: 'partials/campaignDetail.html'
      controller: CampaignDetailCtrl
    $routeProvider.when '/campaign/new/:auction',
      templateUrl: 'partials/campaignDetail.html'
      controller: CampaignDetailCtrl
    $routeProvider.when '/campaign/calendar',
      templateUrl: 'partials/campaignDetailCalendar.html'
      controller: CampaignDetailCalendarCtrl
    $routeProvider.when '/campaign/targetTweak',
      templateUrl: 'partials/campaignDetailTargetTweak.html'
      controller: CampaignDetailTargetTweakCtrl
    $routeProvider.when '/campaign/:campaign',
      templateUrl: 'partials/campaignDetail.html'
      controller: CampaignDetailCtrl


    $routeProvider.otherwise {redirectTo: '/'}

  ]
