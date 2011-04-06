wesabe.provide 'lang.string',
  trim: (string) ->
    string.replace(/^\s+|\s+$/g, '')

  substring: (string, start, end = string.length) ->
    start += string.length if start < 0
    end += string.length if end < 0

    return string.substring(start, end)
