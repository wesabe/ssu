module.exports =
  parse: (string) ->
    JSON.parse(string)

  render: (object) ->
    JSON.stringify(object)
