# warehouse

warehouse = []

fetch = (url, clean, cb) ->
    d3.json url, (err, data) ->
        return console.error err if err
        cleaned = clean(data)
        cleaned.forEach (d) ->
            warehouse.push d
        cb cleaned

fields = (_) ->
    all = {}
    (if _? then _ else warehouse).forEach (d) ->
        d3.keys(d).forEach (k) ->
            all[k] = yes
    d3.keys all

return {
    fetch: fetch
    fields: fields
    records: -> warehouse
}
