wesabe.provide('util.Colorizer')
extend = wesabe.lang.extend

#
# Provides an easy way to generate ANSI color strings for the shell.
# Example:
#
#   var s = new wesabe.util.Colorizer();
#   s.red();
#   s.print("this is red.");
#   s.underlined();
#   s.print("and this is red and underlined.");
#   s.reset();
#   dump(s.toString());
#
class wesabe.util.Colorizer
  @COLORS =
    black: '30'
    red: '31'
    green: '32'
    yellow: '33'
    blue: '34'
    magenta: '35'
    cyan: '36'
    white: '37'

  @STYLES =
    reset: '0'
    normal: '0'
    bold: '1'
    underlined: '2'
    negative: '5'

  # add colors and styles as methods
  for name, code of extend(extend({}, @COLORS), @STYLES)
    do (name, code) =>
      this::[name] = ->
        @print("\x1b[#{code}m") unless @disabled
        @print.apply(this, arguments) if arguments.length
        @print("\x1b[#{@constructor.STYLES.reset}m") unless @disabled
        return this

  constructor: ->
    @output = ''

  print: ->
    @output += arg for arg in arguments
    return this

  toString: ->
    @output
