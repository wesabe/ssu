wesabe.provide('dom.page');

wesabe.require('lang.*');
wesabe.require('util.*');
wesabe.require('xpath.*');

/**
 * Provides a wrapper around an +HTMLDocument+ to simplify interaction with it.
 *
 * ==== Types (shortcuts for use in this file)
 * Xpath:: <String, Array[String], wesabe.xpath.Pathway, wesabe.xpath.Pathset>
 */
wesabe.dom.page = {
  EVENT_TYPE_MAP: {
    click: 'MouseEvents',
    mousedown: 'MouseEvents',
    mouseup: 'MouseEvents',
    mousemove: 'MouseEvents',
    change: 'HTMLEvents',
    submit: 'HTMLEvents'
  },

  /**
   * Finds the first node matching +xpathOrNode+ in +document+ with optional
   * +scope+ when it is an xpath, returns it when it's a node.
   *
   * ==== Parameters
   * document<HTMLDocument>:: The document to serve as the root.
   * xpathOrNode<HTMLElement, Xpath>:: The thing to look for.
   * scope<HTMLElement>:: The element to scope the search to.
   *
   * ==== Returns
   * HTMLElement, null:: The found element, if one was found.
   *
   * @public
   */
  find: function(document, xpathOrNode, scope) {
    if (xpathOrNode && xpathOrNode.nodeType) return xpathOrNode;
    var xpath = wesabe.xpath.Pathway.from(xpathOrNode);
    return xpath.first(document, scope);
  },

  /**
   * Finds all nodes matching +xpathOrNode+ in +document+ with optional
   * +scope+ when it is an xpath, returns it when it's a node.
   *
   * ==== Parameters
   * document<HTMLDocument>:: The document to serve as the root.
   * xpathOrNode<HTMLElement, Xpath>:: The thing to look for.
   * scope<HTMLElement>:: The element to scope the search to.
   *
   * ==== Returns
   * tainted(Array[HTMLElement]):: The found elements.
   *
   * @public
   */
  select: function(document, xpathOrNode, scope) {
    if (xpathOrNode && xpathOrNode.nodeType) return [xpathOrNode];
    var xpath = wesabe.xpath.Pathway.from(xpathOrNode);
    return xpath.select(document, scope && wesabe.dom.page.find(document, scope));
  },

  /**
   * Finds the first node matching +xpathOrNode+ in +document+ with optional
   * +scope+ when it is an xpath, returns it when it's a node. If nothing
   * is found an exception is thrown.
   *
   * ==== Parameters
   * document<HTMLDocument>:: The document to serve as the root.
   * xpathOrNode<Xpath, HTMLElement>:: The thing to look for.
   * scope<HTMLElement>:: The element to scope the search to.
   *
   * ==== Returns
   * tainted(HTMLElement):: The found element.
   *
   * ==== Raises
   * Error:: When no element is found.
   *
   * @public
   */
  findStrict: function(document, xpathOrNode, scope) {
    var element = wesabe.dom.page.find(document, xpathOrNode, scope);
    if (!element)
      throw new Error("No element found matching " + wesabe.util.inspect(xpathOrNode));
    return element;
  },

  /**
   * Fills the given node/xpath endpoint with the given value.
   *
   * ==== Parameters
   * document<HTMLDocument>:: The document to serve as the root.
   * xpathOrNode<HTMLElement, Xpath>:: The thing to fill.
   * valueOrXpathOrNode<Xpath, HTMLElement>::
   *   The value to set the node to if it's a string, or the element whose
   *   value to use otherwise.
   *
   * ==== Raises
   * Error:: When the element can't be found.
   *
   * ==== Notes
   * The value assigned is truncated according to the maxlength property,
   * if present. This also triggers the +change+ event on the element it finds.
   *
   * @public
   */
  fill: function(document, xpathOrNode, valueOrXpathOrNode) {
    wesabe.tryThrow('page.fill', function(log) {
      var element = wesabe.dom.page.findStrict(document, xpathOrNode);
      log.info('element=', element);

      var value = wesabe.untaint(valueOrXpathOrNode);
      if (wesabe.isNumber(value)) {
        value = value.toString();
      }
      if (value && !wesabe.isString(value)) {
        var valueNode = wesabe.dom.page.findStrict(document, value, element);
        log.debug('valueNode=', valueNode);
        value = wesabe.untaint(valueNode.value);
      }
      log.radioactive('value=', value);

      var maxlength = wesabe.untaint(element).getAttribute("maxlength");
      if (value && maxlength) {
        maxlength = parseInt(maxlength, 10);  // get as an integer in base 10
        if (maxlength) {
          log.warn("Truncating value to ", maxlength, " characters");
          value = value.substring(0, maxlength);
        }
      }

      wesabe.untaint(element).value = value;
      wesabe.dom.page.fireEvent(document, element, 'change');
    });
  },

  /**
   * Clicks the given node/xpath endpoint.
   *
   * ==== Parameters
   * document<HTMLDocument>:: The document to serve as the root.
   * xpathOrNode<HTMLElement, Xpath>:: The thing to click.
   *
   * ==== Raises
   * Error:: When the element can't be found.
   *
   * ==== Notes
   * Triggers the events +mousedown+, +click+, then +mouseup+.
   *
   * @public
   */
  click: function(document, xpathOrNode) {
    wesabe.tryThrow('page.click', function(log) {
      var element = wesabe.dom.page.findStrict(document, xpathOrNode);
      log.info('element=', element);
      wesabe.dom.page.fireEvent(document, element, 'mousedown');
      wesabe.dom.page.fireEvent(document, element, 'click');
      wesabe.dom.page.fireEvent(document, element, 'mouseup');
    });
  },

  /**
   * Checks the element given by +xpathOrNode+.
   *
   * ==== Parameters
   * document<HTMLDocument>:: The document to serve as the root.
   * xpathOrNode<HTMLElement, Xpath>:: The thing to check.
   *
   * ==== Raises
   * Error:: When the element can't be found.
   *
   * @public
   */
  check: function(document, xpathOrNode) {
    wesabe.tryThrow('page.check', function(log) {
      var element = wesabe.dom.page.findStrict(document, xpathOrNode);
      log.info('element=', element);
      wesabe.untaint(element).checked = true;
    });
  },

  /**
   * Unchecks the element given by +xpathOrNode+.
   *
   * ==== Parameters
   * document<HTMLDocument>:: The document to serve as the root.
   * xpathOrNode<HTMLElement, Xpath>:: The thing to uncheck.
   *
   * ==== Raises
   * Error:: When the element can't be found.
   *
   * @public
   */
  uncheck: function(document, xpathOrNode) {
    wesabe.tryThrow('page.uncheck', function(log) {
      var element = wesabe.dom.page.findStrict(document, xpathOrNode);
      log.info('element=', element);
      wesabe.untaint(element).checked = false;
    });
  },

  /**
   * Simulates submitting a form.
   *
   * ==== Parameters
   * document<HTMLDocument>:: The document to serve as the root.
   * xpathOrNode<HTMLElement, Xpath>:: The thing to uncheck.
   *
   * ==== Raises
   * Error::
   *   When the element can't be found or when it is not a form
   *   or contained by a form.
   *
   * ==== Notes
   * The found element can be either a form or a descendent of a form.
   *
   * @public
   */
  submit: function(document, xpathOrNode) {
    wesabe.tryThrow('page.submit', function(log) {
      var element = wesabe.dom.page.findStrict(document, xpathOrNode);
      log.info('element=', element);
      // find the containing form
      while (element && element.tagName.toLowerCase() != 'form') element = element.parentNode;
      if (!element)
        throw new Error('No form found wrapping element! Cannot submit')

      wesabe.dom.page.fireEvent(document, element, 'submit');
    });
  },

  /**
   * Fires an event on the given node/xpath endpoint.
   *
   * ==== Parameters
   * document<HTMLDocument>:: The document to serve as the root.
   * xpathOrNode<HTMLElement, Xpath>:: The thing to fire the event on.
   * event<String>:: The name of the event to fire (e.g. 'click').
   *
   * @public
   */
  fireEvent: function(document, xpathOrNode, event) {
    var element = wesabe.untaint(wesabe.dom.page.findStrict(document, xpathOrNode));
    var ev = element.ownerDocument.createEvent(wesabe.dom.page.EVENT_TYPE_MAP[event]);
    ev.initEvent(event, true, true);
    element.dispatchEvent(ev);
  },

  /**
   * Determines whether the given node/xpath endpoint is visible.
   *
   * ==== Parameters
   * document<HTMLDocument>:: The document to serve as the root.
   * xpathOrNode<HTMLElement, Xpath>:: The thing to check for visibility.
   *
   * ==== Notes
   * Returns +true+ when given a text node.
   *
   * @public
   */
  visible: function(document, xpathOrNode) {
    var element = wesabe.untaint(wesabe.dom.page.find(document, xpathOrNode));
    if (element) {
      if (element.nodeType == 3) return true; /* text nodes don't have style */
      var visible = (document.defaultView.getComputedStyle(element, null).display != 'none');
      if (element.parentNode && element != document.body) {
        return visible && wesabe.dom.page.visible(document, element.parentNode);
      } else {
        return visible;
      }
    }
    return false;
  },

  /**
   * Determines whether the given node/xpath endpoint is visible.
   *
   * ==== Parameters
   * document<HTMLDocument>:: The document to serve as the root.
   * xpathOrNode<HTMLElement, Xpath>:: The thing to check for existence.
   * scope<HTMLElement>:: The element to scope the search to.
   *
   * @public
   */
  present: function(document, xpathOrNode, scope) {
    return !!wesabe.dom.page.find(document, xpathOrNode, scope);
  },

  /**
   * Generates a percentage match between the page and the xpaths based on
   * how many of the elements are present on the page.
   *
   * ==== Parameters
   * document<HTMLDocument>:: The page document to check.
   * xpaths<Array[String, wesabe.xpath.Pathway]>:: The xpaths to look for.
   *
   * ==== Returns
   * Number:: A number between 0 and 1 representing a percentage match.
   *
   * @public
   */
  match: function(document, xpaths) {
    var match = 0;
    xpaths.forEach(function(xpath){
      xpath = wesabe.xpath.from(xpath);
      if (wesabe.dom.page.present(document, xpath)) match++;
    });
    return parseFloat(match) / xpaths.length;
  },

  /**
   * Gets all the cells associated with the given node. For a <th> or <td> node,
   * that's all the <td> elements in the same column. For a <tr> node, that's
   * all the <td> elements in the same row.
   *
   * @param document [HTMLDocument]
   *   The document to serve as the root.
   * @param xpathOrNode [HTMLElement, Xpath]
   *   The thing to get related cells for.
   *
   * @return [tainted(Array[HTMLElement]), null]
   *   The cells related to +xpathOrNode+, or +null+ if the found node
   *   is not of a type that has related cells.
   *
   * @public
   */
  cells: function(document, xpathOrNode) {
    var node = wesabe.untaint(wesabe.dom.page.findStrict(document, xpathOrNode));
    var name = node.tagName.toLowerCase();
    switch (name) {
      case 'th': case 'td':
        var preceding = wesabe.dom.page.select(document, 'preceding-sibling::'+name, node);
        var col = preceding.length + 1;
        return wesabe.dom.page.select(document, 'ancestor::table//tr/td[position()='+col+']', node);
      case 'tr':
        return wesabe.dom.page.select(document, './td', node);
    }
    return null;
  },

  /**
   * Finds the next sibling matching +siblingMatcher+, if given.
   *
   * @param document [HTMLDocument]
   *   The document to serve as the root.
   * @param xpathOrNode [HTMLElement, Xpath]
   *   The thing whose next sibling is wanted.
   * @param siblingMatcher [String, null]
   *   An Xpath expression to use to match the following sibling (defaults to "*").
   *
   * @return [tainted([HTMLElement]), null]
   */
  next: function(document, xpathOrNode, siblingMatcher) {
    var node = wesabe.dom.page.findStrict(document, xpathOrNode);
    return wesabe.dom.page.find(document, 'following-sibling::'+(siblingMatcher || '*'), node);
  },

  /**
   * Returns the text content of +xpathOrNode+.
   *
   * @param document [HTMLDocument]
   *   The document to serve as the root.
   * @param xpathOrNode [HTMLElement, Xpath]
   *   The thing whose text is wanted.
   *
   * @return [tainted([String])]
   */
  text: function(document, xpathOrNode) {
    var node = wesabe.dom.page.findStrict(document, xpathOrNode);
    return wesabe.taint(wesabe.dom.page.select(document, './/text()', node).map(function(text){ return wesabe.untaint(text.nodeValue); }).join(''));
  },

  /**
   * Goes back one step in the document's window's history.
   *
   * @param document [HTMLDocument]
   *   The page document contained by the window to navigate.
   *
   * @public
   */
  back: function(document) {
    document.defaultView.history.back();
  },

  /**
   * Inject some javascript into a document by appending a script tag.
   *
   * @param document [HTMLDocument]
   *   The page document to append the script tag to.
   *
   * @param script [String]
   *   JavaScript to be put into the page and executed.
   *
   * @public
   */
  inject: function(document, script) {
    var element = document.createElementNS("http://www.w3.org/1999/xhtml", "script");
    element.setAttribute("type", "text/javascript");
    element.setAttribute("style", "display:none");
    element.innerHTML = script;
    document.documentElement.appendChild(element);
  },

  /**
   * Dumps the HTML and PNG representations of the page to the profile
   * under +%PROFILE_DIR%/wesabe-page-dumps+.
   *
   * @param document [HTMLDocument]
   *   The page document to dump.
   *
   * @return Options
   *   :html<String>:: The path of the dumped HTML.
   *   :png<String>:: The path of the dumped PNG.
   *
   * @public
   */
  dump: function(document) {
    return wesabe.tryThrow('page.dump', function() {
      var folder = wesabe.io.dir.profile;
      folder.append('wesabe-page-dumps');
      wesabe.io.dir.create(folder);

      var html = folder.clone(), png = folder.clone(), basename;
      basename = document.title.replace(/[^-_a-zA-Z0-9 ]/g, '');
      basename = (new Date()).getTime() + '-' + basename;
      html.append(basename+'.html');
      png.append(basename+'.png');

      wesabe.debug('Dumping contents of current page to ', html.path, ' and ', png.path);
      wesabe.io.file.write(html, "<html>"+document.documentElement.innerHTML+"</html>");
      wesabe.canvas.snapshot.writeToFile(document.defaultView, png.path);

      return {html: html.path, png: png.path};
    });
  },

  dumpStructure: function(document, scope, level) {
    level = level || 0;
    var indent = "";
    for (var i = 0; i < level; i++) indent += "  ";
    wesabe.dom.page.select(document, '*', scope || document).forEach(function(node) {
      wesabe.debug(indent, '<', wesabe.untaint(node.tagName.toLowerCase()), ' id=', wesabe.util.inspect(wesabe.untaint(node.id)), '>');
      wesabe.dom.page.dumpStructure(document, node, level + 1);
      wesabe.debug(indent, '</', wesabe.untaint(node.tagName.toLowerCase()), '>');
    });
  },

  // This method replaces all words in text nodes with asterisks unless
  // the word is a dictionary word (defined in wesabe.util.words.list),
  // then dumps the page as usual.
  dumpPrivately: function(document) {
    wesabe.dom.page.select(document, '//body//text()').forEach(function(text) {
      text = wesabe.untaint(text);
      var value = text.nodeValue, m = null;
      var sanitized = [];

      while (value && (m = value.match(/\W+/))) {
        var word = RegExp.leftContext;
        var sep  = m[0];
        var rest = RegExp.rightContext;

        if (wesabe.util.words.exist(word)) {
          sanitized.push(word);
        } else {
          for (var i = 0; i < word.length; i++)
            sanitized.push('*');
        }
        sanitized.push(sep);

        // use the remainder as the new value
        value = rest;
      }

      // replace the existing one with the sanitized one
      text.nodeValue = sanitized.join('');
    });
    return wesabe.dom.page.dump(document);
  },

  /**
   * Wraps the document so that it has all the methods of +wesabe.dom.page+.
   *
   * ==== Parameters
   * document<HTMLDocument>:: The page document to wrap.
   *
   * ==== Example
   *   // allows accessing wesabe.dom.page methods directly
   *   var page = wesabe.dom.page.wrap(document);
   *   page.click('//a[@title="Wesabe"]');
   *
   *   // also allows direct access to existing methods/fields
   *   alert(page.title);
   */
  wrap: function(document) {
    var proxy = wesabe.util.proxy(document);

    for (var key in wesabe.dom.page) {
      if (key == 'wrap') continue;
      // add a method to the proxy that puts the proxy first in the argument list
      proxy[key] = new Function("return wesabe.dom.page." + key + ".apply(this, [this].concat(wesabe.lang.array.from(arguments)))");
    }
    return proxy;
  }
};
