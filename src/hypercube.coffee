# hypercube data browser

logFormat = d3.format ",.0f"
brushSize = 30

# create a new dimension
class Dimension
    constructor: (xf, @_name, @_get) ->
        @_dim = xf.dimension @_get

    axis: (type) ->
        axis @, type

    group: ->
        group @

dimension = (xf, name, accessor) ->
    new Dimension xf, name, accessor

class Group
    constructor: (dim) ->
        @_name =  dim._name
        @_get =  dim._get
        @_dim =  dim._dim
        @_group =  dim._dim.group()

    axis: (type) ->
        axis @, type

group = (dim) ->
    new Group dim

class Axis
    constructor: (dim, type) ->
        me = @
        @_name = dim._name
        @_type = type
        @_dim = dim
        scale = @_scale ?= d3.scale[type]()
        @_axis = d3.svg.axis().scale(scale)
        @_brush = d3.svg.brush()
        @_map = (d) -> scale dim._get d

        @_brush.on 'brush', ->
            dim._dim.filterRange me._brush.extent()

        @_scale.domain [
            dim._get(dim._dim.bottom(1)[0]),
            dim._get(dim._dim.top(1)[0])
        ]

        @axis = (sel) ->
            sel .call(me._axis)
                .selectAll('.label')
                .text(me._name)
        @brush = (sel) ->
            rect = sel.call(me._brush)
                .selectAll('rect')
            if me._side is 'left' or me._side is 'right'
                rect.attr('x', -brushSize)
                    .attr('width', brushSize)
            else
                rect.attr('height', brushSize)

    range: (extent) ->
        @_scale.range extent
        @

    orient: (side) ->
        @_side = side
        brushAxis = if side is 'left' or side is 'right' then 'y' else 'x'
        @_brush[brushAxis](@_scale)
        @_axis.orient side
        @

class LogAxis extends Axis
    constructor: (dim) ->
        super dim, 'log'
        @_axis.tickFormat logFormat

class TimeAxis extends Axis
    constructor: (dim) ->
        @_scale = d3.time.scale()
        super dim, 'time'

class OrdinalAxis extends Axis
    constructor: (dim) ->
        super dim, 'ordinal'
        scale = @_scale
        offset = ((d)-> d + scale.rangeBand()*0.5)
        @_map = (d) -> offset scale dim._get d
        @_scale.domain dim._dim.group().all().map (d) -> d.key

    range: (extent) ->
        @_scale.rangeRoundBands extent, 0.1
        @

axis = (dim, type) ->
    return new OrdinalAxis dim if type is 'ordinal'
    return new TimeAxis dim if type is 'time'
    return new LogAxis dim if type is 'log'
    new Axis dim, type

defaultAxis = (dim) ->
    vals = d3.nest().key((d) -> d.key).map dim._dim.group().all()
    scale = d3.scale.linear()
    ax =
        _scale: scale
        _map: (d) -> scale if not vals[dim._get d]? then 0 else vals[dim._get d][0].value
        axis: d3.svg.axis().scale(scale)
        brush: ->
        range: (extent) -> @_scale.range extent; @
        orient: (side) -> @axis.orient side; @

    ax._scale.domain d3.extent d3.values(vals), (d) -> d[0].value

    ax

class Projection
    constructor: (selector, w, h) ->
        m = h * 0.1

        @_svg = d3.select(selector).append('svg')
            .attr('width', w)
            .attr('height', h)
            .append('g')
            .attr('transform', "translate(#{m},#{m})")

        @_width = w - 2*m
        @_height = h - 2*m

        @_svg.append('g')
            .attr('class', 'x axis')
            .attr('transform', "translate(0,#{@_height})")
            .append('text')
            .attr('class', 'label')
            .attr('text-anchor', 'end')
            .attr('transform', "translate(#{@_width},36)")
        @_svg.append('g')
            .attr('class', 'x brush')
            .attr('transform', "translate(0,#{@_height})")
        @_svg.append('g')
            .attr('class', 'y axis')
            .append('text')
            .attr('class', 'label')
            .attr('text-anchor', 'start')
            .attr('transform', 'translate(-40,-16)')
        @_svg.append('g')
            .attr('class', 'y brush')

    x: (ax) ->
        @_x = ax
            .range([0, @_width])
            .orient('bottom')

        if not @_y?
            @_y = defaultAxis(ax._dim)
                .range([@_height, 0])
                .orient('left')

    y: (ax) ->
        @_y = ax
            .range([@_height, 0])
            .orient('left')

        if not @_x?
            @_x = defaultAxis(ax._dim)
                .range([0, @_width])
                .orient('bottom')

    r: (ax) ->
        @_r = ax.range([2, 8])

    fill: (ax) ->
        @_fill = ax

    draw: (records) ->
        if @_x?
            @_svg.select('.x.axis')
                .call(@_x.axis)
            @_svg.select('.x.brush')
                .call(@_x.brush)
        if @_y?
            @_svg.select('.y.axis')
                .call(@_y.axis)
            @_svg.select('.y.brush')
                .call(@_y.brush)

        circle = @_svg.selectAll('.record')
            .data(records)

        circle
            .enter().append('circle')
            .attr('class', 'record')

        circle
            .exit().remove()

        circle
            .attr('r', if @_r? then @_r._map else 3)
            .attr('cx', if @_x? then @_x._map else 0)
            .attr('cy', if @_y? then @_y._map else 0)
            .attr('fill', if @_fill? then @_fill._map else 'black')

projection = (selector, w, h) ->
    new Projection selector, w, h

class Hypercube
    constructor: (records) ->
        @_xf = crossfilter records
        @_dims = []
        @_projs = []

    dimension: (name, accessor) ->
        d = dimension @_xf, name, accessor
        @_dims.push d
        d

    projection: (selector, width, height, margin) ->
        p = projection selector, width, height, margin
        @_projs.push p
        p

# create a new hypercube
hypercube = (records) ->
    new Hypercube records

return hypercube
