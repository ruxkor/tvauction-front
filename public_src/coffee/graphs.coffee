
module = angular.module('tvAuction.graphs' , [])

# time restrictions directive
# 
# this directive is used to whow a calendar-like view
# and updates directly the campaign object, containing
# the daily and hourly restrictions
module.directive 'timerestrictions', ['$parse', '$compile', ($parse, $compile) ->
  directive =
    replace: true
    compile: (tElm, tAttr, transclude) ->
      horiz = ((if 0==i%2 then i else '') for i in [0...24])
      vert = ['Mo', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

      # build scales
      x = d3.scale.ordinal()
        .domain([0...25])
        .rangeBands([0,tElm.width()])
      y = d3.scale.ordinal()
        .domain([0...8])
        .rangeBands([0,tElm.height()])

      # create main chart
      graph = d3.selectAll(tElm).append('svg')

      chart = graph
        .append('g')
        .attr('class','chart')

      # add selection brush
      brush = d3.svg.brush().x(x).y(y)

      drawCalendar = (entries, scope) ->
        # build data arrays
        calendar = []
        for day in [1,2,3,4,5,6,0]
          for hour in [0...24]
            calendar_entry = [hour,day]
            in_entry = _.any entries, (entry) ->
              calendar_entry[0] == entry[0] && calendar_entry[1] == entry[1]
            calendar_entry.push in_entry
            calendar.push calendar_entry

        # create fields
        fields = chart
          .selectAll('rect.field')
          .data(calendar)
        fields
          .enter()
          .append('rect')
          .attr('class','field')
          .attr('x', (d,i,j) -> x(d[0]+1) )
          .attr('y', (d,i,j) -> y(d[1]+1) )
          .attr('width', x.rangeBand())
          .attr('height', y.rangeBand())
        fields
          .classed('restricted', (d) -> d[2])

        # create horizontal header text
        graph
          .selectAll('text.border.horiz')
          .data(horiz)
          .enter()
          .append('text')
          .attr('class','border horiz')
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
          .attr('class','border vert')
          .attr('x', 0)
          .attr('y', (d,i) -> y(i+1))
          .attr('dy', '1em')
          .text(String)

      return (scope, elm, attr, ctrl) ->
        ngModel = $parse attr.ngModel

        brushstart = ->
        brushmove = ->
          brush_dims = d3.event.target.extent()
          fields = chart.selectAll('rect')
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
          fields = chart.selectAll('rect.field')
          selected = fields.filter('.inselection')
          restricted =  selected.filter('.restricted')
          inactive =  selected.filter(':not(.restricted)')
          restricted.classed('restricted', false)
          inactive.classed('restricted', true)
          selected.classed('inselection', false)
          brush.clear()
          graph.call(brush)
          
          restrictedEntries = _.map fields.filter('.restricted').data(), (d) ->
            d[0...2]
          ngModel.assign scope, restrictedEntries
          scope.$digest()

        clearselection = ->
          fields = chart.selectAll('rect.field')
          fields.classed('restricted', false)
          ngModel.assign scope, []
          scope.$digest()

          
        graph
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

        scope.$watch ngModel, (newValue, oldValue) ->
          return unless newValue
          drawCalendar(newValue, scope)
        , true




  return directive
]

module.directive 'targettweaks', ['$parse', '$compile', ($parse, $compile) ->
  directive =
    replace: true
    compile: (tElm, tAttr, transclude) ->
      margin = {top: 10, right: 10, bottom: 100, left: 60}
      margin2 = {top: 280, right: 10, bottom: 20, left: 60}
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

      area2 = d3.svg.area()
        .x( (d) -> x2(d.date) )
        .y0(height2)
        .y1( (d) -> y2(d.target) )
        .interpolate('monotone')


      svg = d3.selectAll(tElm)
        .append('svg')
        .attr('width', width + margin.left + margin.right)
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

      contextArea = context
        .append('path')

      barOpacity = d3.scale.linear().domain([30,5])

      bars = null

      barClipPath = focus
        .append('g')
        .attr('clip-path', 'url(#clip)')

      drawBars = (slots, scope) ->
        bars = barClipPath
          .selectAll('rect.slot')
          .data(slots)
        bars
          .enter()
          .append('rect')
          .attr('class', 'slot')
          .attr('x', (d) -> x(d.date) )
          .attr('width', 2)
          .attr('slot-popup', (d,pos) -> tAttr.ngModel+"["+pos+"]" )
          .attr('slot-trigger','slotTrigger')
          .each( -> $compile(this)(scope) )
        bars
          .classed('active', (d) -> d.active)
          .classed('forced', (d) -> d.forced)
          .transition()
          .duration(400)
          .attr('y', (d) -> y(d.target))
          .attr('height', (d) -> y(y.domain()[0]) - y(d.target))
        bars
          .exit()
          .remove()


      # keep track of the opened bars
      openedBars = []

      barHide = (d, pos, el) ->
        el.popover('hide') if el.data('popover')
        openedBars = []

      onBrushStart = ->
        bars.each (d,pos) -> barHide(d,pos, $(this))

      onBrush = ->
        x.domain(if brush.empty() then x2.domain() else brush.extent())
        focus.select('.x.axis').call(xAxis)
        # determine width of 15 minute bar
        barWidth = ~~x(+x.domain()[0]+15*60*1000)
        barWidth = 2 if barWidth < 2

        bars
          .attr('x', (d) -> x(d.date) )
          .attr('width', (d) -> barWidth)

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

      context.select('g.x_brush')
        .call(brush)
        .selectAll('rect')
        .attr('y', -6)
        .attr('height',height2 + 7)

      return (scope, elm, attr, ctrl) ->
        # the slots value gets assigned on the $watch event below
        ngModel = $parse attr.ngModel
        slots = null

        # update all axes' domains and re-scale axes
        refreshAxes = ->
          x.domain(d3.extent(d.date for d in slots))
          y.domain([0, d3.max(d.target for d in slots)])
          x2.domain(x.domain())
          y2.domain(y.domain())
          focus.select('g.x_axis').call(xAxis)
          focus.select('g.y_axis').call(yAxis)

        refreshYAxis = ->
          y.domain([0, d3.max(d.target for d in slots)])
          y2.domain(y.domain())
          focus.select('g.y_axis').call(yAxis)

        refreshValues = ->
          contextArea
            .data([slots])
            .attr('d', area2)
          drawBars(slots, scope)


        scope.$watch ngModel, (newValue, oldValue) ->
          return unless newValue
          firstUpdate = (slots == null)
          slotsChanged = not oldValue or (newValue.length != oldValue.length)
          slots = newValue

          if firstUpdate or slotsChanged
            refreshAxes()
            brush.clear() if slotsChanged
          else
            refreshYAxis()
          refreshValues()
        , true


  return directive
]

module.directive 'campaigncalendar', ['$parse', '$compile', ($parse, $compile) ->
  directive =
    replace: true
    compile: (tElm, tAttr, transclude) ->
      margin = {top: 10, right: 10, bottom: 20, left: 50}

      width = tElm.width() - margin.left - margin.right
      height = tElm.height() - margin.top - margin.bottom

      x = d3.time.scale()
        .range([0, width])
      y = d3.scale.linear()
        .range([0, height])

      xAxis = d3.svg.axis()
        .scale(x)
        .orient('bottom')
        .ticks(d3.time.days,1)

      yAxis = d3.svg.axis()
        .scale(y)
        .orient('left')
        .ticks(12)

      svg = d3.selectAll(tElm)
        .append('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
      svg
        .append('defs')
        .append('clipPath')
          .attr('id', 'clip')
        .append('rect')
          .attr('width', width)
          .attr('height', height)

      graph = svg.append('g')
        .attr('class', 'graph')
        .attr('transform', "translate(#{margin.left},#{margin.top})")

      bars = null
      openedBars = []

      barHide = (d, pos, el) ->
        el.popover('hide') if el.data('popover')
        openedBars = []


      x0 = null
      y0 = null

      successfulTranslate = [0, 0]

      zoomer = d3.behavior.zoom()
        .scaleExtent([1,2])

      onZoom = ->
        ev = d3.event # translate[x,y], scale

        bars.each (d,pos) -> barHide(d,pos,$(this))

        if ev.scale == 1.0
          x.domain x0.domain()
          y.domain y0.domain()
          successfulTranslate = [0, 0]
        else
          xLimits = x0.domain()
          yLimits = y0.domain()
          xTrans = x0.range().map( (xVal) -> (xVal-ev.translate[0]) / ev.scale ).map(x0.invert)
          yTrans = y0.range().map( (yVal) -> (yVal-ev.translate[1]) / ev.scale ).map(y0.invert)
          xTransOk = xTrans[0] >= xLimits[0] and xTrans[1] <= xLimits[1]
          yTransOk = yTrans[0] >= yLimits[0] and yTrans[1] <= yLimits[1]
          if xTransOk
            x.domain xTrans
            successfulTranslate[0] = ev.translate[0]
          if yTransOk
            y.domain yTrans
            successfulTranslate[1] = ev.translate[1]
        zoomer.translate successfulTranslate

      resetZoom = ->
        zoomer.translate [0,0]
        zoomer.scale 1

      graph.append('g')
        .attr('class','x axis')
        .attr('transform', "translate(0,#{height})")

      graph.append('g')
        .attr('class', 'y axis')

      # if the previous timezone is bigger, then they overlap. example: -60 > -120 
      # for GMT+0100 and GMT+0200
      #return previousSlot.date.getTimezoneOffset() > d.date.getTimezoneOffset()
      overlapCheck =
        next: (d,pos) ->
          other = slots[pos+1]
          return false unless other
          return other.date.getTimezoneOffset() < d.date.getTimezoneOffset()
        previous: (d,pos) ->
          other = slots[pos-1]
          return false unless other
          return other.date.getTimezoneOffset() > d.date.getTimezoneOffset()

      overlapCheck =
        next: (d,pos) -> pos == 9
        previous: (d,pos) -> pos == 10

      barClipPath = graph
        .append('g')
        .attr('clip-path', 'url(#clip)')
        .call(zoomer)
      
      drawBars = (slots, scope) ->
        bars = barClipPath
          .selectAll('rect.slot')
          .data(slots)
        bars
          .enter()
          .append('rect')
          .attr('class','slot')
          .attr('slot-popup', (d,pos) -> tAttr.ngModel+"["+pos+"]" )
          .attr('slot-trigger','slotTrigger')
          .each( -> $compile(this)(scope) )
        bars
          .classed('active', (d) -> d.active)
          .classed('forced', (d) -> d.forced)
          .attr('width', (d, pos) ->
            res = x(d3.time.day.ceil(new Date(+d.date+1000))) - x(d3.time.day.floor(d.date))
            res *= 0.5 if overlapCheck.next(d,pos) or overlapCheck.previous(d,pos)
            res - 2)
          .attr('height', (d) ->
            hours = d.date.getHours() + d.date.getMinutes()/60
            res = y(hours+1) - y(hours)
            res - 2)
          .attr('y', (d) ->
            hours = d.date.getHours() + d.date.getMinutes()/60
            barY = y(hours)
            1+barY)
          .attr('x', (d, pos) ->
            barX = x(d3.time.day.floor(d.date))
            if overlapCheck.previous(d,pos)
              barX = (barX + x(d3.time.day.ceil(d.date))) * 0.5
            1+barX)
        bars
          .exit()
          .remove()

      return (scope, elm, attr, ctrl) ->

        ngModel = $parse attr.ngModel
        slots = null

        refreshAxes = ->
          limits =
            x: [d3.min(d3.time.day.floor(d.date) for d in slots), d3.max(d3.time.day.ceil(d.date) for d in slots)]
            y: [0,24]
          x.domain(limits.x[..])
          y.domain(limits.y[..])
          x0 = x.copy()
          y0 = y.copy()
          
          graph.select('g.x.axis').call(xAxis)
          graph.select('g.y.axis').call(yAxis)

          zoomer.on 'zoom', ->
            onZoom()
            graph.select('g.x.axis').call(xAxis)
            graph.select('g.y.axis').call(yAxis)
            drawBars slots, scope


        refreshValues = ->
          drawBars slots, scope

        scope.$watch ngModel, (newValue, oldValue) ->
          return unless newValue
          firstUpdate = (slots == null)
          slotsChanged = not oldValue or (newValue.length != oldValue.length)
          slots = newValue

          if firstUpdate or slotsChanged
            refreshAxes()
            resetZoom() if slotsChanged

          refreshValues()
        , true

]

module.directive 'auctionreach', ['$parse','$compile', ($parse, $compile) ->
  directive =
    replace: true
    scope:
      auctionStart: '='
      auctionEnd: '='
      slots: '='
      reach: '='
    compile: (tElm, tAttr, transclude) ->
      margin = {top: 10, right: 10, bottom: 20, left: 60}

      width = tElm.width() - margin.left - margin.right
      height = tElm.height() - margin.top - margin.bottom

      x = d3.time.scale().range([0, width])
      y = d3.scale.linear().range([0, height])

      xAxis = d3.svg.axis().scale(x).orient('bottom')
      yAxis = d3.svg.axis().scale(y).orient('left')

      area = d3.svg.line()
        .x( (d) -> x(d.date) )
        .y( (d) -> y(d.reach) )
        .interpolate('monotone')

      svg = d3.selectAll(tElm)
        .append('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)

      context = svg.append('g')
        .attr('transform', "translate(#{margin.left},#{margin.top})")

      contextArea = context
        .append('path')

      context.append('g')
        .attr('class','x axis x_axis')
        .attr('transform', "translate(0,#{height})")
      context.append('g')
        .attr('class','y axis y_axis')

      return (scope, elm, attr, ctrl) ->

        # we augment the slots with a reach attribute
        # this attribute is then used to draw the y values
        slots = null
        reaches = null
        auction_start = null
        auction_end = null

        refreshReaches = ->
          if reaches.length != slots.length
            throw new Error('reaches and slots do not have the same length')

          for slot, i in slots
            slot.reach = reaches[i]

          x.domain([auction_start,auction_end])
          y.domain([d3.max(d.reach for d in slots),0])
          context.select('g.x_axis').call(xAxis)
          context.select('g.y_axis').call(yAxis)

          contextArea
            .data([slots])
            .transition()
            .attr('d', area)

        checkForRefresh = ->
          refreshReaches() if slots and reaches and auction_start and auction_end

        scope.$watch 'auctionStart', (newValue, oldValue) ->
          auction_start = new Date(newValue)
          checkForRefresh()
        scope.$watch 'auctionEnd', (newValue, oldValue) ->
          auction_end = new Date(newValue)
          checkForRefresh()
        scope.$watch 'slots', (newValue, oldValue) ->
          slots = newValue
          checkForRefresh()
        scope.$watch 'reach', (newValue, oldValue) ->
          reaches = newValue
          checkForRefresh()

  return directive
]

