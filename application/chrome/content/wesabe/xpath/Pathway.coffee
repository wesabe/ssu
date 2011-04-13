wesabe.provide('xpath.Pathway')
wesabe.require('util')

#
# Provides methods for generating, manipulating, and searching by XPaths.
#
# ==== Types (shortcuts for use in this file)
# Xpath:: <String, Array[String], wesabe.xpath.Pathway, wesabe.xpath.Pathset>
#
class wesabe.xpath.Pathway
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
    result = document.evaluate(
               wesabe.untaint(@value),
               wesabe.untaint(scope || document),
               null,
               XPathResult.ANY_TYPE,
               null,
               null)

    return result && wesabe.taint(result.iterateNext())

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
               wesabe.untaint(scope || document),
               null,
               XPathResult.ANY_TYPE,
               null,
               null)

    nodes = []
    nodes.push(node) while node = result.iterateNext()
    return wesabe.taint(@constructor.inDocumentOrder(nodes))

  #
  # Applies a binding to a copy of this +Pathway+.
  #
  # ==== Parameters
  # binding<Object>:: Key-value pairs to interpolate into the +Pathway+.
  #
  # ==== Returns
  # wesabe.xpath.Pathway:: A new +Pathway+ bound to +binding+.
  #
  # ==== Example
  #   var pathway = new wesabe.xpath.Pathway('//a[@title=":title"]');
  #   pathway.bind({title: "Wesabe"}).value; // => '//a[@title="Wesabe"]'
  #
  # @public
  #
  bind: (binding) ->
    boundValue = @value

    for own key, value of binding
      boundValue = boundValue.replace(new RegExp(":#{key}", 'g'), wesabe.untaint(value))
      boundValue = wesabe.taint(boundValue) if wesabe.isTainted(value)

    return new wesabe.xpath.Pathway(boundValue)

#
# Applies a binding to an +Xpath+.
#
# ==== Parameters
# xpath<Xpath>:: The thing to bind.
# binding<Object>:: Key-value pairs to interpolate into the xpath.
#
# ==== Returns
# wesabe.xpath.Pathway,wesabe.xpath.Pathset::
#   A +Pathway+-compatible object with bindings applied from +binding+.
#
# ==== Example
#   wesabe.xpath.bind('//a[@title=":title"]', {title: "Wesabe"}).value // => '//a[@title="Wesabe"]'
#
# @public
#
wesabe.xpath.bind = (xpath, binding) ->
  wesabe.xpath.Pathway.from(xpath).bind(binding)

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
wesabe.xpath.Pathway.from = (xpath) ->
  if wesabe.isString(xpath)
    new wesabe.xpath.Pathway(xpath)
  else if wesabe.isArray(xpath)
    new wesabe.xpath.Pathset(xpath)
  else if xpath instanceof wesabe.xpath.Pathway or xpath instanceof wesabe.xpath.Pathset
    xpath
  else
    throw new Error("Could not convert #{wesabe.util.inspect(xpath)} to a wesabe.xpath.Pathway.")

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
wesabe.xpath.Pathway.inDocumentOrder = (elements) ->
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
