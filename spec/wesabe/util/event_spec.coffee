event = require 'util/event'

class FakeElement
  nodeType: 1
  constructor: (@nodeName='div') ->
  addEventListener: (type, listener, useCapture=false) ->
    # ignore it

class FakeTextNode
  nodeType: 3
  nodeName: '#text'

class FakeCommentNode
  nodeType: 8
  nodeName: '#comment'

class FakeCDataSection
  nodeType: 4
  nodeName: '#cdata-section'

describe 'util/event', ->
  describe 'given a javascript object', ->
    object = null

    beforeEach ->
      object = {}

    it 'does not add a native event handler', ->
      expect(object.addEventListener).toBeUndefined()
      event.add object, 'click', -> alert 'foo'

    it 'allows triggering a bound event', ->
      handler = jasmine.createSpy 'handler'
      event.add object, 'click', handler
      event.trigger object, 'click'
      expect(handler).toHaveBeenCalled()

    it 'allows unbinding a handler', ->
      handler = jasmine.createSpy 'handler'
      event.add object, 'click', handler
      event.remove object, 'click', handler
      event.trigger object, 'click'
      expect(handler).not.toHaveBeenCalled()

    it 'allows binding a one-time handler', ->
      counter = 0
      incr = -> counter++
      event.one object, 'click', incr

      # make sure it's 1 after the first trigger
      event.trigger object, 'click'
      expect(counter).toEqual(1)

      # and that it's still 1 after the second
      event.trigger object, 'click'
      expect(counter).toEqual(1)

    it 'allows triggering multiple events by using multiple words', ->
      clickHandler = jasmine.createSpy 'clickHandler'
      mousedownHandler = jasmine.createSpy 'mousedownHandler'
      event.add object, 'click', clickHandler
      event.add object, 'mousedown', mousedownHandler

      event.trigger object, 'mousedown click'
      expect(clickHandler).toHaveBeenCalled()
      expect(mousedownHandler).toHaveBeenCalled()

    it 'allows binding more than one handler to the same event', ->
      handler1 = jasmine.createSpy 'handler1'
      handler2 = jasmine.createSpy 'handler2'
      event.add object, 'click', handler1
      event.add object, 'click', handler2

      event.trigger object, 'click'
      expect(handler1).toHaveBeenCalled()
      expect(handler2).toHaveBeenCalled()

    afterEach ->
      event.remove object

  describe 'without giving an object at all', ->
    it 'defaults to using the wesabe root object', ->
      handler = jasmine.createSpy 'handler'
      event.add 'click', handler
      event.trigger wesabe, 'click'
      expect(handler).toHaveBeenCalled()

  describe 'given an Element', ->
    element = null

    beforeEach ->
      element = new FakeElement()

    it 'adds a native event handler', ->
      handler = -> alert 'foo'
      spyOn element, 'addEventListener'
      event.add element, 'click', handler
      expect(element.addEventListener).toHaveBeenCalledWith 'click', handler, false

    afterEach ->
      event.remove element

  describe 'given a TextNode', ->
    text = null

    beforeEach ->
      text = new FakeTextNode()

    it 'does not bind events', ->
      handler = jasmine.createSpy 'handler'
      event.add text, 'click', handler
      event.trigger text, 'click', handler
      expect(handler).not.toHaveBeenCalled()

  describe 'given a Comment', ->
    comment = null

    beforeEach ->
      comment = new FakeCommentNode()

    it 'does not bind events', ->
      handler = jasmine.createSpy 'handler'
      event.add comment, 'click', handler
      event.trigger comment, 'click', handler
      expect(handler).not.toHaveBeenCalled()

  describe 'given a CDATA section', ->
    cdata = null

    beforeEach ->
      cdata = new FakeCDataSection()

    it 'does not bind events', ->
      handler = jasmine.createSpy 'handler'
      event.add cdata, 'click', handler
      event.trigger cdata, 'click', handler
      expect(handler).not.toHaveBeenCalled()
