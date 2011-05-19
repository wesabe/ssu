wesabe.provide('xml.Element')
wesabe.require('dom.Selector')

class wesabe.xml.Element
  constructor: (name, selfclosing) ->
    @name = name
    @selfclosing = true if selfclosing
    @__children__ = []
    @__attributes__ = {}

  #
  # DOM-ish methods
  #

  # attribute stuff

  this::__defineGetter__ 'id', ->
    @__attributes__.id || null

  this::__defineGetter__ 'className', ->
    @__attributes__.class || ''

  this::__defineGetter__ 'childNodes', ->
    new wesabe.xml.NodeList(@__children__)

  this::__defineGetter__ 'tagName', ->
    @name

  setAttribute: (name, value) ->
    @__attributes__[name] = value

  this::__defineGetter__ 'attributes', ->
    for name, value in @__attributes__
      new wesabe.xml.Attribute(name, value)

  # child stuff

  appendChild: (node) ->
    @__children__.push(node)
    node.parentNode = this

  this::__defineGetter__ 'firstChild', ->
    @__children__[0]

  this::__defineGetter__ 'lastChild', ->
    @__children__[@__children__.length-1]

  this::__defineGetter__ 'text', ->
    (n.text for n in @__children__).join('')

  insertBefore: (node, adjacentNode) ->
    for child, i in @__children__
      if child == adjacentNode
        @__children__.splice(i, 0, node)
        node.parentNode = this
        return node

    throw new Error("Element#insertBefore: Could not find adjacentNode #{wesabe.util.inspect(adjacentNode)}")

  insertAfter: (node, adjacentNode) ->
    for child, i in @__children__
      if child == adjacentNode
        @__children__.splice(i+1, 0, node)
        node.parentNode = this
        return node

    throw new Error("Element#insertAfter: Could not find adjacentNode #{wesabe.util.inspect(adjacentNode)}")

  # finders

  search: (callback, one) ->
    found = []
    descendants = [this]

    while descendants.length
      child = descendants.shift()
      if callback(child)
        return child if one
        found.push(child)

      if wesabe.isArray(child.__children__)
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
    s = new wesabe.util.Colorizer()
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
      value = wesabe.util.privacy.sanitize(value) if tainted

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
      hasElementChildren = hasElementChildren || wesabe.is(child, wesabe.xml.Element)
      s.print(' ', wesabe.util._inspect(child, refs, color, tainted))

    # only show the closing tag if there are child elements (not text)
    if hasElementChildren
      s.print(' ')
       .yellow('</')
       .white()
       .bold()
       .print(this.name)
       .yellow('>')

    return s.bold('}').toString()
