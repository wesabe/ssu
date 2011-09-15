list = null

exist = (word) ->
  list ||= require "util/words/list"
  list.hasOwnProperty(word.toLowerCase())

module.exports = {exist}
