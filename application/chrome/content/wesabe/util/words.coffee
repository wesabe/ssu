list = null

contains = (word) ->
  list ||= require "util/words/list"
  list.hasOwnProperty(word.toLowerCase())

module.exports = {contains}
