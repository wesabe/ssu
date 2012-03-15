class MimeType
  constructor: (@type, @aliases=[], @extensions=[]) ->
    if arguments.length is 2
      @extensions = @aliases
      @aliases = []

  match: (identifier) ->
    @isGlobal or
    identifier is @type or
      identifier in @aliases or
      identifier in @extensions

  @::__defineGetter__ 'isGlobal', ->
    @type is '*/*'

class MimeTypes
  constructor: ->
    @types = []

  add: (mimeTypes...) ->
    for mimeType in mimeTypes
      if not mimeType instanceof MimeType
        mimeType = new MimeType mimeType.type, mimeType.aliases, mimeType.extensions
      @types.push mimeType

  search: (identifier) ->
    for type in @types
      return type if type.match identifier

    new MimeType identifier

  byExtension: (ext) ->
    for type in @types
      return type if ext in type.extensions

    return null

MIME_TYPES = new MimeTypes
MIME_TYPES.JSON = new MimeType(
  'application/json',
  ['application/x-json', 'text/json'],
  ['json']
)

MIME_TYPES.HTML = new MimeType(
  'text/html',
  ['html', 'shtml', 'htm']
)

MIME_TYPES.TEXT = new MimeType(
  'text/plain',
  ['txt']
)

MIME_TYPES.XML = new MimeType(
  'application/xml',
  ['text/xml'],
  ['xml']
)

MIME_TYPES.YAML = new MimeType(
  'application/x-yaml',
  ['text/yaml'],
  ['yml', 'yaml']
)

MIME_TYPES.add MIME_TYPES.JSON, MIME_TYPES.TEXT, MIME_TYPES.XML, MIME_TYPES.YAML
module.exports = MIME_TYPES
