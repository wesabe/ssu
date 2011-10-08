File = require 'io/File'
Dir  = require 'io/Dir'

describe 'io/File', ->
  it 'wraps a path to a specific file', ->
    expect((new File 'test.txt').path).toBe 'test.txt'

  it 'accurrately reports files that do not exist', ->
    expect((new File 'idonotexist.nope').exists).toBe false

  it 'accurrately reports files that do exist', ->
    expect((new File __filename).exists).toBe true

  it 'is able to synchronously read the file contents', ->
    expect((new File __filename).read()).toMatch /^File = require 'io\/File'/

  it 'is able to get the basename of a file', ->
    expect((new File __filename).basename).toBe 'file_spec.coffee'

  it 'is able to get the parent of a file', ->
    expect((new File __filename).parent.path).toBe __dirname

  it 'has a class method for reading files', ->
    expect((new File __filename).read()).toBe File.read(__filename)

  it 'can create a file without writing anything to it', ->
    file = @tmpfile()

    expect(file.exists).toBe false
    expect(file.create()).toBe true
    expect(file.exists).toBe true

  beforeEach ->
    i = 0
    @cleanup = []
    @tmpfile = ->
      file = Dir.tmp.child("#{File.basename(__filename)}-#{i}").asFile
      @cleanup.push file
      return file

  afterEach ->
    file.unlink() for file in @cleanup

