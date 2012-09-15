'use strict'

express = require('express')
routes = require('./routes')
http = require('http')
path = require('path')
urlparser = require('url')

checkSession = (req, res, next) ->
  url = urlparser.parse req.url, true
  if url.pathname.match(/^\/[^\/]*$/) or url.pathname.match(/^\/(js|lib|css|partials|test)\//) or url.pathname.match(/^\/user\/(login|logout|check)$/)
    next()
    return
  else if not req.session.auth
    res.writeHead 403
    res.end 'not authenticated'
    return

app = express()
app.configure ->
  app.set 'port', process.env.PORT or 3000
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser('blabla')
  app.use express.cookieSession()
  app.use checkSession
  app.use app.router
  app.use '/test', express.static(path.join(__dirname, 'test'))
  app.use express.static(path.join(__dirname, 'public'))

app.configure 'development', ->
  app.use express.errorHandler()

app.param 'user', (req, res, next, id) ->
  console.info arguments
  if ~~id == 2
    next()
  else
    next new Error('nono')

###
GET     /thing              ->  index
GET     /thing/new          ->  new
POST    /thing              ->  create
GET     /thing/:thing       ->  show
GET     /thing/:thing/edit  ->  edit
PUT     /thing/:thing       ->  update
DELETE  /thing/:thing       ->  destroy
###

# routes
app.post '/user/login', routes.user.login
app.get '/user/logout', routes.user.logout
app.get '/user/check', routes.user.check

app.get '/auction', routes.auction.index
app.get '/auction/:auction', routes.auction.show

app.get '/campaign', routes.campaign.index
app.get '/campaign/:campaign', routes.campaign.show
app.post '/campaign', routes.campaign.create
app.put '/campaign/:campaign', routes.campaign.update
app.delete '/campaign/:campaign', routes.campaign.delete


# create web server
http.createServer(app).listen app.get('port'), ->
  console.log 'Express server listening on port ' + app.get('port')

