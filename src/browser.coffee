# data browser

browser = () ->
    cube = hypercube([])

    sources = d3.select('#sources')
    dimensions = d3.select('#dimensions')
    groups = d3.select('#groups')
    plot = cube.projection('#viz', 600, 600)

    search = (url, clean) ->
        warehouse.fetch url, clean, (records) ->
            li = sources.select('ul').append('li')
            li.append('span')
                .text(url)
            li.append('ul')
                .selectAll('li')
                .data(warehouse.fields(records))
                .enter().append('li')
                .text (d) -> d
            cube._xf.add(records)

    {
        search: search
        cube: cube
        plot: plot
    }

return browser
