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
    link : (scope, elm, attr, ctrl) ->
      removeTriggerWatch = null
      removeSlotWatch = null

      destroyPopover = (newValue, oldValue) ->
        elm.popover 'destroy'
        delete scope.input
        removeTriggerWatch() if removeTriggerWatch
        removeSlotWatch() if removeSlotWatch

      elm.click ->
        scope.slotTrigger = !scope.slotTrigger
        if not elm.data('popover')
          scope.input = $.extend {}, scope.slot
          #scope.input = angular.copy scope.slot
          elm.popover {
            title: 'Slot #'+scope.slot.id
            content: $compile("<div class=\"slcontainer\" ng-include src=\"'partials/slotPopup.html'\">Loading...</div>")(scope)
            trigger: 'manual'
            placement: 'right'
          }
          elm.popover 'show'
          removeTriggerWatch = scope.$watch 'slotTrigger', (newValue, oldValue) ->
            destroyPopover() if newValue != oldValue
          removeSlotWatch = scope.$watch 'slot', (newValue, oldValue) ->
            destroyPopover() unless _.isEqual newValue, oldValue
          , true
        else
          destroyPopover()
        scope.$apply()

      scope.closePopup = ->
        destroyPopover()
      scope.saveInput = ->
        scope.slot = $.extend scope.slot,
          forced: scope.input.forced
          target: scope.input.target
        destroyPopover()

  return directive
]

