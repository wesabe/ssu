wesabe.require("io.*")

wesabe.provide "util.words",
  list: null

  exist: (word) ->
    @ensureLoaded()
    @list.hasOwnProperty(word.toLowerCase())

  ensureLoaded: ->
    wesabe.require("util.words.list")

  loaded: ->
    !!@list
