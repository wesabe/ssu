extend = wesabe.require 'lang.extend'

describe 'wesabe.lang.extend', ->
  it 'copies keys from the source to the target', ->
    source = {a: 1, b: 2}
    target = {}
    extend(target, source)
    expect(target.a).toEqual(1)
    expect(target.b).toEqual(2)

  it 'overrides values in target by default', ->
    source = {a: 1, b: 2}
    target = {a: 3}
    extend(target, source)
    expect(target.a).toEqual(1)

  it 'allows preventing overriding values in target', ->
    source = {a: 1, b: 2}
    target = {a: 3}
    extend(target, source, override: false)
    expect(target.a).toEqual(3)

  it 'allows merging subtrees if possible', ->
    source = {a: 1, b: {c: 3}}
    target = {a: 2, b: {d: 5}}
    extend(target, source, merge: true)
    expect(target.a).toEqual(1)
    expect(target.b).toEqual(c: 3, d: 5)

  it 'copies getters', ->
    source = {}
    source.__defineGetter__ 'test', -> 4
    expect(extend({}, source).test).toEqual(4)

  it 'copies setters', ->
    source = {}
    target = {}
    source.__defineSetter__ 'test', (@v) ->
    extend(target, source)
    target.test = 4
    expect(target.v).toEqual(4)

  it 'does not copy values that do not belong directly to it', ->
    sklass = ->
    sklass.prototype.a = 1
    source = new sklass()
    expect(source.a).toEqual(1)
    expect(extend({}, source).a).not.toEqual(1)
