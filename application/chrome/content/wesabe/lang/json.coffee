wesabe.provide 'lang.json',
  parse: (string) ->
    JSON.parse(string)

  render: (object) ->
    JSON.stringify(object)
