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
    line = script.content.split('\n')[lineNumber-1]

    {filename, lineNumber, line}


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
