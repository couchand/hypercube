# basic server

express = require 'express'
app = express()

request = require 'request'

#app.use express.static 'example'
app.use express.static 'www'

app.get '/fetch/:url', (req, res) ->
    protocol = 'http'
    url = req.params.url
    url = "#{protocol}://#{url}" unless 0 is url.indexOf protocol
    request url, (error, response, body) ->
        body = body[1...body.length-1] if body[0] is '('
        res.send body

app.listen 3000
console.log 'Listening on localhost:3000'
