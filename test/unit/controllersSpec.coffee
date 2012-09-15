'use strict'

describe 'TvAuction controllers', ->

  beforeEach ->
    this.addMatchers
      toEqualData: (expected) ->
        angular.equals this.actual, expected

  beforeEach module('tvAuction.services')

  describe 'UserLoginCtrl', ->

    scope = ctrl = $httpBackend = undefined

    beforeEach inject(($injector, $rootScope, $controller) ->
      a = arguments
      $httpBackend = $injector.get '$httpBackend'
      scope = $rootScope.$new()
      ctrl = $controller UserLoginCtrl, {$scope: scope}
    )

    it 'it should set credentialsInvalid if the login failed', ->
      $httpBackend.expectPOST('user/login').respond(200,"0")
      scope.user =
        email: 'test@test.com'
        password: 'test'

      scope.login()
      $httpBackend.flush()
      expect(scope.credentialsInvalid).toBe(true)

    it 'it should set credentialsInvalid if the login failed', ->
      $httpBackend.expectPOST('user/login').respond(200,"2")
      scope.user =
        email: 'test@test.com'
        password: 'test'

      scope.login()
      $httpBackend.flush()
      expect(scope.credentialsInvalid).not.toBe(true)
