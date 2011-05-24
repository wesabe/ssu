event = wesabe.require 'util.event'

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

describe 'wesabe.util.event', ->
  describe 'given a javascript object', ->
    object = null

    beforeEach ->
      object = {}

    it 'does not add a native event handler', ->
      expect(object.addEventListener).toBeUndefined()
      wesabe.bind(object, 'click', -> alert('foo'))

    it 'allows triggering a bound event', ->
      handler = jasmine.createSpy('handler')
      wesabe.bind(object, 'click', handler)
      wesabe.trigger(object, 'click')
      expect(handler).toHaveBeenCalled()

    it 'allows unbinding a handler', ->
      handler = jasmine.createSpy('handler')
      wesabe.bind(object, 'click', handler)
      wesabe.unbind(object, 'click', handler)
      wesabe.trigger(object, 'click')
      expect(handler).not.toHaveBeenCalled()

    it 'allows binding a one-time handler', ->
      counter = 0
      incr = -> counter++
      wesabe.one(object, 'click', incr)

      # make sure it's 1 after the first trigger
      wesabe.trigger(object, 'click')
      expect(counter).toEqual(1)

      # and that it's still 1 after the second
      wesabe.trigger(object, 'click')
      expect(counter).toEqual(1)

    it 'allows triggering multiple events by using multiple words', ->
      clickHandler = jasmine.createSpy('clickHandler')
      mousedownHandler = jasmine.createSpy('mousedownHandler')
      wesabe.bind(object, 'click', clickHandler)
      wesabe.bind(object, 'mousedown', mousedownHandler)

      wesabe.trigger(object, 'mousedown click')
      expect(clickHandler).toHaveBeenCalled()
      expect(mousedownHandler).toHaveBeenCalled()

    it 'allows binding more than one handler to the same event', ->
      handler1 = jasmine.createSpy('handler1')
      handler2 = jasmine.createSpy('handler2')
      wesabe.bind(object, 'click', handler1)
      wesabe.bind(object, 'click', handler2)

      wesabe.trigger(object, 'click')
      expect(handler1).toHaveBeenCalled()
      expect(handler2).toHaveBeenCalled()

    afterEach ->
      wesabe.unbind(object)

  describe 'without giving an object at all', ->
    it 'defaults to using the wesabe root object', ->
      handler = jasmine.createSpy('handler')
      wesabe.bind('click', handler)
      wesabe.trigger(wesabe, 'click')
      expect(handler).toHaveBeenCalled()

  describe 'given an Element', ->
    element = null

    beforeEach ->
      element = new FakeElement()

    it 'adds a native event handler', ->
      handler = -> alert('foo')
      spyOn(element, 'addEventListener')
      wesabe.bind(element, 'click', handler)
      expect(element.addEventListener).toHaveBeenCalledWith('click', handler, false)

    afterEach ->
      wesabe.unbind(element)

  describe 'given a TextNode', ->
    text = null

    beforeEach ->
      text = new FakeTextNode()

    it 'does not bind events', ->
      handler = jasmine.createSpy('handler')
      wesabe.bind(text, 'click', handler)
      wesabe.trigger(text, 'click', handler)
      expect(handler).not.toHaveBeenCalled()

  describe 'given a Comment', ->
    comment = null

    beforeEach ->
      comment = new FakeCommentNode()

    it 'does not bind events', ->
      handler = jasmine.createSpy('handler')
      wesabe.bind(comment, 'click', handler)
      wesabe.trigger(comment, 'click', handler)
      expect(handler).not.toHaveBeenCalled()

  describe 'given a CDATA section', ->
    cdata = null

    beforeEach ->
      cdata = new FakeCDataSection()

    it 'does not bind events', ->
      handler = jasmine.createSpy('handler')
      wesabe.bind(cdata, 'click', handler)
      wesabe.trigger(cdata, 'click', handler)
      expect(handler).not.toHaveBeenCalled()
