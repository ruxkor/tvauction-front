'use strict'

module = angular.module('tvAuction.filters', [])

module.filter 'interpolate', ['version', (version) ->
  return (text) ->
    String(text).replace(/\%VERSION\%/mg, version)
]

module.filter 'yesno', ->
	return (input) ->
		if input then 'yes' else 'no'