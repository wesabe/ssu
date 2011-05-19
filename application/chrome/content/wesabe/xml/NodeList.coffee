wesabe.provide('xml.NodeList')

class wesabe.xml.NodeList
  constructor: (nodes) ->
    @nodes = nodes || []

  this::__defineGetter__ 'length', ->
    @nodes.length

  item: (index) ->
    @nodes[index]

  push: (node) ->
    @nodes.push(node)
