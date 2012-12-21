'use strict'

# Directives


module = angular.module('tvAuction.directives' , [])

module.directive 'appVersionBla', ['version' , (version) ->
  return (scope, elm, attrs) ->
    elm.text version
]

module.directive 'campaignminbudget', ->
  directive =
    require: 'ngModel'
    link: (scope, elm, attr, ctrl) ->
      ctrl.$parsers.push (value) ->
        ctrl.$setValidity 'minbudget', value > scope.campaign.minBudget()
        return value
  return directive

module.directive 'slotPopup', ['$parse', '$compile', ($parse, $compile) ->
  directive =
    restrict: 'A'
    scope:
      slot: '=slotPopup'
      slotTrigger: '='
      slotLocked: '='
    link : (scope, elm, attr, ctrl) ->
      removeTriggerWatch = null
      removeSlotWatch = null
      popover = null

      destroyPopover = (newValue, oldValue) ->
        if popover
          delete scope.input
          popover.destroy() 
          popover = null
          removeTriggerWatch()
          removeSlotWatch()

      elm.click ->
        scope.slotTrigger = !scope.slotTrigger
        if not elm.data('popover')
          scope.input = $.extend {}, scope.slot
          elm.popover {
            title: 'Slot #'+scope.slot.id
            content: $compile("<div class=\"slcontainer\" ng-include src=\"'partials/slotPopup.html'\">Loading...</div>")(scope)
            trigger: 'manual'
            placement: 'right'
          }
          popover = elm.data('popover')
          removeTriggerWatch = scope.$watch 'slotTrigger', (newValue, oldValue) ->
            destroyPopover() unless newValue == oldValue
          removeSlotWatch = scope.$watch 'slot', (newValue, oldValue) ->
            destroyPopover() unless _.isEqual newValue, oldValue
          , true

          elm.popover 'show'
          scope.$apply()
        else
          destroyPopover()

      scope.closePopup = -> 
        destroyPopover()

      scope.saveInput = ->
        return if scope.slotLocked
        scope.slot = $.extend scope.slot,
          forced: scope.input.forced
          target: scope.input.target
        destroyPopover()

      scope.$on '$destroy', (event) ->
        destroyPopover()

  return directive
]

