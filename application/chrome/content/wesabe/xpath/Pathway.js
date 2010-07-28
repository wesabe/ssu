wesabe.provide('xpath.Pathway');
wesabe.require('util');

/**
 * Provides methods for generating, manipulating, and searching by XPaths.
 *
 * ==== Types (shortcuts for use in this file)
 * Xpath:: <String, Array[String], wesabe.xpath.Pathway, wesabe.xpath.Pathset>
 */
wesabe.xpath.Pathway = function(value) {
  var self = this;
  this.value = value;

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
    var result = document.evaluate(
                  wesabe.untaint(self.value), wesabe.untaint(scope || document),
                  null, XPathResult.ANY_TYPE, null, null);
    return result && wesabe.taint(result.iterateNext());
  };

  /**
   * Returns all matching DOM elements in the given document.
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
    var result = document.evaluate(
                  wesabe.untaint(self.value), wesabe.untaint(scope || document),
                  null, XPathResult.ANY_TYPE, null, null);
    var node, nodes = [];
    while (node = result.iterateNext()) nodes.push(node);
    return wesabe.taint(wesabe.xpath.Pathway.inDocumentOrder(nodes));
  };

  /**
   * Applies a binding to a copy of this +Pathway+.
   *
   * ==== Parameters
   * binding<Object>:: Key-value pairs to interpolate into the +Pathway+.
   *
   * ==== Returns
   * wesabe.xpath.Pathway:: A new +Pathway+ bound to +binding+.
   *
   * ==== Example
   *   var pathway = new wesabe.xpath.Pathway('//a[@title=":title"]');
   *   pathway.bind({title: "Wesabe"}).value; // => '//a[@title="Wesabe"]'
   *
   * @public
   */
  this.bind = function(binding) {
    var boundValue = this.value;

    for (var key in binding) {
      boundValue = boundValue.replace(new RegExp(':' + key, 'g'), wesabe.untaint(binding[key]));
      if (wesabe.isTainted(binding[key])) boundValue = wesabe.taint(boundValue);
    }

    return new wesabe.xpath.Pathway(boundValue);
  };
};

/**
 * Applies a binding to an +Xpath+.
 *
 * ==== Parameters
 * xpath<Xpath>:: The thing to bind.
 * binding<Object>:: Key-value pairs to interpolate into the xpath.
 *
 * ==== Returns
 * wesabe.xpath.Pathway,wesabe.xpath.Pathset::
 *   A +Pathway+-compatible object with bindings applied from +binding+.
 *
 * ==== Example
 *   wesabe.xpath.bind('//a[@title=":title"]', {title: "Wesabe"}).value // => '//a[@title="Wesabe"]'
 *
 * @public
 */
wesabe.xpath.bind = function(xpath, binding) {
  return wesabe.xpath.Pathway.from(xpath).bind(binding);
};

/**
 * Returns a +Pathway+-compatible object if one can be generated from +xpath+.
 *
 * ==== Parameters
 * xpath<Xpath>::
 *   Something that can be used as a +Pathway+.
 *
 * ==== Returns
 * wesabe.xpath.Pathway,wesabe.xpath.Pathset::
 *   A +Pathway+ or +Pathset+ converted from the argument.
 *
 * @public
 */
wesabe.xpath.Pathway.from = function(xpath) {
  if (wesabe.isString(xpath)) return new wesabe.xpath.Pathway(xpath);
  if (wesabe.isArray(xpath)) return new wesabe.xpath.Pathset(xpath);
  if (xpath instanceof wesabe.xpath.Pathway) return xpath;
  if (xpath instanceof wesabe.xpath.Pathset) return xpath;
  throw new Error("Could not convert " + wesabe.util.inspect(xpath) + " to a wesabe.xpath.Pathway.")
};

/**
 * Returns the given array with elements sorted by document order.
 *
 * ==== Parameters
 * elements<Array[~compareDocumentPosition]>:: List of elements to sort.
 *
 * ==== Returns
 * Array[~compareDocumentPosition]:: List of sorted elements.
 *
 * @public
 */
wesabe.xpath.Pathway.inDocumentOrder = function(elements) {
  return elements.sort(function(a, b) {
    a = wesabe.untaint(a); b = wesabe.untaint(b);
    switch (a.compareDocumentPosition(b)) {
      case Node.DOCUMENT_POSITION_PRECEDING:
      case Node.DOCUMENT_POSITION_CONTAINS:
        return 1;
      case Node.DOCUMENT_POSITION_FOLLOWING:
      case Node.DOCUMENT_POSITION_IS_CONTAINED:
        return -1;
      default:
        return 0;
    }
  });
};
