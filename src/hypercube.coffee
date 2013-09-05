# hypercube data browser

# create a new dimension
dimension = (xf, accessor, type) ->
    dim =
        _get: accessor
        _dim: xf.dimension accessor
        _scale: scale = if type is 'time' then d3.time.scale() else d3.scale[type]()
        _map: (d) -> scale accessor d
        _axis: d3.svg.axis().scale(scale)

    dim._scale.domain [dim._get(dim._dim.bottom(1)[0]), dim._get(dim._dim.top(1)[0])]

    dim

graph = (selector, w, h, m) ->
    m ?= 50
    gr =
        _svg: d3.select(selector).append('svg')
            .attr('width', w + 2*m)
            .attr('height', h + 2*m)
            .append('g')
            .attr('transform', "translate(#{m},#{m})")

    gr.x = (dim) ->
        dim._scale.range([0, w])
        gr._x = dim
        gr._svg.append('g')
            .attr('class', 'x axis')
            .attr('transform', "translate(0,#{h})")
            .call(dim._axis)

    gr.y = (dim) ->
        dim._scale.range([h, 0])
        dim._axis.orient('left')
        gr._y = dim
        gr._svg.append('g')
            .attr('class', 'y axis')
            .call(dim._axis)

    gr.r = (dim) ->
        dim._scale.range([2, 6])
        gr._r = dim

    gr.fill = (dim) ->
        gr._fill = dim

    gr.draw = (records) ->
        gr._svg.selectAll('.record')
            .data(records)
            .enter().append('circle')
            .attr('class', 'record')
            .attr('r', gr._r._map)
            .attr('cx', gr._x._map)
            .attr('cy', gr._y._map)
            .attr('fill', gr._fill._map)

    gr

# create a new hypercube
hypercube = (records) ->
    cube =
        _xf: crossfilter records
        _dims: []

    cube.dimension = (accessor, type) ->
        d = dimension cube._xf, accessor, type
        cube._dims.push d
        d

    cube.graph = graph

    cube
