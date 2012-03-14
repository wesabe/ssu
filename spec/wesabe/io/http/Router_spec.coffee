Router = require 'io/http/Router'

describe 'Router', ->
  router = null
  callback = null

  beforeEach ->
    router = new Router

  describe 'without any routes', ->
    beforeEach ->
      expect(router.routes).toEqual([])

    it 'does not match anything', ->
      expect(router.match(method: 'GET', url: '/')).toBeFalsy()

  describe 'with one route', ->
    matching = method: 'GET', url: '/'
    nonmatchingPath = method: 'GET', url: '/login'
    nonmatchingMethod = method: 'POST', url: '/'

    beforeEach ->
      callback = jasmine.createSpy('GET / callback')
      router.map 'GET', '/', callback

    it 'matches requests with identical method and url', ->
      expect(router.match(matching)).toBeTruthy()

    it 'does not match requests with the same method but not url', ->
      expect(router.match(nonmatchingPath)).toBeFalsy()

    it 'does not match requests with the same url but not method', ->
      expect(router.match(nonmatchingMethod)).toBeFalsy()

    it 'calls the callback when routing a matching request', ->
      router.route(matching)
      expect(callback).toHaveBeenCalledWith({})

    it 'does not call the callback when routing a non-matching request', ->
      expect(router.route(nonmatchingPath)).toBeFalsy()
      expect(router.route(nonmatchingMethod)).toBeFalsy()
      expect(callback).not.toHaveBeenCalled()

  describe 'with a route including placeholders', ->
    matching = method: 'GET', url: '/files/list.txt'
    nonmatching = method: 'GET', url: '/files/list'

    beforeEach ->
      callback = jasmine.createSpy('route callback')
      router.map 'GET', '/:part1/:part2.:part3', callback

    it 'matches requests with the right structure', ->
      expect(router.match(matching)).toBeTruthy()

    it 'does not match requests with the wrong structure', ->
      expect(router.match(nonmatching)).toBeFalsy()

    it 'calls the callback with the path parts named for placeholders', ->
      expect(router.route(matching)).toBeTruthy()
      expect(callback).toHaveBeenCalledWith(part1: 'files', part2: 'list', part3: 'txt')
