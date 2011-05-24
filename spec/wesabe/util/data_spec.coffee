data = wesabe.require 'util.data'

describe 'wesabe.util.data', ->
  describe 'setting and getting data by name', ->
    it 'allows storing and retrieving data for an object', ->
      object = {}
      data(object, 'type', 'FooBar')
      expect(data(object, 'type')).toEqual('FooBar')

    it 'allows overwriting data for an object', ->
      object = {}
      data(object, 'type', 'FooBar')
      data(object, 'type', 'Widget')
      expect(data(object, 'type')).toEqual('Widget')

    it 'allows reading the expando for an object', ->
      object = {}
      expect(data(object)).toBeDefined()
      expect(data(object)).toEqual(data(object))

    it 'allows removing data by name for an object', ->
      object = {}
      data(object, 'type', 'FooBar')
      data.remove(object, 'type')
      expect(data(object, 'type')).toBeUndefined()

    it 'allows removing all data for an object', ->
      object = {}
      data(object, 'type', 'FooBar')
      data(object, 'name', 'object')
      data.remove(object)
      expect(data(object, 'type')).toBeUndefined()
      expect(data(object, 'name')).toBeUndefined()
