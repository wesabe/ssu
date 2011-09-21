@onerror = (error) ->
  dump "unhandled error: #{error}\n"

getContent = (uri) ->
  xhr = new XMLHttpRequest()

  xhr.open 'GET', uri, false
  try
    xhr.send null
  catch e
    # uh oh, 404?
    return null

  if xhr.status in [0, 200]
    xhr.responseText
  else
    null

indentCount = (line) ->
  indent = 0
  indent++ while line.indexOf(('  ' for i in [0..indent]).join('')) == 0
  indent

functionNameForLine = (line) ->
  # foo: function(...)
  if match = line.match(/([_a-zA-Z]\w*)\s*:\s*(?:__bind\()?function\s*\(/)
    match[1]

  # function foo(...)
  else if match = line.match(/function\s*([_a-zA-Z]\w*)\s*\([\)]*/)
    match[1]

  # foo = function(...)
  else if match = line.match(/(\w+)\s*=\s*(?:__bind\()?function\b/)
    match[1]

  # Bar.prototype.foo = function(...)
  else if match = line.match(/\w+\.([_a-zA-Z]\w*)\s*=\s*(?:__bind\()?function/)
    match[1]

  # get foo() / set foo(value)
  else if match = line.match(/((?:get|set)\s+[_a-zA-Z]\w*)\(\)/)
    match[1]

  # __defineGetter__('foo', function() / __defineSetter__('foo', function(...)
  else if match = line.match(/__define([GS]et)ter__\(['"]([_a-zA-Z]\w*)['"],\s*function/)
    "#{match[1].toLowerCase()} #{match[2]}"

bootstrap =
  loadedScripts: []

  info: null
  uri: 'bootstrap.js'
  evalOffset: null
  currentOffset: null

  load: (uri, scope={}) ->
    content = getContent uri
    content = CoffeeScript.compile(content) if uri.match /\.coffee$/
    lines = content.split('\n').length
    offset = @currentOffset
    padding = new Array(offset-@evalOffset+1).join('\n')

    @loadedScripts.push {uri, content, offset, lines}
    @currentOffset += lines

    (-> `with (scope) { eval(padding+content) }`; null ).call(window) # JS version won't have "CoffeeScript" on the same line

  infoForEvaledLineNumber: (lineNumber) ->
    script = @info

    for s in @loadedScripts
      if s.offset <= lineNumber - 1 < s.offset + s.lines
        script = s
        break

    filename = script.uri
    lineNumber = lineNumber - script.offset
    lines = script.content.split('\n')
    line = lines[lineNumber-1]
    name = functionNameForLine line

    if not name and line
      indentOfLine = indentCount line
      minimumIndent = indentOfLine
      lineNumberToCheck = lineNumber-2
      while lineNumberToCheck >= 0
        lineToCheck = lines[lineNumberToCheck]
        indentOfLineToCheck = indentCount lineToCheck

        if indentOfLineToCheck < minimumIndent
          minimumIndent = indentOfLineToCheck

          if name = functionNameForLine lineToCheck
            break

        lineNumberToCheck--

      name ||= if indentOfLine is 1 then '(top)' else '(anonymous)'

    {filename, lineNumber, line, name}


do ->
  lines = (getContent bootstrap.uri).split('\n')

  for line, i in lines
    if line.match(/\beval\(/) and not line.match(/CoffeeScript/)
      bootstrap.evalOffset = i
      break

  bootstrap.currentOffset = lines.length
  bootstrap.info =
    uri: bootstrap.uri
    content: lines.join('\n')
    offset: 0
    lines: lines.length


do ->
  scripts = document.getElementsByTagName 'script'
  for s in scripts when s.getAttribute('type') is 'text/coffeescript'
    if src = s.getAttribute('src')
      bootstrap.load src


@bootstrap = bootstrap
