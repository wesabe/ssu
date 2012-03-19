Job = require 'download/Job'

# small utility to memoize a function
m = (generator) ->
  result = null
  -> result ||= generator()

describe 'Job', ->
  job = id = fid = creds = options = null

  beforeEach ->
    job = m -> new Job id(), fid(), creds(), options()
    id = m -> null
    fid = m -> 'com.example.bank'
    creds = m -> username: 'myname123', password: 'smurf32'
    options = m -> {}

  describe 'defaults', ->
    it 'has status=202', ->
      expect(job().status).toEqual(202)

    it 'is not done', ->
      expect(job().done).toBeFalsy()

    it 'is at version=0', ->
      expect(job().version).toEqual(0)

    it 'has a single goal: "statements"', ->
      expect(job().options.goals).toEqual(['statements'])

    it 'does not set the "since" option', ->
      expect(job().since?).toBeFalsy()

    it 'generates a UUID as its id', ->
      expect(job().id).toMatch(/[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}/)

  describe '#done', ->
    it 'is true when status is not 202', ->
      job().status = 200
      expect(job().done).toBeTruthy()

  describe 'given a specific id', ->
    beforeEach ->
      id = m -> '1D99213B-BD5E-0001-FFFF-1FFF1FFF1FFF'

    it 'uses that id instead of generating its own', ->
      expect(job().id).toEqual(id())
