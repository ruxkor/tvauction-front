'use strict'
bcrypt = require 'bcrypt'

handleError = (err) ->
  throw err if err

module.exports = (config, db) ->
  user:
    # route for the user login.
    # compares the email and the bcrypted password hash
    # if successful, the user_id is returned and the session authenticated
    login: (req, res) -> ( (_) ->
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
    )(handleError)


    # logs the user out by deleting his session
    # returns user_id 0 (i.e. logged out)
    logout: (req, res) ->
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
    index: (req, res) -> ( (_) ->
      stmt = ''' 
        SELECT auction.id, auction.from, auction.to, auction.deadline, campaign.id as campaign_id
        FROM auction 
        LEFT JOIN campaign ON (campaign.auction_id=auction.id AND campaign.user_id=?)
        WHERE campaign.id IS NOT NULL OR auction.deadline > NOW()
        ORDER BY auction.from'''
      rows = db.query stmt, [req.session.user_id], _
      res.end JSON.stringify rows
    )(handleError)


    # gets a specific auction
    show: (req, res) -> ( (_) ->
      auction_id = req.params.auction
      rows = db.query 'SELECT * from auction WHERE id=?', [auction_id], _
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
    )(handleError)


  # campaign routes
  campaign:
    # lists all campaigns for a user
    index: (req, res) -> ( (_) ->
      stmt = '''SELECT campaign.id, campaign.auction_id, campaign.published, campaign.modified, auction.from, auction.to, auction.deadline
                JOIN auction ON (auction.id=campaign.auction_id)
                WHERE campaign.user_id=?
                ORDER BY auction.from'''
      rows = db.query stmt, [req.session.user_id], _
      res.end JSON.stringify rows
    )(handleError)


    # gets a specific campaign
    # a user can only get his own campaigns
    show: (req, res) -> ( (_) ->
      campaign_id = req.params.campaign
      if not campaign_id
        res.writeHead
        res.end()
        return
      rows = db.query 'SELECT * from campaign WHERE id=? and user_id=?', [campaign_id, req.session.user_id], _
      if not rows.length
        res.writeHead 404
        res.end()
      else
        campaign = rows[0]
        res.end JSON.stringify(campaign)
    )(handleError)


    # create a campaign
    create: (req, res) -> ( (_) ->
      campaign_id = req.params.campaign
      campaign_columns =
        user_id: req.session.user_id
        auction_id: ~~req.body.auction_id
        published: !!req.body.published
        modified: new Date()
        content: req.body.campaign

      # check if a campaign can still be created for the auction
      rows = db.query 'SELECT 1 FROM auction WHERE id=? AND deadline < NOW()', [campaign_columns.auction_id], _
      if not rows.length
        res.writeHead 403
        res.end 'auction not existing or locked'
        return

      params = [campaign_id, req.session.user_id]
      rows = db.query 'INSERT INTO campaign SET ?', params, _
      res.end ''+rows.affectedRows
    )(handleError)


    # update a campaign
    update: (req, res) -> ( (_) ->
      campaign_id = req.params.campaign
      campaign_columns =
        published: req.body.published
        modified: new Date()
      # only update the content field if passed
      if req.body.campaign
        campaign_columns.content = req.body.campaign

      # check if a campaign can still be created for the auction
      stmt = '''SELECT 1 FROM campaign
                JOIN auction ON (auction.id=campaign.auction_id AND auction.deadline > NOW())
                WHERE campaign.id=? AND campaign.user_id=?'''
      rows = db.query stmt, [campaign_id, req.session.user_id]
      if not rows.length
        res.writeHead 403
        res.end 'auction not existing or locked'
        return

      params = [campaign_columns, campaign_id, req.session.user_id]
      rows = db.query 'UPDATE campaign SET ? WHERE campaign_id=? AND user_id=?', params, _
      res.end ''+rows.affectedRows
    )(handleError)


    # delete a campaign. the campaign 
    delete: (req, res) -> ( (_) ->
      params = [campaign_id, req.session.user_id]
      rows = db.query 'DELETE FROM campaign WHERE campaign_id=? AND user_id=?', params, _
      res.end ''+rows.affectedRows
    )(handleError)
