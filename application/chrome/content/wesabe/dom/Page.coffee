#
# Provides a wrapper around an +HTMLDocument+ to simplify interaction with it.
#

{Pathway} = require 'xpath'
Colorizer = require 'util/Colorizer'
inspect   = require 'util/inspect'
type      = require 'lang/type'
number    = require 'lang/number'
dir       = require 'io/dir'
file      = require 'io/file'
snapshot  = require 'canvas/snapshot'
english   = require 'util/words'
privacy   = require 'util/privacy'
{tryCatch, tryThrow} = require 'util/try'

# ==== Types (shortcuts for use in this file)
# Xpath:: <String, Array[String], Pathway, Pathset>
#
EVENT_TYPE_MAP =
  click:     'MouseEvents'
  mousedown: 'MouseEvents'
  mouseup:   'MouseEvents'
  mousemove: 'MouseEvents'
  change:    'HTMLEvents'
  submit:    'HTMLEvents'
  keydown:   'KeyEvents'
  keypress:  'KeyEvents'
  keyup:     'KeyEvents'
  focusin:   'UIEvents'
  focus:     'UIEvents'
  blur:      'UIEvents'
  focusout:  'UIEvents'

class Page
  constructor: (@document) ->

  #
  # Returns the title of this page.
  #
  @::__defineGetter__ 'title', ->
    privacy.taint @document.title

  @::__defineGetter__ 'name', ->
    privacy.taint @defaultView.name

  #
  # Returns the +Window+ associated with this page.
  #
  @::__defineGetter__ 'defaultView', ->
    privacy.taint @document.defaultView

  #
  # Returns the URL of this page.
  #
  @::__defineGetter__ 'url', ->
    privacy.taint @document.URL

  #
  # Returns true if this page is in a frame, false otherwise.
  #
  @::__defineGetter__ 'framed', ->
    if frameElement = @defaultView.frameElement
      return frameElement.tagName?.toLowerCase() isnt 'browser'
    else
      return false

  #
  # Returns the top-most +Page+, the one at the root of the frame hierarchy.
  #
  @::__defineGetter__ 'topPage', ->
    @constructor.wrap @defaultView.top.document

  #
  # Returns an array of +Page+ objects wrapping all the frames contained in this +Page+.
  #
  @::__defineGetter__ 'framePages', ->
    @constructor.wrap frame.document for frame in @defaultView.frames

  #
  # Finds the first node matching +xpathOrNode+ with optional
  # +scope+ when it is an xpath, returns it when it's a node.
  #
  # ==== Parameters
  # xpathOrNode<HTMLElement, Xpath>:: The thing to look for.
  # scope<HTMLElement>:: The element to scope the search to.
  #
  # ==== Returns
  # HTMLElement, null:: The found element, if one was found.
  #
  # @public
  #
  find: (xpathOrNode, scope) ->
    return xpathOrNode if xpathOrNode?.nodeType
    xpath = Pathway.from(xpathOrNode)
    return xpath.first(@document, scope)

  #
  # Shorthand for finding an element by id, returns null if not found.
  #
  byId: (id) ->
    privacy.taint @document.getElementById(id)

  #
  # Find a link either by id, href, content, or using a matcher function.
  #
  #   # matches <a id="formSubmitButton">
  #   page.link 'formSubmitButton'
  #
  #   # both match <a href="/logoff">Log Off</a>
  #   page.link '/logoff'
  #   page.link 'Log Off'
  #
  #   # matches the first link whose content text is longer than 1000 characters
  #   page.link (a) -> page.text(a).length > 1000
  #
  link: (matcher, scope) ->
    if type.isString matcher
      escaped = matcher.replace /"/, '\\"'
      @find """//a[@id="#{escaped}" or @href="#{escaped}" or contains(string(.), "#{escaped}")]""", scope

    else if type.isFunction matcher
      for link in @select '//a', scope
        return link if matcher link

      return null

  #
  # Finds all nodes matching +xpathOrNode+ with optional
  # +scope+ when it is an xpath, returns it when it's a node.
  #
  # ==== Parameters
  # xpathOrNode<HTMLElement, Xpath>:: The thing to look for.
  # scope<HTMLElement>:: The element to scope the search to.
  #
  # ==== Returns
  # tainted(Array[HTMLElement]):: The found elements.
  #
  # @public
  #
  select: (xpathOrNode, scope) ->
    return xpathOrNode if xpathOrNode?.nodeType
    xpath = Pathway.from(xpathOrNode)
    return xpath.select(@document, scope and @find(scope))

  #
  # Finds the first node matching +xpathOrNode+ with optional
  # +scope+ when it is an xpath, returns it when it's a node. If nothing
  # is found an exception is thrown.
  #
  # ==== Parameters
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
  findStrict: (xpathOrNode, scope) ->
    result = @find xpathOrNode, scope
    throw new Error "No element found matching #{inspect xpathOrNode}" unless result
    return result

  #
  # Fills the given node/xpath endpoint with the given value.
  #
  # ==== Parameters
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
  fill: (xpathOrNode, valueOrXpathOrNode) ->
    tryThrow 'Page.fill', (log) =>
      element = privacy.untaint @findStrict(xpathOrNode)
      log.info 'element=', privacy.taint(element)

      value = privacy.untaint(valueOrXpathOrNode)
      value = value.toString() if type.isNumber(value)

      if value and not type.isString(value)
        valueNode = privacy.untaint @findStrict(value, element)
        log.debug 'valueNode=', privacy.taint(valueNode)
        value = valueNode.value

      log.radioactive 'value=', value

      maxlength = element.getAttribute("maxlength")
      if value and maxlength
        maxlength = number.parse(maxlength)
        if maxlength
          log.warn "Truncating value to ", maxlength, " characters"
          value = value[0...maxlength]

      ##
      #
      # Fill Event Order
      #
      # focusin
      # focus
      # change
      # focusout
      # blur
      #
      ##

      @fireEvent element, 'focusin'
      @fireEvent element, 'focus'

      if element.type is 'text'
        # fill text inputs one character at a time
        for i in [0...value.length]
          charCode = value.charCodeAt(i)
          @fireEvent element, 'keydown',  keyCode: charCode
          @fireEvent element, 'keypress', keyCode: charCode, charCode: charCode
          @fireEvent element, 'keyup',    keyCode: charCode

      element.value = value
      @fireEvent element, 'change'

      @fireEvent element, 'focusout'
      @fireEvent element, 'blur'

  #
  # Clicks the given node/xpath endpoint.
  #
  # ==== Parameters
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
  click: (xpathOrNode) ->
    tryThrow 'Page.click', (log) =>
      element = @findStrict xpathOrNode
      log.info 'element=', element
      @fireEvent element, 'mousedown'
      @fireEvent element, 'click'
      @fireEvent element, 'mouseup'

  #
  # Checks the element given by +xpathOrNode+.
  #
  # ==== Parameters
  # xpathOrNode<HTMLElement, Xpath>:: The thing to check.
  #
  # ==== Raises
  # Error:: When the element can't be found.
  #
  # @public
  #
  check: (xpathOrNode) ->
    tryThrow 'Page.check', (log) =>
      element = @findStrict xpathOrNode
      log.info 'element=', element
      privacy.untaint(element).checked = true

  #
  # Unchecks the element given by +xpathOrNode+.
  #
  # ==== Parameters
  # xpathOrNode<HTMLElement, Xpath>:: The thing to uncheck.
  #
  # ==== Raises
  # Error:: When the element can't be found.
  #
  # @public
  #
  uncheck: (xpathOrNode) ->
    tryThrow 'Page.uncheck', (log) =>
      element = @findStrict xpathOrNode
      log.info('element=', element)
      privacy.untaint(element).checked = false

  #
  # Simulates submitting a form.
  #
  # ==== Parameters
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
  submit: (xpathOrNode) ->
    tryThrow 'Page.submit', (log) =>
      element = @findStrict xpathOrNode
      log.info 'element=', element
      # find the containing form
      element = element.parentNode while element and element.tagName.toLowerCase() isnt 'form'
      throw new Error 'No form found wrapping element! Cannot submit' unless element

      @fireEvent element, 'submit'

  #
  # Fires an event on the given node/xpath endpoint.
  #
  # ==== Parameters
  # xpathOrNode<HTMLElement, Xpath>:: The thing to fire the event on.
  # type<String>:: The name of the event to fire (e.g. 'click').
  #
  # @public
  #
  fireEvent: (xpathOrNode, eventType, args...) ->
    options = if args.length is 1 and typeof args[args.length-1] is 'object' then args.pop() else {}
    element = privacy.untaint(@findStrict xpathOrNode)
    event = element.ownerDocument.createEvent EVENT_TYPE_MAP[eventType]

    if eventType in ['keydown', 'keypress', 'keyup']
      {bubbles, cancelable, view, ctrlKey, altKey, shiftKey, metaKey, keyCode, charCode} = options
      bubbles ?= true
      cancelable ?= true
      view ?= element.ownerDocument.defaultView
      ctrlKey ?= false
      altKey ?= false
      shiftKey ?= false
      metaKey ?= false
      keyCode ?= charCode or 0
      charCode ?= 0
      event.initKeyEvent(eventType, bubbles, cancelable, view, ctrlKey, altKey, shiftKey, metaKey, keyCode, charCode)
    else
      event.initEvent(eventType, true, true, args...)
      event[key] = value for own key, value of options

    element.dispatchEvent(event)

  #
  # Determines whether the given node/xpath endpoint is visible.
  #
  # ==== Parameters
  # xpathOrNode<HTMLElement, Xpath>:: The thing to check for visibility.
  #
  # ==== Notes
  # Returns +true+ when given a text node.
  #
  # @public
  #
  visible: (xpathOrNode) ->
    element = privacy.untaint @find(xpathOrNode)

    # no element? not visible
    return false unless element

    # text nodes don't have style
    if element.nodeType != 3
      # display:none? not visible
      return false if @document.defaultView.getComputedStyle(element, null).display is 'none'

    # check our ancestors if we're not the body
    if element.parentNode and element isnt @document.body
      return @visible element.parentNode

    # must be visible
    return true

  #
  # Determines whether the given node/xpath endpoint is visible.
  #
  # ==== Parameters
  # xpathOrNode<HTMLElement, Xpath>:: The thing to check for existence.
  # scope<HTMLElement>:: The element to scope the search to.
  #
  # @public
  #
  present: (xpathOrNode, scope) ->
    !!(@find xpathOrNode, scope)

  #
  # Generates a percentage match between the page and the xpaths based on
  # how many of the elements are present on the page.
  #
  # ==== Parameters
  # xpaths<Array[String, Pathway]>:: The xpaths to look for.
  #
  # ==== Returns
  # Number:: A number between 0 and 1 representing a percentage match.
  #
  # @public
  #
  match: (xpaths) ->
    match = 0
    for xpath in xpaths
      xpath = wesabe.xpath.from(xpath)
      match++ if @present xpath

    return match / xpaths.length

  #
  # Gets all the cells associated with the given node. For a <th> or <td> node,
  # that's all the <td> elements in the same column. For a <tr> node, that's
  # all the <td> elements in the same row.
  #
  # @param xpathOrNode [HTMLElement, Xpath]
  #   The thing to get related cells for.
  #
  # @return [tainted(Array[HTMLElement]), null]
  #   The cells related to +xpathOrNode+, or +null+ if the found node
  #   is not of a type that has related cells.
  #
  # @public
  #
  cells: (xpathOrNode) ->
    node = privacy.untaint @findStrict(xpathOrNode)
    name = node.tagName.toLowerCase()

    switch name
      when 'th', 'td'
        preceding = @select "preceding-sibling::#{name}", node
        col = preceding.length + 1
        @select "ancestor::table//tr/td[position()=#{col}]", node
      when 'tr'
        @select './td', node
      else
        null

  #
  # Finds the next sibling matching +siblingMatcher+, if given.
  #
  # @param xpathOrNode [HTMLElement, Xpath]
  #   The thing whose next sibling is wanted.
  # @param siblingMatcher [String, null]
  #   An Xpath expression to use to match the following sibling (defaults to "*").
  #
  # @return [tainted([HTMLElement]), null]
  #
  next: (xpathOrNode, siblingMatcher='*') ->
    @find "following-sibling::#{siblingMatcher}", @findStrict(xpathOrNode)

  #
  # Returns the text content of +xpathOrNode+.
  #
  # @param xpathOrNode [HTMLElement, Xpath]
  #   The thing whose text is wanted.
  #
  # @return [tainted([String])]
  #
  text: (xpathOrNode) ->
    node = @findStrict xpathOrNode
    if node.nodeType is 3
      textNodes = [node]
    else
      textNodes = @select './/text()', node
    privacy.taint (privacy.untaint(node.nodeValue) for node in textNodes).join('')

  #
  # Returns +true+ if +xpathOrNode+ has class +className+, +false+ otherwise.
  #
  hasClass: (xpathOrNode, className) ->
    " #{@findStrict(xpathOrNode).className} ".indexOf(" #{className} ") > -1

  #
  # Goes back one step in the document's window's history.
  #
  # @public
  #
  back: ->
    @document.defaultView.history.back()

  #
  # Inject some javascript into a document by appending a script tag.
  #
  # @param script [String]
  #   JavaScript to be put into the page and executed.
  #
  # @public
  #
  inject: (script) ->
    element = @document.createElementNS "http://www.w3.org/1999/xhtml", "script"
    element.setAttribute "type", "text/javascript"
    element.setAttribute "style", "display:none"
    element.innerHTML = script
    @document.documentElement.appendChild element

  #
  # Dumps the HTML and PNG representations of the page to the profile
  # under +%PROFILE_DIR%/wesabe-page-dumps+.
  #
  # @return Options
  #   :html<String>:: The path of the dumped HTML.
  #   :png<String>:: The path of the dumped PNG.
  #
  # @public
  #
  dump: ->
    tryThrow 'Page.dump', =>
      folder = dir.profile
      folder.append 'wesabe-page-dumps'
      dir.create folder

      html = folder.clone()
      png = folder.clone()
      basename = "#{new Date().getTime()}-#{@document.title.replace /[^-_a-zA-Z0-9 ]/g, ''}"
      html.append "#{basename}.html"
      png.append "#{basename}.png"

      logger.debug 'Dumping contents of current page to ', html.path, ' and ', png.path
      file.write html, "<html>#{@document.documentElement.innerHTML}</html>"
      snapshot.writeToFile @document.defaultView, png.path

      html: html.path
      png:  png.path

  dumpStructure: (scope, level=0) ->
    indent = ""
    indent += '  ' for i in [0...level]

    for node in @select '*', scope or @document
      selector = privacy.untaint node.tagName.toLowerCase()
      selector += "##{node.id}" if node.id
      selector += ".#{node.className.replace /\s+/g, '.'}" if node.className
      logger.debug indent, selector
      @dumpStructure node, level + 1

    return null

  # This method replaces all words in text nodes with asterisks unless
  # the word is a dictionary word (defined in wesabe.util.words.list),
  # then dumps the page as usual.
  dumpPrivately: ->
    for text in @select '//body//text()'
      text = privacy.untaint text
      value = text.nodeValue
      sanitized = []

      while value and (m = value.match /\W+/)
        word = RegExp.leftContext
        sep = m[0]
        rest = RegExp.rightContext

        if not english.contains word
          word = ('*' for i in [0...word.length]).join('')

        sanitized.push word, sep

        # use the remainder as the new value
        value = rest

      # replace the existing one with the sanitized one
      text.nodeValue = sanitized.join('')

    @dump

  contentForInspect: ->
    url: @url, title: @title, name: @name

  #
  # Wraps documents for scripts to have easy helper access.
  #
  @wrap: (document) ->
    if type.is document, @
      document
    else
      new @ document


module.exports = Page
