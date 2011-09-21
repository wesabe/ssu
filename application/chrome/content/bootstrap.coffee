@onerror = (error) ->
  dump "unhandled error: #{error}\n"

Cc = Components.classes
Ci = Components.interfaces

getContent = (uri) ->
  liveFile = $file.open $dir.chrome.path + "/content/#{uri}"
  return null unless liveFile.exists()

  if m = uri.match /^(?:(.+)\/)?([^\/]+)\.coffee$/
    name = m[2]
    dir = m[1]

    {root} = $dir
    cache = $dir.mkpath root, "tmp/script-build-cache/#{dir or ''}"
    cache.append "#{name}.js"

    if cache.exists() and cache.lastModifiedTime >= liveFile.lastModifiedTime
      # up to date, read the cached file
      return $file.read cache
    else
      # out of date, rebuild cached file
      dump "\x1b[36m[compile]\x1b[0m #{uri}\n"
      content = CoffeeScript.compile $file.read(liveFile)
      $file.write cache, content
      return content

  $file.read liveFile

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

$file =
  open: (path) ->
    file = Cc['@mozilla.org/file/local;1'].createInstance(Ci.nsILocalFile)
    file.initWithPath(path)
    return file

  read: (file) ->
    if typeof file is 'string'
      path = file
      file = $file.open path
    else if file
      path = file.path

    fiStream = Cc['@mozilla.org/network/file-input-stream;1'].createInstance(Ci.nsIFileInputStream)
    siStream = Cc['@mozilla.org/scriptableinputstream;1'].createInstance(Ci.nsIScriptableInputStream)
    fiStream.init(file, 1, 0, false)
    siStream.init(fiStream)

    data = siStream.read(-1)
    siStream.close()
    fiStream.close()

    return data

  write: (file, data, mode) ->
    if typeof file is 'string'
      path = file
      file = $file.open path
    else if file
      path = file.path

    foStream = Cc['@mozilla.org/network/file-output-stream;1'].createInstance(Ci.nsIFileOutputStream)
    flags = if mode is 'a'
              0x02 | 0x10        # wronly | append
            else
              0x02 | 0x08 | 0x20 # wronly | create | truncate

    foStream.init(file, flags, 0664, 0)
    foStream.write(data, data.length)
    foStream.close()

    return true

$dir =
  create: (dir) ->
    dir = $file.open dir if typeof dir is 'string'
    dir.create 0x01, 0774

  mkpath: (root, path) ->
    for part in path.split /[\/\\]/
      root.append part
      $dir.create root unless root.exists()

    return root

$dir.__defineGetter__ 'chrome', ->
  Cc['@mozilla.org/file/directory_service;1']
    .createInstance(Ci.nsIProperties)
    .get('AChrom', Ci.nsIFile)

$dir.__defineGetter__ 'root', ->
  root = $file.open $dir.chrome.path + '/../../'
  root.normalize()
  return root


bootstrap =
  loadedScripts: []

  info: null
  uri: 'bootstrap.js'
  evalOffset: null
  currentOffset: null

  getContent: getContent

  load: (uri, scope={}) ->
    content = getContent uri
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
