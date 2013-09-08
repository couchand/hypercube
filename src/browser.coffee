# data browser

draggable = (selection) ->
    selection.forEach (el) ->
        $(el).draggable
            revert: yes

browser = () ->
    cube = hypercube([])

    sourceList = d3.select('#sources').select('ul')
    dimensionList = d3.select('#dimensions').select('ul')
    groupList = d3.select('#groups').select('ul')
    plot = cube.projection('#viz', 600, 600)

    $('#dimensions').droppable
        accept: '#sources li'
        drop: (e, ui) ->
            dimension $(ui.draggable).text()

    $('#viz').droppable
        accept: '#dimensions li'
        drop: (e, ui) ->
            axis = prompt 'axis (x, y, r, fill)'
            type = 'category20' if axis is 'fill'
            type = 'sqrt' if axis is 'r'
            type = prompt 'type' if not type?
            plot[axis](ui.draggable[0].__data__, type)
            plot.draw cube._dims[0]._dim.top Infinity

    search = (url, clean) ->
        warehouse.fetch url, clean, (records) ->
            li = sourceList.append('li')
            li.append('span')
                .text(url)
            li.append('ul')
                .selectAll('li')
                .data(warehouse.fields(records))
                .enter().append('li')
                .call(draggable)
                .text (d) -> d

            cube._xf.add(records)

    dimension = (field) ->
        d = cube.dimension accessor field
        li = dimensionList.append('li')
            .datum(d)
            .call(draggable)
        li.append('span')
            .text(field)
        d

    {
        search: search
        cube: cube
        plot: plot
        dimension: dimension
    }

return browser
