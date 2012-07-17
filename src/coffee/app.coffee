'use strict'

angular
	.module('tvAuction', ['tvAuction.filters','tvAuction.services','tvAuction.directives'])
	.config ['$routeProvider', ($routeProvider) ->
		$routeProvider.when '/campaign/create',
			templateUrl: 'partials/campaignCreate.html'
			controller: CampaignCreateCtrl
		$routeProvider.when '/campaign/create/calendar',
			templateUrl: 'partials/campaignCreateCalendar.html'
			controller: CampaignCreateCalendarCtrl
		$routeProvider.otherwise {redirectTo: '/campaign/create'}
  ]
