chai = require 'chai'
sinon = require 'sinon'
chai.should()
 
routesFn = require '../app/routes'
class MockResponse
  constructor: ->
    @data = ''
    @open = true
  send: (data) ->
    throw new Error('not open') if not @open
    @data += data
  end: (data) ->
    throw new Error('not open') if not @open
    @data += data
    @open = false

describe '/user/login', (_) ->
  routes = db = db_mock = req = res = null
  next = ->
  beforeEach ->
    db = {'query': (cb) -> cb(0) }
    db_mock = sinon.mock db
    routes = routesFn {}, db
    req = {session: {}}
    res = new MockResponse()

  afterEach ->
    db_mock.verify()

  it 'should return a user id when we pass correct credentials', (_) ->
    db_mock
      .expects('query').once()
      .yields(null, [{id: 999, password: '$2a$10$zAPC12E6sSOaSZPr56di4.e/SEMtSdJ9XhZH.jajBdDk/eYRNMkhG' }])
    req.body =
      email: 'test@test.com'
      password: 'test'
    routes.user.login(req, res, next, _)
    res.data.should.eql '999'

  it 'should return a user id of 0 if the password is incorrect', (_) ->
    db_mock
      .expects('query').once()
      .yields(null, [{id: 999, password: '$2a$10$zAPC12E6sSOaSZPr56di4.e/SEMtSdJ9XhZH.jajBdDk/eYRNMkhG' }])
    req.body =
      email: 'test@test.com'
      password: 'invalid'
    routes.user.login(req, res, next, _)
    res.data.should.eql '0'

  it 'should return a user id of 0 if the username is not found', (_) ->
    db_mock
      .expects('query').once()
      .yields(null, [])
    req.body =
      email: 'test@test.com'
      password: 'test'
    routes.user.login(req, res, next, _)
    res.data.should.eql '0'
