'use strict'

module = angular.module('tvAuction.filters', [])

module.filter 'interpolate', ['version', (version) ->
  return (text) ->
    String(text).replace(/\%VERSION\%/mg, version)
]

module.filter 'yesno', ->
	return (input) ->
		if input then 'yes' else 'no'

module.filter 'oknotok', ->
	return (input) ->
		if input then '✔' else ' '

module.filter 'join', ->
	return (input) ->
		if Array.isArray input then input.join ', ' else input