'use strict'

exports.index = (req, res) ->
  res.send 'ui'

exports.user =
  login: (req, res) ->
    email = req.body.email
    password = req.body.password
    session = req.session

    authed = false
    user_id = 0
    if email == 'test@test.com'
      session.user_id = user_id = 2
      session.auth = authed = true

    res.end JSON.stringify(user_id)

  logout: (req, res) ->
    req.session = null
    res.end()

  check: (req, res) ->
    user_id = req.session.user_id or 0
    res.end JSON.stringify(user_id)

exports.auction =
  index: (req, res) ->
  create: (req, res) ->
  update: (req, res) ->
  delete: (req, res) ->

exports.campaign =
  index: (req, res) ->
  create: (req, res) ->
  update: (req, res) ->
  delete: (req, res) ->
