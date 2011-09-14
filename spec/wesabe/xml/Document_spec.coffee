Document = wesabe.require 'xml.Document'
Text     = wesabe.require 'xml.Text'

describe 'wesabe.xml.Document', ->
  it 'throws an exception on a blank XML string', ->
    try
      new Document('')
      throw new Error("constructor failed to throw an exception")
    catch err
      expect(err.message).toMatch(/Unexpected EOF/)

  it 'parses self-closing elements', ->
    root = new Document('<root/>').documentElement
    expect(root.nodeName).toEqual('root')
    expect(root.childNodes.length).toBe(0)

  it 'parses nested elements', ->
    root = new Document('<root><child></child></root>').documentElement
    expect(root.firstChild.nodeName).toBe('child')
    expect(root.childNodes.length).toBe(1)

  it 'parses attributes', ->
    root = new Document('<a href="/search?q=test">Test Search</a>').documentElement
    expect(root.getAttribute('href')).toBe('/search?q=test')
    expect(root.attributes.length).toBe(1)
    attr = root.attributes[0]
    expect(attr.nodeName).toBe('href')
    expect(attr.nodeValue).toBe('/search?q=test')

  it 'parses text content', ->
    root = new Document('<a href="/">Home</a>').documentElement
    expect(root.firstChild.nodeValue).toBe('Home')

  it 'handles unclosed elements', ->
    root = new Document('<root>abc<child>def</root>').documentElement
    expect(root.childNodes.length).toBe(2)
    expect(root.firstChild instanceof Text).toBe(true)
    expect(root.lastChild.nodeName).toBe('child')
    expect(root.lastChild.text).toBe('def')
