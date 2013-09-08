# hypercube data browser

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

    if type is 'ordinal'
        ax._scale.domain dim._dim.group().all().map (d) -> d.key
    else
        ax._scale.domain [
            dim._get(dim._dim.bottom(1)[0]),
            dim._get(dim._dim.top(1)[0])
        ]

    ax

projection = (selector, w, h, m) ->
    m ?= 50
    proj =
        _svg: d3.select(selector).append('svg')
            .attr('width', w + 2*m)
            .attr('height', h + 2*m)
            .append('g')
            .attr('transform', "translate(#{m},#{m})")

    proj.x = (dim, type) ->
        ax = axis dim, type
        if type is 'ordinal'
            ax._scale.rangeRoundBands [0, w], 0.1
        else
            ax._scale.range([0, w])
        proj._x = ax
        proj._svg.append('g')
            .attr('class', 'x axis')
            .attr('transform', "translate(0,#{h})")
            .call(ax._axis)

    proj.y = (dim, type) ->
        ax = axis dim, type
        ax._scale.range([h, 0])
        ax._axis.orient('left')
        proj._y = ax
        proj._svg.append('g')
            .attr('class', 'y axis')
            .call(ax._axis)

    proj.r = (dim, type) ->
        ax = axis dim, type
        ax._scale.range([2, 6])
        proj._r = ax

    proj.fill = (dim, type) ->
        ax = axis dim, type
        proj._fill = ax

    proj.draw = (records) ->
        proj._svg.selectAll('.record')
            .data(records)
            .enter().append('circle')
            .attr('class', 'record')
            .attr('r', if proj._r? then proj._r._map else 3)
            .attr('cx', if proj._x? then proj._x._map else 0)
            .attr('cy', if proj._y? then proj._y._map else 0)
            .attr('fill', if proj._fill? then proj._fill._map else 'red')

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
