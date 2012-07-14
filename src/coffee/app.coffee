'use strict'

angular
	.module('tvAuction', ['tvAuction.filters','tvAuction.services','tvAuction.directives'])
	.config ['$routeProvider', ($routeProvider) ->
		$routeProvider.when '/campaignCreate',
			templateUrl: 'partials/campaignCreate.html'
			controller: CampaignCreateCtrl
		$routeProvider.otherwise {redirectTo: '/campaignCreate'}
  ]
