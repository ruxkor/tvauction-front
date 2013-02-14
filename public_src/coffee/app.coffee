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
    $routeProvider.when '/auction/:auction_id',
      templateUrl: 'partials/auctionView.html'
      controller: AuctionViewCtrl

    $routeProvider.when '/campaign',
      templateUrl: 'partials/campaign.html'
      controller: CampaignCtrl
    $routeProvider.when '/campaign/edit/:auction_id',
      templateUrl: 'partials/campaignDetail.html'
      controller: CampaignDetailCtrl
    $routeProvider.when '/campaign/calendar/:auction_id',
      templateUrl: 'partials/campaignDetailCalendar.html'
      controller: CampaignDetailCalendarCtrl
    $routeProvider.when '/campaign/targetTweak/:auction_id',
      templateUrl: 'partials/campaignDetailTargetTweak.html'
      controller: CampaignDetailTargetTweakCtrl
    $routeProvider.when '/result/:auction_id',
      templateUrl: 'partials/result.html'
      controller: ResultCtrl

    $routeProvider.otherwise {redirectTo: '/'}
  ]
