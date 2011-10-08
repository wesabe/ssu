{Pathway} = require 'xpath'
Colorizer = require 'util/Colorizer'
inspect   = require 'util/inspect'
type      = require 'lang/type'
number    = require 'lang/number'
Dir       = require 'io/Dir'
File      = require 'io/File'
snapshot  = require 'canvas/snapshot'
english   = require 'util/words'
privacy   = require 'util/privacy'
{tryCatch, tryThrow} = require 'util/try'

# Internal: Event name to internal type mapping.
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

# Internal: Base error class for errors raised in Page.
class PageError
  constructor: (@page, @message) ->

  raise: ->
    error = new Error @message
    error.name = @constructor.name
    error.page = @page
    throw error

  @raise: (page, message) ->
    (new @ page, message).raise()

# Internal: Specialized error for when an attempt to
# interact with elements from another page happens.
class DocumentMismatchError extends PageError
  # Internal: Asserts that element belongs to document.
  #
  # node - Any Node whose ownership we'd like to verify.
  # document - Any Document we'd like to verify as the owner.
  #
  # Returns nothing.
  # Raises DocumentMismatchError if element's owner isn't document.
  @assert: (page, node) ->
    if node.ownerDocument isnt page.document
      @raise page, node

  constructor: (page, @node) ->
    super page, "you're attempting to use a node (#{inspect @node}) that doesn't belong to this page"

# Internal: Specialized error for when we were unable to find a node.
class NodeNotFoundError extends PageError
  constructor: (page, @xpath) ->
    super page, "expected to find a node matching #{inspect @xpath}, but none were found"

# Internal: Specialized error for when we're looking for an element's containing form.
class MissingFormError extends PageError
  constructor: (page, @xpath, @document) ->
    super page, "expected node matching #{inspect @xpath} to be contained by a <form>"


# Public: Provides a wrapper around an +HTMLDocument+ to simplify interaction with it.
#
# Examples
#
#   # click the first link on a page
#   page.click '//a'
#
#   # fill in a search field
#   page.fill '//input[@name="q"]', "doctor who"
class Page
  constructor: (@document) ->

  # Public: Gets the String page title, tainted.
  @::__defineGetter__ 'title', ->
    privacy.taint @document.title

  # Public: Sets the String page title.
  @::__defineSetter__ 'title', (title) ->
    @document.title = privacy.untaint title

  # Public: Gets the tainted String page name, tainted.
  @::__defineGetter__ 'name', ->
    privacy.taint @defaultView.name

  # Public: Gets this page's Window, tainted.
  @::__defineGetter__ 'defaultView', ->
    privacy.taint @document.defaultView

  # Public: Gets this page's String URL, tainted.
  @::__defineGetter__ 'url', ->
    privacy.taint @document.URL

  # Public: Gets this page's HTMLBodyElement, tainted.
  @::__defineGetter__ 'body', ->
    privacy.taint @document.body

  # Public: Determines whether this page is framed or not.
  #
  # Returns a Boolean that's true if this page is framed.
  @::__defineGetter__ 'framed', ->
    if frameElement = @defaultView.frameElement
      return frameElement.tagName?.toLowerCase() isnt 'browser'
    else
      return false

  # Public: Gets the Page at the root of the frame hierarchy.
  #
  # Returns a Page that is not contained by any other pages.
  @::__defineGetter__ 'topPage', ->
    @constructor.wrap @defaultView.top.document

  # Public: Gets all Pages contained in this Page's frames.
  #
  # Return an Array containing Pages.
  @::__defineGetter__ 'framePages', ->
    @constructor.wrap frame.document for frame in @defaultView.frames

  # Public: Finds the first matching node. This is like select(), but
  # returns the first matching node rather than all matching nodes.
  #
  # xpathOrNode - If it's a Node, just returns it. Otherwise it should
  #               be a String xpath.
  # scope - An Element to restrict the xpath search to, ignored if xpathOrNode
  #         is a Node.
  #
  # Examples
  #
  #   # finds the first link on the page
  #   page.find '//a'
  #
  #   # nodes passed in will simply be returned.
  #   link = page.find '//a'
  #   (page.find link) is link
  #   # => true
  #
  # Returns a tainted Node.
  # Raises DocumentMismatchError given a node not belonging to this page.
  find: (xpathOrNode, scope) ->
    if xpathOrNode?.nodeType
      DocumentMismatchError.assert @, xpathOrNode
      return xpathOrNode

    xpath = Pathway.from(xpathOrNode)
    return xpath.first(@document, scope)

  # Public: Finds an Element by id.
  #
  # id - A String matching a page element's id attribute.
  #
  # Examples
  #
  #   page.click page.byId('next-button')
  #
  # Returns a tainted Element or null if no matching Element was found.
  byId: (id) ->
    privacy.taint @document.getElementById(privacy.untaint id)

  # Public: Finds a matching anchor on this page.
  #
  # matcher - If a String, matches links whose id or href matches exactly
  #           or whose text content contains matcher.
  #           If a Function, it will be called with each link on the page
  #           until it returns true, which will cause that link to match.
  # scope - An Element to restrict the link search to.
  #
  # Examples
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
  # Returns an HTMLAnchorElement matching matcher and contained by scope, or null
  # if no link on the page matches.
  link: (matcher, scope) ->
    matcher = privacy.untaint matcher

    if type.isString matcher
      escaped = matcher.replace /"/, '\\"'
      @find """//a[@id="#{escaped}" or @href="#{escaped}" or contains(string(.), "#{escaped}")]""", scope

    else if type.isFunction matcher
      for link in @select '//a', scope
        return link if matcher link

      return null

  # Public: Finds matching nodes on the page. This is much like find(), but returns
  # all matching nodes instead of a single node.
  #
  # xpathOrNode - If it's a Node, returns it wrapped in an Array.
  #               Otherwise it should be a String xpath.
  # scope - An Element to restrict the search to.
  #
  # Examples
  #
  #   # finds all links on the page
  #   page.select '//a'
  #
  #   # gets a string containing all the text strings in the <body>
  #   (page.select '//text()', page.body).join('')
  #
  # Returns an Array of tainted Nodes found by xpath.
  # Raises DocumentMismatchError given a node not belonging to this page.
  select: (xpathOrNode, scope) ->
    if xpathOrNode?.nodeType
      DocumentMismatchError.assert @, xpathOrNode
      return [xpathOrNode]

    xpath = Pathway.from(xpathOrNode)
    return xpath.select @document, scope and @find(scope)

  # Public: Finds the first matching node, throwing an error
  # if there is no such matching node. Use this when you want to blow up
  # when the node cannot be found.
  #
  # xpathOrNode - If it's a Node, just returns it. Otherwise it should
  #               be a String xpath.
  # scope - An Element to restrict the xpath search to, ignored if xpathOrNode
  #         is a Node.
  #
  # Examples
  #
  #   # raises NodeNotFoundError because the xpath condition can never be satisfied
  #   page.findStrict '//*[@id!=@id]'
  #
  #   # just like page.find() when there's at least one link on the page
  #   link = page.findStrict '//a'
  #
  # Returns a tainted Node.
  # Raises DocumentMismatchError given a node not belonging to this page.
  # Raises NodeNotFoundError given an xpath for which there are no matches.
  findStrict: (xpathOrNode, scope) ->
    if result = @find xpathOrNode, scope
      return result

    NodeNotFoundError.raise @, xpathOrNode

  # Public: Fills an element with a given value. Note that the value will
  # be truncated according to any maxlength property found on the Element.
  #
  # xpathOrNode - If it's an Element, uses it as the Element to fill.
  #               Otherwise it should be a String xpath.
  # valueOrXpathOrNode - If it's a String, the value to use when filling
  #                      the Element. Otherwise it should be an Element
  #                      whose value we use to fill the Element.
  #
  # Examples
  #
  #   # fill in the search field
  #   page.fill '//input[@name="q"]', "angry birds"
  #
  #   # select an option in a dropdown
  #   colorSelect = page.findStrict '//select[@name="color"]'
  #   page.fill colorSelect, colorSelect.options[1]
  #
  # Returns nothing.
  # Raises DocumentMismatchError given a node not belonging to this page.
  # Raises NodeNotFoundError given an xpath for which there are no matches.
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

      maxlength = element.getAttribute "maxlength"
      if value and maxlength
        maxlength = number.parse maxlength
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

  # Public: Clicks the given element by firing mousedown, click,
  # and mouseup events.
  #
  # xpathOrNode - If it's an Element, uses it as the Element to click.
  #               Otherwise it should be a String xpath.
  #
  # Examples
  #
  #   # clicks a logoff link
  #   page.click page.link("Log off")
  #
  # Returns nothing.
  # Raises DocumentMismatchError given a node not belonging to this page.
  # Raises NodeNotFoundError given an xpath for which there are no matches.
  click: (xpathOrNode) ->
    tryThrow 'Page.click', (log) =>
      element = @findStrict xpathOrNode
      log.info 'element=', element
      @fireEvent element, 'mousedown'
      @fireEvent element, 'click'
      @fireEvent element, 'mouseup'

  # Public: Checks an element.
  #
  # xpathOrNode - If it's an Element, uses it as the Element to check.
  #               Otherwise it should be a String xpath.
  #
  # Examples
  #
  #   # checks all checkboxes on a page
  #   page.check '//input[@type="checkbox"]'
  #
  # Returns nothing.
  # Raises DocumentMismatchError given a node not belonging to this page.
  # Raises NodeNotFoundError given an xpath for which there are no matches.
  check: (xpathOrNode) ->
    tryThrow 'Page.check', (log) =>
      element = @findStrict xpathOrNode
      log.info 'element=', element
      privacy.untaint(element).checked = true
      @fireEvent element, 'change'

  # Public: Unchecks an element.
  #
  # xpathOrNode - If it's an Element, uses it as the Element to uncheck.
  #               Otherwise it should be a String xpath.
  #
  # Examples
  #
  #   # unchecks all checkboxes on a page
  #   page.uncheck '//input[@type="checkbox"]'
  #
  # Returns nothing.
  # Raises DocumentMismatchError given a node not belonging to this page.
  # Raises NodeNotFoundError given an xpath for which there are no matches.
  uncheck: (xpathOrNode) ->
    tryThrow 'Page.uncheck', (log) =>
      element = @findStrict xpathOrNode
      log.info('element=', element)
      privacy.untaint(element).checked = false
      @fireEvent element, 'change'

  # Public: Simulates submitting a form.
  #
  # xpathOrNode - If it's an HTMLFormElement, uses it as the HTMLFormElement to submit.
  #               If it's any other Element, searches through its ancestors to find an HTMLFormElement.
  #               Otherwise it should be a String xpath.
  #
  # Examples
  #
  #   # submits a form by name
  #   page.submit '//form[@name="quickreplyform"]'
  #
  #   # submits the form containing the search field
  #   page.submit '//input[@name="q"]'
  #
  # Returns nothing.
  # Raises DocumentMismatchError given a node not belonging to this page.
  # Raises NodeNotFoundError given an xpath for which there are no matches.
  submit: (xpathOrNode) ->
    tryThrow 'Page.submit', (log) =>
      element = @findStrict xpathOrNode
      log.info 'element=', element
      # find the containing form
      element = privacy.untaint element
      element = element.parentNode while element and element.tagName.toLowerCase() isnt 'form'

      unless element
        MissingFormError.raise @, xpathOrNode

      @fireEvent element, 'submit'

  # Internal: Fires an event on the given node/xpath endpoint.
  #
  # xpathOrNode - If it's an Element, uses it as the event's target Element.
  #               Otherwise it should be a String xpath.
  # type - The name of the event to fire (e.g. 'click').
  #
  # Examples
  #
  #   # fire the keypress event with the letter 'a'
  #   @fireEvent input, 'keypress', charCode: 'a'
  #
  # Returns nothing.
  # Raises DocumentMismatchError given a node not belonging to this page.
  # Raises NodeNotFoundError given an xpath for which there are no matches.
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

  # Public: Determines whether a node is visible.
  #
  # xpathOrNode - If it's a Node, uses it as the Node to check for visibility.
  #               Otherwise it should be a String xpath.
  #
  # Examples
  #
  #   page.visible '//imnotonthispage'
  #   # => false
  #
  #   page.visible '//div[contains(@style, "display:none")]'
  #   # => false
  #
  #   page.visible '//body'
  #   # => true
  #
  #   page.visible '//div[@class="this-class-hides-things"]//a'
  #   # => false
  #
  # Returns a Boolean indicating whether the Node is visible.
  # Raises DocumentMismatchError given a node not belonging to this page.
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

  # Pubilc: Determines whether a node is present.
  #
  # xpathOrNode - If it's a Node, it's automatically present.
  #               Otherwise it should be a String xpath.
  #
  # Returns a Boolean indicating whether the Node is present.
  # Raises DocumentMismatchError given a node not belonging to this page.
  present: (xpathOrNode, scope) ->
    !!(@find xpathOrNode, scope)

  # Public: Generates a percentage match between the page and the xpaths based on
  # how many of the elements are present on the page.
  #
  # xpaths - An Array of xpaths to search for.
  #
  # Returns a Number between 0 and 1 representing a percentage match.
  match: (xpaths) ->
    match = 0
    for xpath in xpaths
      xpath = Pathway.from xpath
      match++ if @present xpath

    return match / xpaths.length

  # Public: Gets all the cells associated with the given node. For a <th> or <td> node,
  # that's all the <td> elements in the same column. For a <tr> node, that's
  # all the <td> elements in the same row.
  #
  # xpathOrNode - The <td>, <tr> or xpath String to use.
  #
  # Returns an Array of HTMLTableCellElements in the row given by a <tr> or in the column
  # given by a <td> or <th>.
  # Raises DocumentMismatchError given a node not belonging to this page.
  # Raises NodeNotFoundError given an xpath for which there are no matches.
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

  # Public: Finds the next matching sibling.
  #
  # xpathOrNode - The Element whose next sibling to get or a String
  #               xpath to locate said element.
  # siblingMatcher - An xpath expression to use to match the next sibling (default: '*').
  #
  # Returns an Element, tainted.
  # Raises DocumentMismatchError given a node not belonging to this page.
  # Raises NodeNotFoundError given an xpath for which there are no matches.
  next: (xpathOrNode, siblingMatcher='*') ->
    @find "following-sibling::#{siblingMatcher}", @findStrict(xpathOrNode)

  # Public: Gets the text content of the Node.
  #
  # xpathOrNode - If it's a Node, retrieve all its text.
  #               Otherwise it should be a String xpath.
  #
  # Returns a String containing all Node's text, tainted.
  # Raises DocumentMismatchError given a node not belonging to this page.
  # Raises NodeNotFoundError given an xpath for which there are no matches.
  text: (xpathOrNode) ->
    node = @findStrict xpathOrNode
    if node.nodeType is 3
      textNodes = [node]
    else
      textNodes = @select './/text()', node
    privacy.taint (privacy.untaint(node.nodeValue) for node in textNodes).join('')

  # Public: Determines whether an Element has a given class.
  #
  # xpathOrNode - If it's an Element, use it to check the class.
  #               Otherwise it should be a String xpath.
  # className - The class to check the Element for.
  #
  # Examples
  #
  #   page.hasClass page.find('//div[@class="section"]'), 'section'
  #   # => true
  #
  #   page.hasClass page.find('//div[@class="section"]'), 'section'
  #   # => true
  #
  # Returns true if the Element has the given class.
  # Raises DocumentMismatchError given a node not belonging to this page.
  # Raises NodeNotFoundError given an xpath for which there are no matches.
  hasClass: (xpathOrNode, className) ->
    " #{@findStrict(xpathOrNode).className} ".indexOf(" #{className} ") > -1

  # Public: Goes back one step in the page's history.
  #
  # Returns nothing.
  back: ->
    @document.defaultView.history.back()

  # Public: Inject some javascript into a document by appending a script tag.
  #
  # script - JavaScript to be run in the page.
  #
  # Returns nothing.
  inject: (script) ->
    element = @document.createElementNS "http://www.w3.org/1999/xhtml", "script"
    element.setAttribute "type", "text/javascript"
    element.setAttribute "style", "display:none"
    element.innerHTML = script
    @document.documentElement.appendChild element

  # Public: Dumps the HTML and PNG representations of the page to the profile
  # under +%PROFILE_DIR%/wesabe-page-dumps+.
  #
  # Returns an Object whose html property is the path of the dumped HTML,
  # and whose png property is the path of the dumped PNG.
  dump: ->
    tryThrow 'Page.dump', =>
      Dir.profile.child('wesabe-page-dumps').create()

      html = folder.clone()
      png = folder.clone()
      basename = "#{new Date().getTime()}-#{@document.title.replace /[^-_a-zA-Z0-9 ]/g, ''}"
      html.append "#{basename}.html"
      png.append "#{basename}.png"

      logger.debug 'Dumping contents of current page to ', html.path, ' and ', png.path
      File.write html, "<html>#{@document.documentElement.innerHTML}</html>"
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

  # Public: This method replaces all words in text nodes with asterisks unless
  # the word is a dictionary word (defined in util/words),
  # then dumps the page as usual.
  #
  # Returns an Object whose html property is the path of the dumped HTML,
  # and whose png property is the path of the dumped PNG.
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

  # Internal: Returns alternate content for util/inspect to use when
  # generating a string representing this Page.
  #
  # Returns an Object.
  contentForInspect: ->
    url: @url, title: @title, name: @name

  # Public: Wraps documents in Pages.
  #
  # document - Either a Page or a Document to be wrapped.
  #
  # Returns document if document is a Page, otherwise returns a new Page wrapping document.
  @wrap: (document) ->
    if type.is document, @
      document
    else
      new @ document


module.exports = Page
