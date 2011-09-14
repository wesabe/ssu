type      = require 'lang/type'
inspect   = require 'util/inspect'
Colorizer = require 'util/Colorizer'

Parser    = require 'xml/Parser'
Element   = require 'xml/Element'
Attribute = require 'xml/Attribute'
Text      = require 'xml/Text'

wesabe.require 'util.event'
wesabe.require 'util.Colorizer'

class Document
  constructor: (xml, verboten) ->
    @parse xml, verboten if xml?

  this::__defineGetter__ 'root', ->
    this._root ||= new Element()

  this::__defineGetter__ 'documentElement', ->
    @root.firstChild

  find: (selector) ->
    @documentElement.find(selector)

  getElementById: (id) ->
    return null unless @documentElement

    @documentElement.getElementById(id)

  getElementsByTagName: (name) ->
    return [] unless @documentElement

    @documentElement.getElementsByTagName(name)

  parse: (xml, verboten) ->
    parser = new Parser()

    work =
      stack: []

      push: (node) ->
        if type.is(node, Text)
          @stack.push(node)
        else if type.is(node, Attribute)
          @stack[@stack.length-1].setAttribute(node.name, node.value)
        else if type.is(node, Element)
          node.parsing = !node.selfclosing
          @stack.push(node)
        else
          throw new Error('Unexpected node type: ', node)

      setName: (name) ->
        for i in [@stack.length-1..0]
          node = @stack[i]
          if type.is(node, Element)
            node.name = name
            return

        throw new Error('Unable to find an element to set name to ', name)

      pop: (closeTag) ->
        # make sure tags are matched or just figure it out
        popped = []

        while @stack.length
          node = @stack.pop()
          if type.is(node, Element) && node.parsing
            # found the matching opening tag, push all children into it
            if node.name == closeTag.name
              for child in popped
                node.appendChild(child)

              delete node.parsing
              @stack.push(node)
              return
          else if node.parsing
            wesabe.error("NODE IS ", node)

          # push a dangling text node onto the adjacent element if that element is unclosed
          if type.is(popped[0], Text) && type.is(node, Element) && node.parsing
            node.appendChild(popped.shift())
          popped.unshift(node)

        throw new Error("Unexpected closing tag #{inspect(closeTag)}")

    wesabe.bind parser, 'start-open-tag', (event, tag) =>
      work.push(tag.toElement())

    wesabe.bind parser, 'end-open-tag', (event, tag) =>
      work.setName(tag.name)

    wesabe.bind parser, 'close-tag', (event, tag) =>
      work.pop(tag)

    wesabe.bind parser, 'text', (event, text) =>
      work.push(text)

    wesabe.bind parser, 'attribute', (event, attr) =>
      work.push(attr)

    # parse the xml, executing all the callbacks above
    parser.parse(xml, verboten)

    @root.appendChild(work.stack[0])

  inspect: (refs, color, tainted) ->
    # handle NodeJS-style inspect
    if typeof refs is 'number'
      refs = null

    s = new Colorizer()
    s.disabled = !color
    s.yellow('#<')
     .bold(@constructor?.__module__?.name || 'Object')
    s.print(' ', @documentElement.inspect(refs, color, tainted)) if @documentElement
    return s.yellow('>').toString()

module.exports = Document
