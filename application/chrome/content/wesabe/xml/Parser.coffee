wesabe.provide('xml.Parser')
wesabe.require('xml.*')

class wesabe.xml.Parser
  parse: (xml, verboten) ->
    parser = @parser = new wesabe.util.Parser()

    wesabe.util.event.forward(parser, this)

    work = @work =
      el: null

      setEl: (el) ->
        if el && (el != @el)
          el.parsed = false
          el.offset = parser.offset - 1 # <
          work.nodes.push(el)
          el.beginParsing(parser)
        else if !el && @el
          oel = @el
          oel.doneParsing(parser)

          if verboten && oel && wesabe.is(oel, wesabe.xml.OpenTag) && verboten.test(oel.name)
            return unless parser

            etag = "</#{@el.name}>"
            offset = parser.parsing.indexOf(etag, parser.offset)
            if offset >= parser.offset
              parser.offset = offset-1
            else
              throw new Error("Could not skip to #{etag} because it is not present after offset #{parser.offset}")

        @el = el;

      attr: null
      setAttr: (attr) ->
        if attr && (attr != @attr)
          attr.parsed = false
          attr.offset = parser.offset
          @nodes.push(attr)
          attr.beginParsing(parser)
        else if !attr && @attr
          @attr.doneParsing(parser)

        @attr = attr

      text: null
      setText: (text) ->
        if text && (text != @text)
          @nodes.push(text)
          text.beginParsing(parser)
        else if !text && @text
          @text.doneParsing(parser)

        @text = text

      nodes: []

    # handles element nodes
    el =
      # <
      start: ->
        parser.tokens =
          '[a-zA-Z]': el.opening
          '/': el.closing

      # first letter
      opening: (p) ->
        work.setEl(new wesabe.xml.OpenTag())
        el.name(p)

      # subsequent characters
      name: (p) ->
        work.el.name += p
        parser.tokens =
          '[-_\.a-zA-Z0-9:]': el.name
          '\\s': attr.prename
          '>': el.end
          '/': el.selfclosing

      # self-closing /
      selfclosing: ->
        work.el.selfclosing = true
        parser.tokens =
          '>': el.end

      # </
      closing: ->
        work.setEl(new wesabe.xml.CloseTag())
        parser.tokens =
          '[a-zA-Z]': el.name

      # >
      end: ->
        work.setEl(null)
        parser.tokens =
          '<': el.start
          '[^<]': text.start
          EOF: noop

    attr =
      # \s before attribute name
      prename: ->
        parser.tokens =
          '[a-zA-Z]': attr.start
          '\\s': attr.prename
          '>': attr.end

      # first [a-zA-Z]
      start: (p) ->
        work.setAttr(new wesabe.xml.Attribute())
        attr.name(p)

      # subsequent [a-zA-Z]
      name: (p) ->
        work.attr.name += p
        parser.tokens =
          '[a-zA-Z:]': attr.name
          '\\s': attr.postname
          '=': attr.prevalue

      # \s after attribute name
      postname: ->
        parser.tokens =
          '\\s': attr.postname
          '=': attr.prevalue

      # [=\s] before value
      prevalue: ->
        parser.tokens =
          '[a-zA-Z]': attr.value
          '\\s': attr.prevalue
          '[\'"]': attr.prequote

      # ['"] before value
      prequote: (p) ->
        work.attr.quote = p
        attr.value()

      # anything but work.attr.quote
      value: (p) ->
        work.attr.quote ||= '\\s'
        toks =
          '>': attr.end
        toks[work.attr.quote] = attr.postquote
        toks["[^#{work.attr.quote}]"] = attr.value
        parser.tokens = toks
        work.attr.value += p if p

      # work.attr.quote
      postquote: (p) ->
        attr.end()
        if /\s/.test(p)
          attr.prename()
        else
          parser.tokens =
            '>': el.end,
            '\\s': attr.prename
            '/': el.selfclosing

      # > or work.attr.quote
      end: (p) ->
        work.setAttr(null)
        el.end() if p == '>'

    # handles text nodes
    text =
      # first [^<]
      start: (p) ->
        work.setText(new wesabe.xml.Text(p))
        parser.tokens =
          '<': text.end
          '[^<]': text.text
          EOF: quit

      # subsequent [^<]
      text: (p) ->
        work.text.text += p

      # <
      end: ->
        work.setText(null)
        el.start()

    # do nothing
    noop = ->
    # stop parsing
    quit = -> false

    # initial parse setup
    parser.tokens =
      '<': el.start
      '\\s': noop

    wesabe.tryThrow 'xml.Parser', (log) =>
      parser.parse(xml)
      delete self.parser
      delete self.work
      return work.nodes

  stop: ->
    @parser?.stop()
