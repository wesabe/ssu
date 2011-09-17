type    = require 'lang/type'
array   = require 'lang/array'
inspect = require 'util/inspect'

#
# Provides methods for generating, manipulating, and searching by XPaths.
#
# ==== Types (shortcuts for use in this file)
# Xpath:: <String, Array[String], Pathway, Pathset>
#
class Pathway
  constructor: (@value) ->

  #
  # Returns the first matching DOM element in the given document.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # scope<HTMLElement>:: The element to scope the search to.
  #
  # ==== Returns
  # tainted(HTMLElement):: The first matching DOM element.
  #
  # @public
  #
  first: (document, scope) ->
    try
      result = document.evaluate(
                 wesabe.untaint(@value),
                 wesabe.untaint(scope or document),
                 null,
                 XPathResult.ANY_TYPE,
                 null,
                 null)
    catch err
      if err instanceof XPathException
        throw new Error "#{err.message} (XPath = #{@value})"

      throw err

    wesabe.taint result?.iterateNext()

  #
  # Returns all matching DOM elements in the given document.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # scope<HTMLElement, null>:: An optional scope to search within.
  #
  # ==== Returns
  # tainted(Array[HTMLElement]):: All matching DOM elements.
  #
  # @public
  #
  select: (document, scope) ->
    result = document.evaluate(
               wesabe.untaint(@value),
               wesabe.untaint(scope or document),
               null,
               XPathResult.ANY_TYPE,
               null,
               null)

    nodes = []
    nodes.push(node) while node = result.iterateNext()
    return wesabe.taint @constructor.inDocumentOrder(nodes)

  #
  # Applies a binding to a copy of this +Pathway+.
  #
  # ==== Parameters
  # binding<Object>:: Key-value pairs to interpolate into the +Pathway+.
  #
  # ==== Returns
  # Pathway:: A new +Pathway+ bound to +binding+.
  #
  # ==== Example
  #   var pathway = new Pathway('//a[@title=":title"]');
  #   pathway.bind({title: "Wesabe"}).value; // => '//a[@title="Wesabe"]'
  #
  # @public
  #
  bind: (binding) ->
    boundValue = @value

    for own key, value of binding
      boundValue = boundValue.replace(new RegExp(":#{key}", 'g'), wesabe.untaint(value))
      boundValue = wesabe.taint(boundValue) if wesabe.isTainted(value)

    return new Pathway boundValue

  #
  # Returns a +Pathway+-compatible object if one can be generated from +xpath+.
  #
  # ==== Parameters
  # xpath<Xpath>::
  #   Something that can be used as a +Pathway+.
  #
  # ==== Returns
  # wesabe.xpath.Pathway,wesabe.xpath.Pathset::
  #   A +Pathway+ or +Pathset+ converted from the argument.
  #
  # @public
  #
  @from: (xpath) ->
    if type.isString xpath
      new Pathway(xpath)
    else if type.isArray xpath
      new Pathset(xpath)
    else if type.is(xpath, Pathway) or type.is(xpath, Pathset)
      xpath
    else
      throw new Error "Could not convert #{inspect xpath} to a wesabe.xpath.Pathway."

  #
  # Returns the given array with elements sorted by document order.
  #
  # ==== Parameters
  # elements<Array[~compareDocumentPosition]>:: List of elements to sort.
  #
  # ==== Returns
  # Array[~compareDocumentPosition]:: List of sorted elements.
  #
  # @public
  #
  @inDocumentOrder: (elements) ->
    elements.sort (a, b) ->
      a = wesabe.untaint(a)
      b = wesabe.untaint(b)

      switch a.compareDocumentPosition(b)
        when Node.DOCUMENT_POSITION_PRECEDING, Node.DOCUMENT_POSITION_CONTAINS
          1
        when Node.DOCUMENT_POSITION_FOLLOWING, Node.DOCUMENT_POSITION_IS_CONTAINED
          -1
        else
          0

  #
  # Applies a binding to an +Xpath+.
  #
  # ==== Parameters
  # xpath<Xpath>:: The thing to bind.
  # binding<Object>:: Key-value pairs to interpolate into the xpath.
  #
  # ==== Returns
  # Pathway,Pathset::
  #   A +Pathway+-compatible object with bindings applied from +binding+.
  #
  # ==== Example
  #   Pathway.bind('//a[@title=":title"]', {title: "Wesabe"}).value // => '//a[@title="Wesabe"]'
  #
  # @public
  #
  @bind: (xpath, binding) ->
    @from(xpath).bind(binding)

#
# Provides methods for dealing with sets of +Pathways+.
#
class Pathset
  constructor: (args...) ->
    args = args[0] if args.length == 1 && type.isArray(args[0])
    @xpaths = []

    for arg in args
      @xpaths.push(Pathway.from(arg))

  #
  # Returns the first matching DOM element in the given document.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # scope<HTMLElement>:: The element to scope the search to.
  #
  # ==== Returns
  # tainted(HTMLElement):: The first matching DOM element.
  #
  # @public
  #
  first: (document, scope) ->
    for xpath in @xpaths
      if element = xpath.first(document, scope)
        return element

  #
  # Returns all matching DOM elements from the all matching Pathways in the set.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # scope<HTMLElement, null>:: An optional scope to search within.
  #
  # ==== Returns
  # tainted(Array[HTMLElement]):: All matching DOM elements.
  #
  # @public
  #
  select: (document, scope) ->
    elements = []

    for xpath in @xpaths
      elements = elements.concat(xpath.select(document, scope))

    Pathway.inDocumentOrder(array.uniq(elements))

  #
  # Applies a binding to a copy of this +Pathset+.
  #
  # ==== Parameters
  # binding<Object>:: Key-value pairs to interpolate into the +Pathset+.
  #
  # ==== Returns
  # Pathset:: A new +Pathset+ bound to +binding+.
  #
  # ==== Example
  #   var pathset = new Pathset(
  #     '//a[@title=":title"]', '//a[contains(string(.), ":title")]);
  #   pathway.bind({title: "Wesabe"});
  #   // results in #<Pathset value=[
  #                   '//a[@title="Wesabe"]', '//a[contains(string(.), "Wesabe")]>
  #
  # @public
  #
  bind: (binding) ->
    new @constructor(xpath.bind(binding) for xpath in @xpaths)


module.exports = {Pathset, Pathway}
