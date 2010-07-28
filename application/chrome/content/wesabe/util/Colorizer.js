wesabe.provide('util.Colorizer');

/**
 * Provides an easy way to generate ANSI color strings for the shell.
 * Example:
 *   
 *   var s = new wesabe.util.Colorizer();
 *   s.red();
 *   s.print("this is red.");
 *   s.underlined();
 *   s.print("and this is red and underlined.");
 *   s.reset();
 *   dump(s.toString());
 */
wesabe.util.Colorizer = function() {
  var output = '', self = this, escapes = {};
  
  wesabe.lang.extend(escapes, wesabe.util.Colorizer.COLORS);
  wesabe.lang.extend(escapes, wesabe.util.Colorizer.STYLES);
  
  this.printer = function(escape) {
    this[escape] = function() {
      if (!this.disabled) this.print("\x1b["+escapes[escape]+"m");
      if (arguments.length) {
        this.print.apply(this, arguments);
        if (!this.disabled) this.print("\x1b["+escapes.reset+"m");
      }
      return this;
    }
  };
  
  for (var escape in escapes) {
    this.printer(escape);
  }
  
  this.print = function() {
    for (var i = 0; i < arguments.length; i++) output += arguments[i];
    return this;
  };
  
  this.toString = function() {
    return output;
  };
};

wesabe.util.Colorizer.COLORS = {
  black: '30', 
  red: '31', 
  green: '32', 
  yellow: '33', 
  blue: '34', 
  magenta: '35', 
  cyan: '36', 
  white: '37'
};

wesabe.util.Colorizer.STYLES = {
  reset: '0', 
  normal: '0', 
  bold: '1', 
  underlined: '2', 
  negative: '5'
};
