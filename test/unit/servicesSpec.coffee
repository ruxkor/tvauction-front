'use strict'

describe 'service', ->
  beforeEach module('tvAuction.services')

  describe 'UserManager', ->
    userManager = undefined

    beforeEach ->
      inject ($injector) ->
        userManager = $injector.get 'UserManager'

    it 'should contain the functions login and check', ->
      expect(userManager.login).not.toBeUndefined()
      expect(userManager.check).not.toBeUndefined()
