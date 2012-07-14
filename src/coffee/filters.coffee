'use strict'

angular
  .module('tvAuction.filters', [])
  .filter 'interpolate', ['version', (version) ->
    return (text) ->
      String(text).replace(/\%VERSION\%/mg, version)
  ]
