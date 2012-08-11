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
    replace: true
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
      brush = d3.svg.brush().x(x).y(y)

      brushstart = ->
      brushmove = ->
        brush_dims = d3.event.target.extent()
        fields.classed('inselection', (d) ->
          field_dims = [
            [x(d[0]+1)+x.rangeBand(),y(d[1]+1)+y.rangeBand()]
            [x(d[0]+1),y(d[1]+1)]
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

module.directive 'slotpopup', ['$parse', '$compile', ($parse, $compile) ->
  directive =
    require: 'ngModel'
    replace: true
    template: "<div></div>"
    link: (scope, elm, attr, ctrl) ->
      ngModel = $parse attr.ngModel
      slot = ngModel scope
      console.info slot

      ta = $compile("<input type=\"text\" ng-model=\"#{attr.ngModel}.target\" />")(scope)
      elm.append ta
      scope.$apply()
      #elm.html("<input type='\"text\" ng-model=\"#{attr.ngModel}.target\" />")


  return directive
]

module.directive 'targettweaks', ['$parse', '$compile', ($parse, $compile) ->
  directive =
    require: 'ngModel'
    replace: true
    compile: (tElm, tAttr, transclude) ->
      margin = {top: 10, right: 10, bottom: 100, left: 50}
      margin2 = {top: 280, right: 10, bottom: 20, left: 50}
      width = tElm.width() - margin.left - margin.right
      height = tElm.height() - margin.top - margin.bottom
      height2 = tElm.height() - margin2.top - margin2.bottom

      x = d3.time.scale().range([0, width])
      x2 = d3.time.scale().range([0, width])
      y = d3.scale.linear().range([height, 0])
      y2 = d3.scale.linear().range([height2, 0])

      xAxis = d3.svg.axis()
        .scale(x)
        .orient('bottom')
      xAxis2 = d3.svg.axis()
        .scale(x2)
        .orient('bottom')
      yAxis = d3.svg.axis()
        .scale(y)
        .orient('left')

      area = d3.svg.area()
        .x( (d) -> x(d.date) )
        .y0(height)
        .y1( (d) -> y(d.target) )
        .interpolate('monotone')

      area2 = d3.svg.area()
        .x( (d) -> x2(d.date) )
        .y0(height2)
        .y1( (d) -> y2(d.target) )
        .interpolate('monotone')


      svg = d3.selectAll(tElm)
        .append('svg')
        .attr('with', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)

      svg
        .append('defs')
        .append('clipPath')
          .attr('id', 'clip')
        .append('rect')
          .attr('width', width)
          .attr('height', height)

      focus = svg.append('g')
        .attr('transform', "translate(#{margin.left},#{margin.top})")

      context = svg.append('g')
        .attr('class', 'context')
        .attr('transform', "translate(#{margin2.left},#{margin2.top})")

      focusArea = focus.append('path')
        .attr('clip-path', 'url(#clip)')

      contextArea = context
        .append('path')

      bars = null

      barClipPath = focus
        .append('g')
        .attr('clip-path', 'url(#clip)')

      drawBars = (slots) ->
        bars = barClipPath
          .selectAll('rect.slot')
          .data(slots)
        bars
          .enter()
          .append('rect')
          .attr('class', 'slot')
          .classed('active', (d) -> d.active)
          .classed('forced', (d) -> d.forced)
          .attr('x', (d) -> x(d.date) )
          .attr('y', (d) -> y(d.target))
          .attr('width', 0)
          .attr('height', (d) -> y(y.domain()[0]) - y(d.target))
        bars
          .transition()
          .duration(200)
          .attr('y', (d) -> y(d.target))
          .attr('height', (d) -> y(y.domain()[0]) - y(d.target))
        bars
          .exit()
          .remove()


      barOpacity = d3.scale.linear().domain([30,5])

      onBrushStart = ->
        bars.each( -> $(this).popover('hide') )

      onBrush = ->
        x.domain(if brush.empty() then x2.domain() else brush.extent())
        focus.select('.x.axis').call(xAxis)
        # determine width of 15 minute bar
        barWidth = parseInt(x(+x.domain()[0]+15*60*1000), 10)
        barWidth = 0 if barWidth < 8

        focusArea
          .attr('d', area)
          .attr('opacity', Math.min(1,Math.max(0,barOpacity(barWidth))))
        bars
          .attr('x', (d) -> x(d.date) )
          .attr('width', (d) -> barWidth)
          .attr('opacity', Math.min(1,Math.max(0,1-barOpacity(barWidth))))

      brush = d3.svg.brush()
        .x(x2)
        .on('brushstart', onBrushStart)
        .on('brush', onBrush)

      focus.append('g')
        .attr('class', 'x axis x_axis')
        .attr('transform', "translate(0,#{height})")
      focus.append('g')
        .attr('class', 'y axis y_axis')
      context.append('g')
        .attr('class','x brush x_brush')

      d3.selectAll(tElm)
        .append('div')
        .attr('class','row')
        .append('div')
        .attr('class','span9')
        .attr('style','text-align: right;')
        .append('a')
        .attr('class','info')
        .text('Reset')
        .on('click', ->
          brush.clear()
          onBrush()
          svg.call(brush)
        )

      updateAxes = (slots) ->
        x.domain(d3.extent(d.date for d in slots))
        y.domain([0, d3.max(d.target for d in slots)])
        x2.domain(x.domain())
        y2.domain(y.domain())

      return (scope, elm, attr, ctrl) ->
        ngModel = $parse attr.ngModel
        slots = ngModel scope
        window.myNgM = ngModel
        window.myScope = scope

        barWatch = (d, pos) ->
          #return $compile("<div class=\"slotpopup\" slotpopup ng-model=\"#{tAttr.ngModel}[#{pos}]\" />")(scope)
          el = $(this)
          el.popover
            placement: 'top'
            trigger: 'manual'
            title: "Slot #{d.id}"
            content: "ui"
          el.click ->
            el.popover 'toggle'


        refreshGraph = ->
          # update all axes' domains and re-scale axes
          updateAxes(slots)
          focus.select('g.x_axis').call(xAxis)
          focus.select('g.y_axis').call(yAxis)

          focusArea
            .data([slots])
            .attr('d', area)

          contextArea
            .data([slots])
            .attr('d', area2)

          drawBars(slots)
          bars.each barWatch

          context.select('g.x_brush')
            .call(brush)
            .selectAll('rect')
            .attr('y', -6)
            .attr('height',height2 + 7)

        scope.$watch ngModel, (newValue, oldValue) ->
          # update the slots var
          slots = newValue
          refreshGraph()

        scope.$watch 'campaign.slots[0].target', ->
          console.info 'yo'
          refreshGraph()


  return directive
]
