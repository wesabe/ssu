{Lexer} = require 'io/http/request/Lexer'
JisonParser = (require 'io/http/request/Grammar').parser

class Parser
  @parse: (data) ->
    new Parser().parse(data)

  parse: (data) ->
    @tokens = new Lexer().tokenize(data)

    JisonParser.lexer =
      lex: ->
        [tag, @yytext, @yylineno] = @tokens[@pos++] or ['']
        tag
      setInput: (@tokens) ->
        @pos = 0
      upcomingInput: ->
        ''

    result = JisonParser.parse @tokens

    if result.method not in ['GET', 'HEAD'] and 'Content-Length' of result.headers
      contentLength = parseInt(result.headers['Content-Length'], 10)
      result.body = @tokens.body.slice(0, contentLength)
    else if @tokens.body
      throw new Error "Received entity body for #{result.method} request: #{@tokens.body}"

    return result

module.exports = Parser
