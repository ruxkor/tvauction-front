'use strict'

chai = require 'chai'
sinon = require 'sinon'
should = chai.should()

mw = require '../app/middleware'
AuctionModel = mw.AuctionModel
CampaignModel = mw.CampaignModel

describe 'AuctionModel', ->
  db = am = null

  beforeEach ->
    db = {'query': (cb) -> cb() }
    am = new AuctionModel db

  describe 'changeStatus', ->
    it 'should be truey if change status if matching', (_) ->
      db_mock = sinon.mock(db)
      db_mock.expects('query').once().yields(null, {changedRows: 1})
      res = am.changeStatus 1, 'state_a', 'state_b', _
      res.should.eql 1
      db_mock.verify()

    it 'should be falsy if status is not matching', (_) ->
      db_mock = sinon.mock(db)
      db_mock.expects('query').once().yields(null, {changedRows: 0})
      res = am.changeStatus 0, 'state_a', 'state_b', _
      res.should.eql 0
      db_mock.verify()


  describe 'getAndlock', ->
    it 'should return null if no auction is found', (_) ->
      sinon.mock(db).expects('query').once().yields(null, [])
      auction_data = am.getAndLock _
      should.not.exist auction_data

    it 'should return an auction if there is one, and then lock it', (_) ->
      db_mock = sinon.mock db
      am_mock = sinon.mock am
      db_mock
        .expects('query').once()
        .withArgs(AuctionModel.get_and_lock_query)
        .yields(null, [{id:1}])
      am_mock
        .expects('changeStatus').once()
        .withArgs(1)
        .yields(null, 1)        
      auction_data = am.getAndLock _
      should.exist auction_data
      auction_data.id.should.be.eql 1
      db_mock.verify()
      am_mock.verify()

    it 'should return the correct auction if something changed', (_) ->
      db_mock = sinon.mock db
      am_mock = sinon.mock am
      db_mock
        .expects('query').once()
        .withArgs(AuctionModel.get_and_lock_query)
        .yields(null, [{id:1}, {id: 2}])
      am_mock
        .expects('changeStatus').once()
        .withArgs(1)
        .yields(null, 0)
      am_mock
        .expects('changeStatus').once()
        .withArgs(2)
        .yields(null, 1)
      auction_data = am.getAndLock _
      should.exist auction_data
      auction_data.id.should.be.eql 2
      db_mock.verify()
      am_mock.verify()

describe 'Middleware', ->
  




