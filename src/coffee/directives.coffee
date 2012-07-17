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

# time restrictions directive
# 
# this directive is used to whow a calendar-like view
# and updates directly the campaign object, containing
# the daily and hourly restrictions
module.directive 'timerestrictions', ['$parse', ($parse) ->
  directive =
    require: 'ngModel'
    restrict: 'A'
    replace: true
    transclude: true
    link: (scope, elm, attr, ctrl) ->
      ngModel = $parse attr.ngModel

      entries = ngModel scope

      # build data arrays
      calendar = []
      for day in [0...7]
        for hour in [0...24]
          calendar_entry = [hour,day]
          in_entry = _.any entries, (entry) ->
            calendar_entry[0] == entry[0] && calendar_entry[1] == entry[1]
          calendar_entry.push in_entry
          calendar.push calendar_entry

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
      graph = d3.selectAll(elm).append('svg')

      chart = graph
        .append('g')
        .attr('class','chart')

      # create fields
      fields = chart
        .selectAll('rect')
        .data(calendar)
        .enter()
        .append('rect')
        .attr('class','field')
        .attr('x', (d,i,j) -> x(d[0]+1) )
        .attr('y', (d,i,j) -> y(d[1]+1) )
        .attr('width', x.rangeBand())
        .attr('height', y.rangeBand())
        .classed('active', (d) -> d[2])

      # create horizontal header text
      graph
        .selectAll('text.border.horiz')
        .data(horiz)
        .enter()
        .append('text')
        .attr('class','border.horiz')
        .attr('x', (d,i) -> x(i+1) + 0.5*x.rangeBand())
        .attr('y', y.rangeBand())
        .attr('dy', '-0.2em')
        .attr('text-anchor','middle')
        .text(String)
        

      # create vertical header text
      graph
        .selectAll('text.border.vert')
        .data(vert)
        .enter()
        .append('text')
        .attr('class','border.vert')
        .attr('x', 0)
        .attr('y', (d,i) -> y(i+1))
        .attr('dy', '1em')
        .text(String)

      # add selection brush
      window.brush = brush = d3.svg.brush().x(x).y(y)

      brushstart = ->
      brushmove = ->
        brush_dims = d3.event.target.extent()
        fields.classed('inselection', (d) ->
          field_dims = [
            [x(d[0]+1)+0.5*x.rangeBand(),y(d[1]+1)+0.5*y.rangeBand()],
            [x(d[0]+1)+0.5*x.rangeBand(),y(d[1]+1)+0.5*y.rangeBand()]
          ]
          brush_dims[0][0] <= field_dims[0][0] &&
          brush_dims[1][0] >= field_dims[1][0] &&
          brush_dims[0][1] <= field_dims[0][1] &&
          brush_dims[1][1] >= field_dims[1][1]
        )

      brushend = ->
        selected = fields.filter('.inselection')
        active =  selected.filter('.active')
        inactive =  selected.filter(':not(.active)')
        active.classed('active', false)
        inactive.classed('active', true)
        selected.classed('inselection', false)
        brush.clear()
        chart.call(brush)
        
        active_entries = _.map fields.filter('.active').data(), (d) ->
          d[0...2]
        ngModel.assign scope, active_entries
        scope.$digest()

      clearselection = ->
        fields.classed('active', false)
        console.info ctrl, attr
        ngModel.assign scope, []
        scope.$digest()

      chart
      .append('g')
      .attr('class','brush')
      .call(brush
        .on('brushstart', brushstart)
        .on('brush', brushmove)
        .on('brushend', brushend)
      )

      d3.selectAll(elm)
        .append('div')
        .attr('class','row')
        .append('div')
        .attr('class','span9')
        .attr('style','text-align: right;')
        .append('a')
        .attr('class','info')
        .text('Reset')
        .on('click', clearselection)

  return directive
]
