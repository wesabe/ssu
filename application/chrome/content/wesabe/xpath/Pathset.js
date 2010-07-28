wesabe.provide('xpath.Pathset');
wesabe.require('util');
wesabe.require('xpath.Pathway');

/**
 * Provides methods for dealing with sets of +Pathways+.
 */
wesabe.xpath.Pathset = function() {
  var args = [];
  
  for (var i = 0; i < arguments.length; i++)
    args.push(arguments[i]);
  
  if ((args.length == 1) && (args[0] instanceof Array))
    args = args[0];
  
  this.xpaths = [];
  
  for (var i = 0; i < args.length; i++)
    this.xpaths.push(wesabe.xpath.Pathway.from(args[i]));
  
  /**
   * Returns the first matching DOM element in the given document.
   * 
   * ==== Parameters
   * document<HTMLDocument>:: The document to serve as the root.
   * scope<HTMLElement>:: The element to scope the search to.
   * 
   * ==== Returns
   * tainted(HTMLElement):: The first matching DOM element.
   * 
   * @public
   */
  this.first = function(document, scope) {
    var element;
    
    for (var i = 0; i < this.xpaths.length; i++) {
      if (element = this.xpaths[i].first(document, scope))
        return element;
    }
  };
  
  /**
   * Returns all matching DOM elements from the all matching Pathways in the set.
   * 
   * ==== Parameters
   * document<HTMLDocument>:: The document to serve as the root.
   * scope<HTMLElement, null>:: An optional scope to search within.
   * 
   * ==== Returns
   * tainted(Array[HTMLElement]):: All matching DOM elements.
   * 
   * @public
   */
  this.select = function(document, scope) {
    var elements = [];
    
    for (var i = 0; i < this.xpaths.length; i++) {
      elements = elements.concat(this.xpaths[i].select(document, scope));
    }
    
    return wesabe.xpath.Pathway.inDocumentOrder(wesabe.lang.array.uniq(elements));
  };
  
  /**
   * Applies a binding to a copy of this +Pathset+.
   * 
   * ==== Parameters
   * binding<Object>:: Key-value pairs to interpolate into the +Pathset+.
   * 
   * ==== Returns
   * wesabe.xpath.Pathset:: A new +Pathset+ bound to +binding+.
   * 
   * ==== Example
   *   var pathset = new wesabe.xpath.Pathset(
   *     '//a[@title=":title"]', '//a[contains(string(.), ":title")]);
   *   pathway.bind({title: "Wesabe"});
   *   // results in #<wesabe.xpath.Pathset value=[
   *                   '//a[@title="Wesabe"]', '//a[contains(string(.), "Wesabe")]>
   * 
   * @public
   */
  this.bind = function(binding) {
    var boundPathways = [];
    
    for (var i = 0; i < this.xpaths.length; i++) {
      boundPathways.push(this.xpaths[i].bind(binding));
    }
    
    return new wesabe.xpath.Pathset(boundPathways);
  };
};
