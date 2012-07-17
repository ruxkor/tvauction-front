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
        console.info new Date()
        ctrl.$setValidity 'minbudget', value > scope.campaign.minBudget()
        return value
  return directive

module.directive 'campaigncalendar', ->
  directive =
    restrict: 'C'
    replace: true
    transclude: true
    link: (scope, elm, attr, ctr) ->
      days = d3.time.days scope.auction.from, scope.auction.to
      calendar = []
      i = 0
      while i < days.length-1
        calendar.push [days[i], d3.time.hours days[i], days[i+1]]
        i++
      console.info calendar
module.directive 'demographicaudience', ->
  directive =
    restrict: 'C'
    replace: true
    transclude: true
    link: (scope, elm, attr, ctr) ->

      # build data arrays
      week = []
      for i in [0...7]
        week.push [0...24]

      horiz = ((if 0==i%2 then i else '') for i in [0...24])
      vert = ['Mo', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

      # build scales
      x = d3.scale.ordinal()
        .domain([0...25])
        .rangeBands([0,elm.width()])
      y = d3.scale.ordinal()
        .domain([0...8])
        .rangeBands([0,elm.height()])

      # create main chart
      chart = d3.selectAll(elm).append('svg')
        .attr('class','chart')

      # create fields
      chart
        .selectAll('g')
        .data(week)
        .enter().append('g')
        .selectAll('rect')
        .data( (d) -> d )
        .enter()
        .append('rect')
        .attr('class','field')
        .attr('x', (d,i,j) -> x(i+1) )
        .attr('y', (d,i,j) -> y(j+1) )
        .attr('width', x.rangeBand())
        .attr('height', y.rangeBand())
      
      # create horizontal header text
      chart
        .selectAll('text.border.horiz')
        .data(horiz)
        .enter()
        .append('text')
        .attr('class','border.horiz')
        .attr('x', (d,i,j) -> x(i+1) + 0.5*x.rangeBand())
        .attr('y', y.rangeBand())
        .attr('dy', '-0.2em')
        .attr('text-anchor','middle')
        .text(String)

      # create vertical header text
      chart
        .selectAll('text.border.vert')
        .data(vert)
        .enter()
        .append('text')
        .attr('class','border.vert')
        .attr('x', 0)
        .attr('y', (d,i,j) -> y(i+1))
        .attr('dy', '1em')
        .text(String)






          

        #.attr("r", 10)
      
  return directive

