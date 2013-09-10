# data browser

draggable = (selection) ->
    selection.forEach (el) ->
        $(el).draggable
            revert: yes

browser = () ->
    cube = hypercube([])

    $viz = $ '#viz'

    sourceList = d3.select('#sources').select('ul')
    dimensionList = d3.select('#dimensions').select('ul')
    groupList = d3.select('#groups').select('ul')
    plot = cube.projection('#viz', $viz.width(), $viz.height())

    $('#dimensions').droppable
        accept: '#sources li'
        drop: (e, ui) ->
            dimension $(ui.draggable).text()

    $('#groups').droppable
        accept: '#dimensions li'
        drop: (e, ui) ->
            group ui.draggable[0].__data__

    $viz.droppable
        accept: '#dimensions li, #groups li'
        drop: (e, ui) ->
            if not ui.draggable.hasClass 'group'
                axis = prompt 'axis (x, y, r)'
                type = 'sqrt' if axis is 'r'
                type = prompt 'type (linear, log, time, etc.)' if not type?
            else
                axis = prompt 'axis (x, y, fill)'
                type = if axis is 'fill' then 'category20' else 'ordinal'
            plot[axis](ui.draggable[0].__data__.axis type)
            plot.draw cube._dims[0]._dim.top Infinity

    search = (type, name, url, clean) ->
        warehouse.fetch type, url, clean, (records) ->
            records.forEach (record) ->
                record._source = name

            li = sourceList.append('li')
            li.append('span')
                .text(name)
            li.append('ul')
                .selectAll('li')
                .data(warehouse.fields(records))
                .enter().append('li')
                .call(draggable)
                .text (d) -> d

            cube._xf.add(records)

    dimension = (field, fn) ->
        fn = if typeof fn is 'function' then fn else accessor field
        d = cube.dimension field, fn
        d._name = field
        li = dimensionList.append('li')
            .attr('class', 'dimension')
            .datum(d)
            .call(draggable)
        li.append('span')
            .text(field)
        d

    group = (dim) ->
        g = dim.group()
        li = groupList.append('li')
            .attr('class', 'group')
            .datum(g)
            .call(draggable)
        li.append('span')
            .text(dim._name)
        li.append('ul').selectAll('li')
            .data(g._group.top(3))
            .enter().append('li')
            .text (d) -> d.key
        g

    {
        search: search
        cube: cube
        plot: plot
        dimension: dimension
        group: group
    }

return browser
