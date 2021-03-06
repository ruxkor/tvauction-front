'use strict'

debug = require('debug')('tvauction:server')
http = require 'http'
fs = require 'fs'
path = require 'path'
urlparser = require 'url'
optimist = require 'optimist'
mysql = require 'mysql'
express = require 'express'

configDefault = JSON.parse(fs.readFileSync(__dirname+'/config.json'))
config = optimist
  .usage('tvAuction front/middleware\nusage: $0')
  .alias('h','help').describe('help','you\'re looking at it.')
  .alias('d','db').describe('db','database connection arguments')
  .default(configDefault)
  .argv

if config.help
  optimist.showHelp()
  process.exit()

checkSession = (req, res, next) ->
  url = urlparser.parse req.url, true
  matches = [/^\/$/, /^\/help$/, /^\/(js|lib|css|partials|test)\//, /^\/user\/(login|check)$/]
  matched = matches.some (r) -> url.pathname.match r
  if not matched and not req.session.auth
    res.writeHead 403
    res.end 'not authenticated'
  else
    next()

checkIntValue = (valName) ->
  (req, res, next, id) ->
    id = ~~id
    if not id
      res.writeHead 404
      res.end "invalid value for #{valName}"
      return
    else
      req.params[valName] = id
      next()

app = express()
app.configure ->
  app.set 'port', process.env.PORT or 3000
  app.set 'views', path.join(__dirname, '/views')
  app.set 'view engine', 'jade'
  app.use express.favicon()
  # app.use express.logger('dev')
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
db = require('./app/database')(config)
routes = require('./app/routes')(config, db)
middleware = require('./app/middleware').init(config, db)

# guarantee integer values and throw an error if they are not set
for valName in ['auction_id']
  app.param valName, checkIntValue(valName)

app.get '/user/login', routes.user.login
app.post '/user/login', routes.user.login
app.get '/user/logout', routes.user.logout
app.get '/user/check', routes.user.check

app.get '/auction', routes.auction.index
app.get '/auction/:auction_id', routes.auction.show

app.get '/campaign', routes.campaign.index
app.get '/campaign/:auction_id', routes.campaign.show
app.post '/campaign/:auction_id', routes.campaign.create
app.put '/campaign/:auction_id', routes.campaign.update
app.delete '/campaign/:auction_id', routes.campaign.delete

app.get '/result/:auction_id', routes.result.show

app.get '/admin/refresh', (req,res,next,_) -> 
  middleware.refresh(_)
  res.end ''

http.createServer(app).listen app.get('port'), _
debug('http server online')


setTimeout _, 1000
middleware.refresh _
