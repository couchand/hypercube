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
        scale = if type is 'time' then d3.time.scale() else d3.scale[type]()
        offset = if type is 'ordinal' then ((d)-> d + scale.rangeBand()*0.5) else ((d) -> d)
        @_name = dim._name
        @_type = type
        @_dim = dim
        @_scale = scale
        @_axis = d3.svg.axis().scale(scale)
        @_brush = d3.svg.brush()
        @_map = (d) -> offset scale dim._get d

        @_axis.tickFormat(logFormat) if type is 'log'
        @_brush.on 'brush', ->
            dim._dim.filterRange ax._brush.extent()

        if type is 'ordinal'
            @_scale.domain dim._dim.group().all().map (d) -> d.key
        else
            @_scale.domain [
                dim._get(dim._dim.bottom(1)[0]),
                dim._get(dim._dim.top(1)[0])
            ]

    range: (extent) ->
        if @_type is 'ordinal'
            @_scale.rangeRoundBands extent, 0.1
        else
            @_scale.range extent

axis = (dim, type) ->
    new Axis dim, type

defaultAxis = (dim) ->
    vals = d3.nest().key((d) -> d.key).map dim._dim.group().all()
    scale = d3.scale.linear()
    ax =
        _scale: scale
        _map: (d) -> scale if not vals[dim._get d]? then 0 else vals[dim._get d][0].value
        _axis: d3.svg.axis().scale(scale)
        _brush: ->

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
        ax.range [0, @_width]
        ax._brush
            .x(ax._scale)
        @_x = ax

        if not @_y?
            axy = defaultAxis ax._dim
            axy._scale.range([@_height, 0])
            axy._axis.orient('left')
            @_y = axy

    y: (ax) ->
        ax.range [@_height, 0]
        ax._axis.orient('left')
        ax._brush
            .y(ax._scale)
        @_y = ax

        if not @_x?
            axx = defaultAxis ax._dim
            axx._scale.range([0, @_width])
            @_x = axx

    r: (ax) ->
        ax._scale.range([2, 8])
        @_r = ax

    fill: (ax) ->
        @_fill = ax

    draw: (records) ->
        if @_x?
            @_svg.select('.x.axis')
                .call(@_x._axis)
                .selectAll('.label')
                .text(@_x._name)
            @_svg.select('.x.brush')
                .call(@_x._brush)
                .selectAll('rect')
                .attr('height', brushSize)
        if @_y?
            @_svg.select('.y.axis')
                .call(@_y._axis)
                .selectAll('.label')
                .text(@_y._name)
            @_svg.select('.y.brush')
                .call(@_y._brush)
                .selectAll('rect')
                .attr('x', -brushSize)
                .attr('width', brushSize)

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

# create a new hypercube
hypercube = (records) ->
    cube =
        _xf: crossfilter records
        _dims: []
        _projs: []

    cube.dimension = (name, accessor) ->
        d = dimension cube._xf, name, accessor
        cube._dims.push d
        d

    cube.projection = (selector, width, height, margin) ->
        p = projection selector, width, height, margin
        cube._projs.push p
        p

    cube

return hypercube
