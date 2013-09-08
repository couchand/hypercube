# hypercube data browser

logFormat = d3.format ",.0f"
brushSize = 30

# create a new dimension
dimension = (xf, accessor) ->
    dim =
        _get: accessor
        _dim: xf.dimension accessor

    dim

axis = (dim, type) ->
    scale = if type is 'time' then d3.time.scale() else d3.scale[type]()
    offset = if type is 'ordinal' then ((d)-> d + scale.rangeBand()*0.5) else ((d) -> d)
    ax =
        _scale: scale
        _map: (d) -> offset scale dim._get d
        _axis: d3.svg.axis().scale(scale)
        _brush: d3.svg.brush()

    ax._axis.tickFormat(logFormat) if type is 'log'
    ax._brush.on 'brush', ->
        dim._dim.filterRange ax._brush.extent()

    if type is 'ordinal'
        ax._scale.domain dim._dim.group().all().map (d) -> d.key
    else
        ax._scale.domain [
            dim._get(dim._dim.bottom(1)[0]),
            dim._get(dim._dim.top(1)[0])
        ]

    ax

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

projection = (selector, w, h, m) ->
    m ?= 50
    proj =
        _svg: d3.select(selector).append('svg')
            .attr('width', w + 2*m)
            .attr('height', h + 2*m)
            .append('g')
            .attr('transform', "translate(#{m},#{m})")

    proj._svg.append('g')
        .attr('class', 'x axis')
        .attr('transform', "translate(0,#{h})")
    proj._svg.append('g')
        .attr('class', 'x brush')
        .attr('transform', "translate(0,#{h})")
    proj._svg.append('g')
        .attr('class', 'y axis')
    proj._svg.append('g')
        .attr('class', 'y brush')

    proj.x = (dim, type) ->
        ax = axis dim, type
        if type is 'ordinal'
            ax._scale.rangeRoundBands [0, w], 0.1
        else
            ax._scale.range([0, w])
        ax._brush
            .x(ax._scale)
        proj._x = ax

        if not proj._y?
            axy = defaultAxis dim
            axy._scale.range([h, 0])
            axy._axis.orient('left')
            proj._y = axy

    proj.y = (dim, type) ->
        ax = axis dim, type
        if type is 'ordinal'
            ax._scale.rangeRoundBands [h, 0], 0.1
        else
            ax._scale.range([h, 0])
        ax._axis.orient('left')
        ax._brush
            .y(ax._scale)
        proj._y = ax

        if not proj._x?
            axx = defaultAxis dim
            axx._scale.range([0, w])
            proj._x = axx

    proj.r = (dim, type) ->
        ax = axis dim, type
        ax._scale.range([2, 8])
        proj._r = ax

    proj.fill = (dim, type) ->
        ax = axis dim, type
        proj._fill = ax

    proj.draw = (records) ->
        if proj._x?
            proj._svg.select('.x.axis')
                .call(proj._x._axis)
            proj._svg.select('.x.brush')
                .call(proj._x._brush)
                .selectAll('rect')
                .attr('height', brushSize)
        if proj._y?
            proj._svg.select('.y.axis')
                .call(proj._y._axis)
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

    cube.dimension = (accessor) ->
        d = dimension cube._xf, accessor
        cube._dims.push d
        d

    cube.projection = (selector, width, height, margin) ->
        p = projection selector, width, height, margin
        cube._projs.push p
        p

    cube

return hypercube
