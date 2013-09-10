# warehouse

class Warehouse
    constructor: ->
        @_warehouse = []

    fetch: (type, url, clean, cb) ->
        w = @_warehouse
        d3[type] url, (err, data) ->
            return console.error err if err
            cleaned = clean(data)
            cleaned.forEach (d) ->
                w.push d
            cb cleaned

    fields: (_) ->
        all = {}
        (if _? then _ else @_warehouse).forEach (d) ->
            d3.keys(d).forEach (k) ->
                all[k] = yes
        d3.keys all

    records: ->
        @_warehouse

return new Warehouse()
