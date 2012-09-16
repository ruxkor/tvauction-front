'use strict'
bcrypt = require 'bcrypt'

module.exports = (config, db) ->
  index: (req, res) ->
    res.send 'ui'

  user:
    login: (req, res, next, _) ->
      email = req.body.email
      password = req.body.password
      session = req.session

      session.user_id = 0
      if email and password
        rows = db.query 'SELECT id, password FROM user WHERE email = ?', [email], _
        if rows.length
          hashIsValid = bcrypt.compare password, rows[0].password , _
          if hashIsValid
            session.user_id = rows[0].id
            session.auth = true

      res.end ''+session.user_id

    logout: (req, res) ->
      req.session = null
      res.end "0"

    check: (req, res) ->
      user_id = req.session.user_id or 0
      res.end JSON.stringify(user_id)

  auction:
    index: (req, res) ->
    create: (req, res) ->
    update: (req, res) ->
    delete: (req, res) ->

  campaign:
    index: (req, res) ->
    create: (req, res) ->
    update: (req, res) ->
    delete: (req, res) ->
