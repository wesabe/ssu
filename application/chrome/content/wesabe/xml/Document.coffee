type      = require 'lang/type'
event     = require 'util/event'
inspect   = require 'util/inspect'
Colorizer = require 'util/Colorizer'

Parser    = require 'xml/Parser'
Element   = require 'xml/Element'
Attribute = require 'xml/Attribute'
Text      = require 'xml/Text'

class Document
  constructor: (xml, verboten) ->
    @parse xml, verboten if xml?

  @::__defineGetter__ 'root', ->
    @_root ||= new Element()

  @::__defineGetter__ 'documentElement', ->
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
        if type.is node, Text
          @stack.push node
        else if type.is node, Attribute
          @stack[@stack.length-1].setAttribute(node.name, node.value)
        else if type.is node, Element
          node.parsing = !node.selfclosing
          @stack.push node
        else
          throw new Error 'Unexpected node type: ', node

      setName: (name) ->
        for i in [@stack.length-1..0]
          node = @stack[i]
          if type.is node, Element
            node.name = name
            return

        throw new Error 'Unable to find an element to set name to ', name

      pop: (closeTag) ->
        # make sure tags are matched or just figure it out
        popped = []

        while @stack.length
          node = @stack.pop()
          if node.parsing and type.is node, Element
            # found the matching opening tag, push all children into it
            if node.name is closeTag.name
              for child in popped
                node.appendChild child

              delete node.parsing
              @stack.push node
              return
          else if node.parsing
            logger.error "NODE IS ", node

          # push a dangling text node onto the adjacent element if that element is unclosed
          if node.parsing and type.is(popped[0], Text) and type.is(node, Element)
            node.appendChild(popped.shift())
          popped.unshift(node)

        throw new Error "Unexpected closing tag #{inspect closeTag}"

    event.add parser, 'start-open-tag', (event, tag) =>
      work.push tag.toElement()

    event.add parser, 'end-open-tag', (event, tag) =>
      work.setName tag.name

    event.add parser, 'close-tag', (event, tag) =>
      work.pop tag

    event.add parser, 'text', (event, text) =>
      work.push text

    event.add parser, 'attribute', (event, attr) =>
      work.push attr

    # parse the xml, executing all the callbacks above
    parser.parse xml, verboten

    @root.appendChild work.stack[0]

  contentForInspect: ->
    @documentElement


module.exports = Document
