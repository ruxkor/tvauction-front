'use strict'

# Directives

angular
  .module('tvAuction.directives' , [])
  .directive 'appVersionBla', ['version' , (version) ->
    return (scope, elm, attrs) ->
      elm.text version
  ]


