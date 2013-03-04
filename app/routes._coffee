'use strict'

__ = require 'underscore'
bcrypt = require 'bcrypt'
debug = require('debug')('tvauction:routes')

handleError = (err) ->
  throw err if err


module.exports = (config, db) ->
  that = this

  auctionIsExistingAndBeforeDeadline = (auction_id, _) ->
    rows = db.query 'SELECT 1 FROM auction WHERE id=? AND deadline > NOW()', [auction_id], _
    return !!rows.length

  user:
    # route for the user login.
    # compares the email and the bcrypted password hash
    # if successful, the user_id is returned and the session authenticated
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

      debug 'user %s logged in. user_id: %d', email, session.user_id if session.user_id
      debug 'user %s could not log in', email unless session.user_id

      res.end ''+session.user_id


    # logs the user out by deleting his session
    # returns user_id 0 (i.e. logged out)
    logout: (req, res) ->
      debug 'user %d logged out', req.session and req.session.user_id
      req.session = null
      res.end "0"


    # checks for a valid login
    # returns the user's user_id or 0 (i.e. logged out)
    check: (req, res) ->
      user_id = req.session.user_id or 0
      res.end ''+user_id


  # auction routes
  auction:
    # get all available auctions
    index: (req, res, next, _) ->
      stmt = ''' 
        SELECT auction.id, auction.state, auction.from, auction.to, auction.deadline, campaign.id as campaign_id
        FROM auction 
        LEFT JOIN campaign ON (campaign.auction_id=auction.id AND campaign.user_id=?)
        WHERE campaign.id IS NOT NULL OR auction.deadline > NOW()
        ORDER BY auction.from'''
      rows = db.query stmt, [req.session.user_id], _
      res.end JSON.stringify(rows)


    # gets a specific auction
    show: (req, res, next, _) ->
      auction_id = req.params.auction_id
      rows = db.query 'SELECT * from auction WHERE id=?', [auction_id], _
      debug 'got auction %d', auction_id if rows.length
      if not rows.length
        res.writeHead 404
        res.end()
      else
        auction = rows[0]
        reaches = db.query 'SELECT * from auction_reach WHERE auction_id=?', [auction_id], _
        res.end JSON.stringify(
          auction: auction
          reaches: reaches
        )

  # campaign routes
  campaign:
    # lists all campaigns for a user
    index: (req, res, next, _) ->
      stmt = '''SELECT 
                  campaign.id, campaign.auction_id, campaign.published, campaign.modified, 
                  auction.state auction_state, auction.from auction_from, auction.to auction_to, auction.deadline auction_deadline
                FROM campaign
                JOIN auction ON (auction.id=campaign.auction_id)
                WHERE campaign.user_id=?
                ORDER BY auction.from, auction.deadline'''
      rows = db.query stmt, [req.session.user_id], _
      res.end JSON.stringify(rows)


    # gets a specific campaign
    # a user can only get his own campaigns
    show: (req, res, next, _) ->
      auction_id = req.params.auction_id
      rows = db.query 'SELECT * from campaign WHERE auction_id=? and user_id=?', [auction_id, req.session.user_id], _
      debug 'got campaign %d for user %d', auction_id, req.session.user_id if rows.length
      if not rows.length
        res.writeHead 404
        res.end()
      else
        campaign = rows[0]
        res.end JSON.stringify(campaign)


    # create a campaign
    create: (req, res, next, _) ->
      auction_id = req.params.auction_id
      if not auctionIsExistingAndBeforeDeadline auction_id, _
        res.writeHead 403
        res.end 'auction not existing or locked'
        return
      
      campaign = __.omit req.body, 'id'
      campaign.content = JSON.stringify campaign.content

      __.extend campaign,
        auction_id: auction_id
        user_id: req.session.user_id
        published: !!req.body.published
        modified: new Date()

      params = [campaign]
      rows = db.query 'INSERT INTO campaign SET ?', params, _
      debug 'created campaign %d for user %d', auction_id, req.session.user_id if rows.affectedRows
      res.end ''+rows.insertId


    # update a campaign
    update: (req, res, next, _) ->
      auction_id = req.params.auction_id
      if not auctionIsExistingAndBeforeDeadline auction_id, _
        res.writeHead 403
        res.end 'auction not existing or locked'
        return

      campaign = __.omit req.body, 'id', 'content'
      campaign.content = JSON.stringify req.body.content if req.body.content

      __.extend campaign,
        auction_id: auction_id
        user_id: req.session.user_id
        published: !!req.body.published
        modified: new Date()

      params = [campaign, auction_id, req.session.user_id]
      rows = db.query 'UPDATE campaign SET ? WHERE auction_id=? AND user_id=?', params, _
      
      debug 'updated campaign %d for user %d', auction_id, req.session.user_id if rows.affectedRows
      if rows.affectedRows
        params = [auction_id, req.session.user_id]
        rows = db.query 'SELECT id FROM campaign WHERE auction_id=? AND user_id=?', params, _
        res.end ''+rows[0].id
      else
        res.writeHead 500
        res.end()


    # delete a campaign. the campaign 
    delete: (req, res, next, _) ->
      auction_id = req.params.auction_id
      if not auctionIsExistingAndBeforeDeadline auction_id, _
        res.writeHead 403
        res.end 'auction not existing or locked'
        return

      params = [auction_id, req.session.user_id]
      rows = db.query 'DELETE FROM campaign WHERE auction_id=? AND user_id=?', params, _
      debug 'deleted campaign %d for user %d', auction_id, req.session.user_id if rows.affectedRows
      res.end ''+rows.affectedRows

  # result routes
  result:
    show: (req, res, next, _) ->
      user_id = req.session.user_id
      auction_id = req.params.auction_id
      stmt = '''SELECT result.content FROM result
                JOIN campaign on (campaign.auction_id=result.auction_id)
                WHERE campaign.auction_id=? AND campaign.user_id=?
             '''
      rows = db.query stmt, [auction_id, user_id], _
      
      if not rows.length
        res.writeHead 404
        res.end()
      else
        result_data = JSON.parse rows[0].content
        winning_bid = result_data.winners
          .filter((b) -> b[0]==user_id)
          .map((b) -> b[1])[0]
        price_bid = result_data.prices_bid[user_id]
        price_final = result_data.prices_final[user_id]
        result =
          bid: if winning_bid != undefined then winning_bid else null
          price: price_final
          slots: if user_id of result_data.winners_slots then result_data.winners_slots[user_id] else []
        res.end JSON.stringify result
