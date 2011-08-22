func = wesabe.require 'lang.func'

describe 'wesabe.lang.func', ->
  describe '.callWithScope function', ->
    it 'allows calling a function with a specific context', ->
      GLOBAL.context = {}
      func.callWithScope(
        (-> expect(this).toBe(GLOBAL.context)),
        GLOBAL.context,
        {})

    it 'allows calling a function with a specific scope', ->
      func.callWithScope(
        (->
          expect(abc).toBe("def")
          expect(notInScope?).toBe(false)),
        this,
        abc: 'def')

    it 'allows calling a function with arguments', ->
      func.callWithScope(
        ((a, b) ->
          expect(a).toBe(1)
          expect(b).toBe(2)),
        this,
        {},
        [1, 2])

    it 'substitutes "undefined" for arguments that are not given', ->
      func.callWithScope(
        ((url, type) ->
          expect(url).toBe('google.com')
          expect(type).toBe(undefined)),
        this,
        {type: 'GET'},
        ['google.com'])

    it 'works with CoffeeScript function binding', ->
      func.callWithScope(
        (->
          expect((-> this)()).not.toBe(this)
          expect((=> this)()).toBe(this)),
        this)

    it 'works with CoffeeScript classes', ->
      func.callWithScope(
        (->
          class Animal

          class Dog extends Animal
            speak: -> 'woof'

          expect(new Dog().speak()).toBe('woof')),
        this)

  describe '.wrap function', ->
    it 'wraps a function by providing a new context', ->
      obj =
        bar: 4

        foo: ->
          @bar

      obj2 = bar: 1

      # calling foo() with obj as the context returns obj's bar
      expect(obj.foo()).toBe(4)

      # calling foo() with obj2 as the context returns obj2's bar
      expect(func.wrap(obj.foo, obj2)()).toBe(1)
