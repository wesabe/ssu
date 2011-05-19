wesabe.provide('xpath.Pathset')
wesabe.require('util')
wesabe.require('xpath.Pathway')

#
# Provides methods for dealing with sets of +Pathways+.
#
class wesabe.xpath.Pathset
  constructor: (args...) ->
    args = args[0] if args.length == 1 && wesabe.isArray(args[0])
    @xpaths = []

    for arg in args
      @xpaths.push(wesabe.xpath.Pathway.from(arg))

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

    wesabe.xpath.Pathway.inDocumentOrder(wesabe.lang.array.uniq(elements))

  #
  # Applies a binding to a copy of this +Pathset+.
  #
  # ==== Parameters
  # binding<Object>:: Key-value pairs to interpolate into the +Pathset+.
  #
  # ==== Returns
  # wesabe.xpath.Pathset:: A new +Pathset+ bound to +binding+.
  #
  # ==== Example
  #   var pathset = new wesabe.xpath.Pathset(
  #     '//a[@title=":title"]', '//a[contains(string(.), ":title")]);
  #   pathway.bind({title: "Wesabe"});
  #   // results in #<wesabe.xpath.Pathset value=[
  #                   '//a[@title="Wesabe"]', '//a[contains(string(.), "Wesabe")]>
  #
  # @public
  #
  bind: (binding) ->
    new @constructor(xpath.bind(binding) for xpath in @xpaths)
