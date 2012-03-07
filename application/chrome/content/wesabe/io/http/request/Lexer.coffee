class Lexer
  tokenize: (data) ->
    @data   = data
    @tokens = []
    @line   = 0

    i = 0
    while @chunk = data.slice i
      i += @methodToken() or
           @headerToken() or
           @pathToken() or
           @whitespaceToken() or
           @httpToken() or
           @numberToken() or
           @dataToken() or
           @unexpectedInput()

    @token 'EOF'

    return @tokens

  methodToken: ->
    return 0 unless match = METHOD.exec @chunk
    method = match[0]

    @token 'METHOD', method
    return method.length

  headerToken: ->
    return 0 unless match = HEADER.exec @chunk
    [input, name, value] = match

    @token 'HEADER', {name, value}
    return input.length

  pathToken: ->
    return 0 unless match = PATH.exec @chunk
    path = match[0]

    @token 'PATH', path
    return path.length

  whitespaceToken: ->
    return 0 unless (match = WHITESPACE.exec @chunk) or
                    (nline = NEWLINE.exec @chunk)

    if nline
      @line++
      @token 'NEWLINE'
      return nline[0].length

    @token 'SP'
    return match[0].length

  httpToken: ->
    return 0 unless match = HTTP_VER_PRE.exec @chunk
    @token 'HTTP'
    return match[0].length

  numberToken: ->
    return 0 unless match = NUMBER.exec @chunk
    numstr = match[0]

    @token 'NUMBER', parseFloat(numstr)
    return numstr.length

  dataToken: ->
    @tokens.body = @chunk

    newlineToken = null
    while @tokens[@tokens.length-1]?[0] is 'NEWLINE'
      newlineToken = @tokens.pop()
    @tokens.push newlineToken if newlineToken

    return @chunk.length

  token: (tag, value) ->
    @tokens.push [tag, value, @line]

  unexpectedInput: ->
    throw new Error("Unexpected input at line #{@line+1}: #{@data.split(/\r?\n/)[@line]}")

METHOD = /^(GET|HEAD|POST|PUT|DELETE|OPTIONS)\b/
PATH   = /^\/\S*/
HEADER = /^([a-zA-Z][-a-zA-Z]*): ([^\r\n]*)/

WHITESPACE = /^[^\n\S]+/
NEWLINE    = /^\r?\n/

HTTP_VER_PRE = /^HTTP\//
NUMBER = /^[0-9](?:\.[0-9])?/

exports.Lexer = Lexer