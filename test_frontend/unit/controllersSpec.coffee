'use strict'

describe 'TvAuction controllers', ->

  beforeEach ->
    this.addMatchers
      toEqualData: (expected) ->
        angular.equals this.actual, expected

  beforeEach module 'tvAuction.services'

  describe 'UserLoginCtrl', ->

    scope = ctrl = httpBackend = location = undefined

    beforeEach inject ($injector, $location, $rootScope, $controller) ->
      a = arguments
      httpBackend = $injector.get '$httpBackend'
      location = $location
      scope = $rootScope.$new()
      httpBackend.expectGET('user/check').respond(200,"0")
      ctrl = $controller UserLoginCtrl, {$scope: scope}
    
    it 'it should set credentialsInvalid if the login succeeded', ->
      httpBackend.expectPOST('user/login').respond(200,"0")
      scope.user =
        email: 'test@test.com'
        password: 'test'

      scope.login()
      httpBackend.flush()
      expect(scope.credentialsInvalid).toBe(true)

    it 'it should set credentialsInvalid if the login failed', ->
      httpBackend.expectPOST('user/login').respond(200,"2")
      scope.user =
        email: 'test@test.com'
        password: 'test'

      scope.login()
      httpBackend.flush()
      expect(scope.credentialsInvalid).not.toBe(true)
