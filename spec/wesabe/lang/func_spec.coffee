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
