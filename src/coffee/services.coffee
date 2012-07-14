'use strict'


module = angular.module 'tvAuction.services' , []

module.factory 'Campaign', ($resource) ->
  return () ->
    return {bla: -> 'blabla'}

module.value 'version','0.1'

