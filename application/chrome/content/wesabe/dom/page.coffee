wesabe.provide('dom.page')

wesabe.require('lang.*')
wesabe.require('util.*')
wesabe.require('xpath.*')

#
# Provides a wrapper around an +HTMLDocument+ to simplify interaction with it.
#
# ==== Types (shortcuts for use in this file)
# Xpath:: <String, Array[String], wesabe.xpath.Pathway, wesabe.xpath.Pathset>
#
wesabe.dom.page =
  EVENT_TYPE_MAP:
    click: 'MouseEvents'
    mousedown: 'MouseEvents'
    mouseup: 'MouseEvents'
    mousemove: 'MouseEvents'
    change: 'HTMLEvents'
    submit: 'HTMLEvents'

  #
  # Finds the first node matching +xpathOrNode+ in +document+ with optional
  # +scope+ when it is an xpath, returns it when it's a node.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # xpathOrNode<HTMLElement, Xpath>:: The thing to look for.
  # scope<HTMLElement>:: The element to scope the search to.
  #
  # ==== Returns
  # HTMLElement, null:: The found element, if one was found.
  #
  # @public
  #
  find: (document, xpathOrNode, scope) ->
    return xpathOrNode if xpathOrNode?.nodeType
    xpath = wesabe.xpath.Pathway.from(xpathOrNode)
    return xpath.first(document, scope)

  #
  # Finds all nodes matching +xpathOrNode+ in +document+ with optional
  # +scope+ when it is an xpath, returns it when it's a node.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # xpathOrNode<HTMLElement, Xpath>:: The thing to look for.
  # scope<HTMLElement>:: The element to scope the search to.
  #
  # ==== Returns
  # tainted(Array[HTMLElement]):: The found elements.
  #
  # @public
  #
  select: (document, xpathOrNode, scope) ->
    return xpathOrNode if xpathOrNode?.nodeType
    xpath = wesabe.xpath.Pathway.from(xpathOrNode)
    return xpath.select(document, scope && wesabe.dom.page.find(document, scope))

  #
  # Finds the first node matching +xpathOrNode+ in +document+ with optional
  # +scope+ when it is an xpath, returns it when it's a node. If nothing
  # is found an exception is thrown.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # xpathOrNode<Xpath, HTMLElement>:: The thing to look for.
  # scope<HTMLElement>:: The element to scope the search to.
  #
  # ==== Returns
  # tainted(HTMLElement):: The found element.
  #
  # ==== Raises
  # Error:: When no element is found.
  #
  # @public
  #
  findStrict: (document, xpathOrNode, scope) ->
    wesabe.dom.page.find(document, xpathOrNode, scope) || (
      throw new Error("No element found matching #{wesabe.util.inspect(xpathOrNode)}"))

  #
  # Fills the given node/xpath endpoint with the given value.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # xpathOrNode<HTMLElement, Xpath>:: The thing to fill.
  # valueOrXpathOrNode<Xpath, HTMLElement>::
  #   The value to set the node to if it's a string, or the element whose
  #   value to use otherwise.
  #
  # ==== Raises
  # Error:: When the element can't be found.
  #
  # ==== Notes
  # The value assigned is truncated according to the maxlength property,
  # if present. This also triggers the +change+ event on the element it finds.
  #
  # @public
  #
  fill: (document, xpathOrNode, valueOrXpathOrNode) ->
    wesabe.tryThrow('page.fill', (log) =>
      element = wesabe.dom.page.findStrict(document, xpathOrNode)
      log.info('element=', element)

      value = wesabe.untaint(valueOrXpathOrNode)
      value = value.toString() if wesabe.isNumber(value)

      if value && !wesabe.isString(value)
        valueNode = @findStrict(document, value, element)
        log.debug('valueNode=', valueNode)
        value = wesabe.untaint(valueNode.value)

      log.radioactive('value=', value)

      maxlength = wesabe.untaint(element).getAttribute("maxlength")
      if value && maxlength
        maxlength = parseInt(maxlength, 10)
        if maxlength
          log.warn("Truncating value to ", maxlength, " characters")
          value = value[0...maxlength]

      wesabe.untaint(element).value = value
      @fireEvent(document, element, 'change'))

  #
  # Clicks the given node/xpath endpoint.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # xpathOrNode<HTMLElement, Xpath>:: The thing to click.
  #
  # ==== Raises
  # Error:: When the element can't be found.
  #
  # ==== Notes
  # Triggers the events +mousedown+, +click+, then +mouseup+.
  #
  # @public
  #
  click: (document, xpathOrNode) ->
    wesabe.tryThrow('page.click', (log) =>
      element = @findStrict(document, xpathOrNode)
      log.info('element=', element)
      @fireEvent(document, element, 'mousedown')
      @fireEvent(document, element, 'click')
      @fireEvent(document, element, 'mouseup'))

  #
  # Checks the element given by +xpathOrNode+.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # xpathOrNode<HTMLElement, Xpath>:: The thing to check.
  #
  # ==== Raises
  # Error:: When the element can't be found.
  #
  # @public
  #
  check: (document, xpathOrNode) ->
    wesabe.tryThrow('page.check', (log) =>
      element = @findStrict(document, xpathOrNode)
      log.info('element=', element)
      wesabe.untaint(element).checked = true)

  #
  # Unchecks the element given by +xpathOrNode+.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # xpathOrNode<HTMLElement, Xpath>:: The thing to uncheck.
  #
  # ==== Raises
  # Error:: When the element can't be found.
  #
  # @public
  #
  uncheck: (document, xpathOrNode) ->
    wesabe.tryThrow('page.uncheck', (log) =>
      element = @findStrict(document, xpathOrNode)
      log.info('element=', element)
      wesabe.untaint(element).checked = false)

  #
  # Simulates submitting a form.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # xpathOrNode<HTMLElement, Xpath>:: The thing to uncheck.
  #
  # ==== Raises
  # Error::
  #   When the element can't be found or when it is not a form
  #   or contained by a form.
  #
  # ==== Notes
  # The found element can be either a form or a descendent of a form.
  #
  # @public
  #
  submit: (document, xpathOrNode) ->
    wesabe.tryThrow('page.submit', (log) =>
      element = @findStrict(document, xpathOrNode)
      log.info('element=', element)
      # find the containing form
      element = element.parentNode while element && element.tagName.toLowerCase() != 'form'
      throw new Error('No form found wrapping element! Cannot submit') unless element

      @fireEvent(document, element, 'submit'))

  #
  # Fires an event on the given node/xpath endpoint.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # xpathOrNode<HTMLElement, Xpath>:: The thing to fire the event on.
  # type<String>:: The name of the event to fire (e.g. 'click').
  #
  # @public
  #
  fireEvent: (document, xpathOrNode, type) ->
    element = wesabe.untaint(@findStrict(document, xpathOrNode))
    event = element.ownerDocument.createEvent(@EVENT_TYPE_MAP[type])
    event.initEvent(type, true, true)
    element.dispatchEvent(event)

  #
  # Determines whether the given node/xpath endpoint is visible.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # xpathOrNode<HTMLElement, Xpath>:: The thing to check for visibility.
  #
  # ==== Notes
  # Returns +true+ when given a text node.
  #
  # @public
  #
  visible: (document, xpathOrNode) ->
    element = wesabe.untaint(@find(document, xpathOrNode))

    # no element? not visible
    return false unless element

    # text nodes don't have style
    if element.nodeType != 3
      # display:none? not visible
      return false if document.defaultView.getComputedStyle(element, null).display == 'none'

    # check our ancestors if we're not the body
    if element.parentNode && (element != document.body)
      return @visible(document, element.parentNode)

    # must be visible
    return true

  #
  # Determines whether the given node/xpath endpoint is visible.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The document to serve as the root.
  # xpathOrNode<HTMLElement, Xpath>:: The thing to check for existence.
  # scope<HTMLElement>:: The element to scope the search to.
  #
  # @public
  #
  present: (document, xpathOrNode, scope) ->
    !!@find(document, xpathOrNode, scope)

  #
  # Generates a percentage match between the page and the xpaths based on
  # how many of the elements are present on the page.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The page document to check.
  # xpaths<Array[String, wesabe.xpath.Pathway]>:: The xpaths to look for.
  #
  # ==== Returns
  # Number:: A number between 0 and 1 representing a percentage match.
  #
  # @public
  #
  match: (document, xpaths) ->
    match = 0
    for xpath in xpaths
      xpath = wesabe.xpath.from(xpath)
      match++ if @present(document, xpath)

    return match / xpaths.length

  #
  # Gets all the cells associated with the given node. For a <th> or <td> node,
  # that's all the <td> elements in the same column. For a <tr> node, that's
  # all the <td> elements in the same row.
  #
  # @param document [HTMLDocument]
  #   The document to serve as the root.
  # @param xpathOrNode [HTMLElement, Xpath]
  #   The thing to get related cells for.
  #
  # @return [tainted(Array[HTMLElement]), null]
  #   The cells related to +xpathOrNode+, or +null+ if the found node
  #   is not of a type that has related cells.
  #
  # @public
  #
  cells: (document, xpathOrNode) ->
    node = wesabe.untaint(@findStrict(document, xpathOrNode))
    name = node.tagName.toLowerCase()

    switch name
      when 'th', 'td'
        preceding = @select(document, "preceding-sibling::#{name}", node)
        col = preceding.length + 1
        @select(document, "ancestor::table//tr/td[position()=#{col}]", node)
      when 'tr'
        @select(document, './td', node)
      else
        null

  #
  # Finds the next sibling matching +siblingMatcher+, if given.
  #
  # @param document [HTMLDocument]
  #   The document to serve as the root.
  # @param xpathOrNode [HTMLElement, Xpath]
  #   The thing whose next sibling is wanted.
  # @param siblingMatcher [String, null]
  #   An Xpath expression to use to match the following sibling (defaults to "*").
  #
  # @return [tainted([HTMLElement]), null]
  #
  next: (document, xpathOrNode, siblingMatcher) ->
    @find(document, "following-sibling::#{siblingMatcher || '*'}", @findStrict(document, xpathOrNode))

  #
  # Returns the text content of +xpathOrNode+.
  #
  # @param document [HTMLDocument]
  #   The document to serve as the root.
  # @param xpathOrNode [HTMLElement, Xpath]
  #   The thing whose text is wanted.
  #
  # @return [tainted([String])]
  #
  text: (document, xpathOrNode) ->
    textNodes = @select(document, './/text()', @findStrict(document, xpathOrNode))
    wesabe.taint((wesabe.untaint(node.nodeValue) for node in textNodes).join(''))

  #
  # Goes back one step in the document's window's history.
  #
  # @param document [HTMLDocument]
  #   The page document contained by the window to navigate.
  #
  # @public
  #
  back: (document) ->
    document.defaultView.history.back()

  #
  # Inject some javascript into a document by appending a script tag.
  #
  # @param document [HTMLDocument]
  #   The page document to append the script tag to.
  #
  # @param script [String]
  #   JavaScript to be put into the page and executed.
  #
  # @public
  #
  inject: (document, script) ->
    element = document.createElementNS("http://www.w3.org/1999/xhtml", "script")
    element.setAttribute("type", "text/javascript")
    element.setAttribute("style", "display:none")
    element.innerHTML = script
    document.documentElement.appendChild(element)

  #
  # Dumps the HTML and PNG representations of the page to the profile
  # under +%PROFILE_DIR%/wesabe-page-dumps+.
  #
  # @param document [HTMLDocument]
  #   The page document to dump.
  #
  # @return Options
  #   :html<String>:: The path of the dumped HTML.
  #   :png<String>:: The path of the dumped PNG.
  #
  # @public
  #
  dump: (document) ->
    wesabe.tryThrow('page.dump', =>
      folder = wesabe.io.dir.profile
      folder.append('wesabe-page-dumps')
      wesabe.io.dir.create(folder)

      html = folder.clone()
      png = folder.clone()
      basename = document.title.replace(/[^-_a-zA-Z0-9 ]/g, '')
      basename = "#{(new Date()).getTime()}-#{basename}"
      html.append("#{basename}.html")
      png.append("#{basename}.png")

      wesabe.debug('Dumping contents of current page to ', html.path, ' and ', png.path)
      wesabe.io.file.write(html, "<html>#{document.documentElement.innerHTML}</html>")
      wesabe.canvas.snapshot.writeToFile(document.defaultView, png.path)

      return {html: html.path, png: png.path})

  dumpStructure: (document, scope, level = 0) ->
    indent = ""
    for i in [0...level]
      for node in @select(document, '*', scope || document)
        wesabe.debug(indent, '<', wesabe.untaint(node.tagName.toLowerCase()), ' id=', wesabe.util.inspect(wesabe.untaint(node.id)), '>')
        @dumpStructure(document, node, level + 1)
        wesabe.debug(indent, '</', wesabe.untaint(node.tagName.toLowerCase()), '>')

  # This method replaces all words in text nodes with asterisks unless
  # the word is a dictionary word (defined in wesabe.util.words.list),
  # then dumps the page as usual.
  dumpPrivately: (document) ->
    for text in @select(document, '//body//text()')
      text = wesabe.untaint(text)
      value = text.nodeValue
      sanitized = []

      while value && (m = value.match(/\W+/))
        word = RegExp.leftContext
        sep = m[0]
        rest = RegExp.rightContext

        if wesabe.util.words.exist(word)
          sanitized.push(word)
        else
          for i in [0...word.length]
            sanitized.push('*')

        sanitized.push(sep)

        # use the remainder as the new value
        value = rest

      # replace the existing one with the sanitized one
      text.nodeValue = sanitized.join('')

    return @dump(document)

  #
  # Wraps the document so that it has all the methods of +wesabe.dom.page+.
  #
  # ==== Parameters
  # document<HTMLDocument>:: The page document to wrap.
  #
  # ==== Example
  #   // allows accessing wesabe.dom.page methods directly
  #   var page = wesabe.dom.page.wrap(document);
  #   page.click('//a[@title="Wesabe"]');
  #
  #   // also allows direct access to existing methods/fields
  #   alert(page.title);
  #
  wrap: (document) ->
    proxy = wesabe.util.proxy(document)

    for key of this
      continue if key == 'wrap'
      # add a method to the proxy that puts the proxy first in the argument list
      proxy[key] = new Function("return wesabe.dom.page.#{key}.apply(wesabe.dom.page, [this.proxyTarget].concat(wesabe.lang.array.from(arguments)))")

    return proxy
