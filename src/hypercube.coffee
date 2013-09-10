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

projection = (selector, w, h) ->
    m = h * 0.1
    proj =
        _svg: d3.select(selector).append('svg')
            .attr('width', w)
            .attr('height', h)
            .append('g')
            .attr('transform', "translate(#{m},#{m})")

    w -= 2*m
    h -= 2*m

    proj._svg.append('g')
        .attr('class', 'x axis')
        .attr('transform', "translate(0,#{h})")
        .append('text')
        .attr('class', 'label')
        .attr('text-anchor', 'end')
        .attr('transform', "translate(#{w},36)")
    proj._svg.append('g')
        .attr('class', 'x brush')
        .attr('transform', "translate(0,#{h})")
    proj._svg.append('g')
        .attr('class', 'y axis')
        .append('text')
        .attr('class', 'label')
        .attr('text-anchor', 'start')
        .attr('transform', 'translate(-40,-16)')
    proj._svg.append('g')
        .attr('class', 'y brush')

    proj.x = (ax) ->
        ax.range [0, w]
        ax._brush
            .x(ax._scale)
        proj._x = ax

        if not proj._y?
            axy = defaultAxis ax._dim
            axy._scale.range([h, 0])
            axy._axis.orient('left')
            proj._y = axy

    proj.y = (ax) ->
        ax.range [h, 0]
        ax._axis.orient('left')
        ax._brush
            .y(ax._scale)
        proj._y = ax

        if not proj._x?
            axx = defaultAxis ax._dim
            axx._scale.range([0, w])
            proj._x = axx

    proj.r = (ax) ->
        ax._scale.range([2, 8])
        proj._r = ax

    proj.fill = (ax) ->
        proj._fill = ax

    proj.draw = (records) ->
        if proj._x?
            proj._svg.select('.x.axis')
                .call(proj._x._axis)
                .selectAll('.label')
                .text(proj._x._name)
            proj._svg.select('.x.brush')
                .call(proj._x._brush)
                .selectAll('rect')
                .attr('height', brushSize)
        if proj._y?
            proj._svg.select('.y.axis')
                .call(proj._y._axis)
                .selectAll('.label')
                .text(proj._y._name)
            proj._svg.select('.y.brush')
                .call(proj._y._brush)
                .selectAll('rect')
                .attr('x', -brushSize)
                .attr('width', brushSize)

        circle = proj._svg.selectAll('.record')
            .data(records)

        circle
            .enter().append('circle')
            .attr('class', 'record')

        circle
            .exit().remove()

        circle
            .attr('r', if proj._r? then proj._r._map else 3)
            .attr('cx', if proj._x? then proj._x._map else 0)
            .attr('cy', if proj._y? then proj._y._map else 0)
            .attr('fill', if proj._fill? then proj._fill._map else 'black')

    proj

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
