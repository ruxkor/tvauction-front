'use strict'

describe 'tvAuction app', ->
  describe 'login page', ->
    beforeEach ->
      browser().navigateTo '../../#/user/login'
      expect(browser().location().url()).toBe('/user/login')


    it 'should display a warning message only when appropriate', ->
      input('user.email').enter('invalid@invalid.com')
      input('user.password').enter('invalid')
      element('#user-login-form :button').click()

      # display now, because the data was wrong
      expect(element('#credentials-invalid').css('display')).not().toBe('none')

      # as soon as the user enters new data, it should not be displayed anymore
      input('user.email').enter('invalid2@invalid.com')
      expect(element('#credentials-invalid').css('display')).toBe('none')


    it 'should redirect to the main page if the login is correct', ->
      input('user.email').enter('test@test.com')
      input('user.password').enter('test')
      element('#user-login-form :button').click()
      expect(browser().location().url()).toBe('/auction')
