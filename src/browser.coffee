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
        drop: (e, ui) ->
            dimension $(ui.draggable).text()

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
        li = dimensionList.append('li')
        li.append('span')
            .text(field)
        cube.dimension accessor field

    {
        search: search
        cube: cube
        plot: plot
        dimension: dimension
    }

return browser
