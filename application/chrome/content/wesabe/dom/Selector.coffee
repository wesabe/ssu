Parser = require 'util/Parser'
{tryCatch, tryThrow} = require 'util/try'

class Selector
  constructor: ->
    @classNames = []

  @::__defineGetter__ 'className', ->
    @classNames[@classNames.length-1]

  @::__defineSetter__ 'className', (className) ->
    @classNames[@classNames.length-1] = className

  test: (el) ->
    return false if el.nodeType isnt 1
    return false if @id and @id isnt el.id
    return false if @tag and @tag isnt el.tagName

    for className in @classNames
      pattern = new RegExp " #{className} ", 'i'
      return false unless pattern.test " #{el.className} "

    return true

  parse: (sel) ->
    parser = new Parser()
    selector = new @constructor()

    noop = -> null

    id =
      start: ->
        selector.id = ''
        parser.tokens =
          '[a-zA-Z]': id.value

      value: (p) ->
        selector.id += p
        parser.tokens =
          '[-_a-zA-Z0-9]': id.value
          '\\.': klass.start
          EOF: noop

    klass =
      # leading period
      start: ->
        selector.classNames.push('')
        parser.tokens =
          '[a-zA-Z]': klass.value

      # name of class
      value: (p) ->
        selector.className += p
        parser.tokens =
          '[-_a-zA-Z]': klass.value
          '\\.': klass.start
          EOF: noop

    tag =
      # first tag character
      start: (p) ->
        selector.tag = p
        parser.tokens =
          '#': id.start
          '[-_a-zA-Z0-9]': tag.value
          '\\.': klass.start
          EOF: noop

      # subsequent characters
      value: (p) ->
        selector.tag += p

      # *
      all: ->
        tag.start()
        delete selector.tag

    selector.raw = sel
    parser.tokens =
      '\\*': tag.all
      '#': id.start
      '[a-zA-Z]': tag.start
      '\\.': klass.start
      EOF: noop

    tryCatch 'PARSING', =>
      parser.parse(sel)

    return selector


module.exports = Selector
