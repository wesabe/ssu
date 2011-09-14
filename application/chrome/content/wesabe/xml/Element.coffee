type       = require 'lang/type'
inspect    = require 'util/inspect'
{sanitize} = require 'util/privacy'
Colorizer  = require 'util/Colorizer'

NodeList  = require 'xml/NodeList'
Attribute = require 'xml/Attribute'

class Element
  constructor: (name, selfclosing) ->
    @name = name
    @selfclosing = true if selfclosing
    @__children__ = []
    @__attributes__ = {}

  #
  # DOM-ish methods
  #

  # attribute stuff

  @::__defineGetter__ 'id', ->
    @__attributes__.id || null

  @::__defineGetter__ 'className', ->
    @__attributes__.class || ''

  @::__defineGetter__ 'childNodes', ->
    new NodeList @__children__

  @::__defineGetter__ 'nodeName', ->
    @name

  @::__defineGetter__ 'tagName', ->
    @name

  getAttribute: (name) ->
    @__attributes__[name]

  setAttribute: (name, value) ->
    @__attributes__[name] = value

  @::__defineGetter__ 'attributes', ->
    for name, value of @__attributes__
      new Attribute name, value

  # child stuff

  appendChild: (node) ->
    @__children__.push(node)
    node.parentNode = this

  @::__defineGetter__ 'firstChild', ->
    @__children__[0]

  @::__defineGetter__ 'lastChild', ->
    @__children__[@__children__.length-1]

  @::__defineGetter__ 'text', ->
    (n.text for n in @__children__).join('')

  insertBefore: (node, adjacentNode) ->
    for child, i in @__children__
      if child == adjacentNode
        @__children__.splice(i, 0, node)
        node.parentNode = this
        return node

    throw new Error("Element#insertBefore: Could not find adjacentNode #{inspect(adjacentNode)}")

  insertAfter: (node, adjacentNode) ->
    for child, i in @__children__
      if child == adjacentNode
        @__children__.splice(i+1, 0, node)
        node.parentNode = this
        return node

    throw new Error("Element#insertAfter: Could not find adjacentNode #{inspect(adjacentNode)}")

  # finders

  search: (callback, one) ->
    found = []
    descendants = [this]

    while descendants.length
      child = descendants.shift()
      if callback(child)
        return child if one
        found.push(child)

      if type.isArray(child.__children__)
        descendants = descendants.concat(child.__children__)

    return found unless one

  searchOne: (callback) ->
    @search(callback, true)

  searchMultiple: (callback) ->
    @search(callback, false)

  getElementById: (id) ->
    @searchOne (node) ->
      node.id == id

  getElementsByTagName: (name) ->
    if name == '*'
      @searchMultiple (node) ->
        node.nodeType == 1
    else
      @searchMultiple (node) ->
        node.nodeType == 1 && node.name.toLowerCase() == name.toLowerCase()

  # misc stuff

  nodeType: 1

   #
   # jQuery-ish methods
   #

  find: (sel) ->
    throw new Error("Element#find is unimplemented")

  #
  # debugging methods
  #

  inspect: (refs, color, tainted) ->
    # handle NodeJS-style inspect
    if typeof refs is 'number'
      refs = null

    s = new Colorizer()
    s.disabled = !color
    s.reset()
     .bold("{#{if @selfclosing then 'empty' else ''}elem ")
     .yellow('<')
     .white()
     .bold()
     .print(@name)

    # print out the attributes
    for attr in @attributes
      value = attr.nodeValue.toString()
      value = sanitize(value) if tainted

      s.print(' ')
       .reset()
       .underlined(attr.nodeName)
       .yellow('="')
       .green(value)
       .yellow('"')

    s.yellow('>')

    # print the children
    hasElementChildren = false
    for child in @__children__
      hasElementChildren = hasElementChildren or type.is(child, Element)
      s.print(' ', inspect(child, refs, color, tainted))

    # only show the closing tag if there are child elements (not text)
    if hasElementChildren
      s.print(' ')
       .yellow('</')
       .white()
       .bold()
       .print(@name)
       .yellow('>')

    return s.bold('}').toString()

module.exports = Element
