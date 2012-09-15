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
    $routeProvider.when '/user/login',
      templateUrl: 'partials/userLogin.html'
      controller: UserLoginCtrl
    $routeProvider.when '/user/logout',
      templateUrl: 'partials/userLogout.html'
      controller: UserLogoutCtrl
    $routeProvider.when '/campaign/create',
      templateUrl: 'partials/campaignCreate.html'
      controller: CampaignCreateCtrl
    $routeProvider.when '/campaign/create/calendar',
      templateUrl: 'partials/campaignCreateCalendar.html'
      controller: CampaignCreateCalendarCtrl
    $routeProvider.when '/campaign/create/targetTweak',
      templateUrl: 'partials/campaignCreateTargetTweak.html'
      controller: CampaignCreateTargetTweakCtrl
    $routeProvider.otherwise {redirectTo: '/'}
  ]
