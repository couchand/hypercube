# hypercube data browser

# create a new dimension
dimension = (xf, accessor) ->
    dim =
        _get: accessor
        _dim: xf.dimension accessor

    dim

axis = (dim, type) ->
    ax =
        _scale: scale = if type is 'time' then d3.time.scale() else d3.scale[type]()
        _map: (d) -> scale dim._get d
        _axis: d3.svg.axis().scale(scale)

    ax._scale.domain [dim._get(dim._dim.bottom(1)[0]), dim._get(dim._dim.top(1)[0])]

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
            .attr('r', proj._r._map)
            .attr('cx', proj._x._map)
            .attr('cy', proj._y._map)
            .attr('fill', proj._fill._map)

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
