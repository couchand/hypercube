# browser

warehouse = []

fetch = (url, clean) ->
    d3.json url, (err, data) ->
        return console.error err if err
        clean(data).forEach (d) ->
            warehouse.push d

fields = ->
    all = {}
    warehouse.forEach (d) ->
        d3.keys(d).forEach (k) ->
            all[k] = yes
    d3.keys all

return {
    fetch: fetch
    fields: fields
    records: -> warehouse
}
