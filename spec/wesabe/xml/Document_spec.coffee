Document = wesabe.require 'xml.Document'

describe 'wesabe.xml.Document', ->
  it 'throws an exception on a blank XML string', ->
    try
      new Document('')
      throw new Error("constructor failed to throw an exception")
    catch err
      expect(err.message).toMatch(/Unexpected EOF/)

  it 'parses self-closing elements', ->
    root = new Document('<root/>').documentElement
    expect(root.tagName).toEqual('root')
    expect(root.childNodes.length).toBe(0)

  it 'parses nested elements', ->
    root = new Document('<root><child></child></root>').documentElement
    expect(root.firstChild.tagName).toBe('child')
    expect(root.childNodes.length).toBe(1)

  it 'parses attributes', ->
    root = new Document('<a href="/search?q=test">Test Search</a>').documentElement
    expect(root.getAttribute('href')).toBe('/search?q=test')
    expect(root.attributes.length).toBe(1)
    attr = root.attributes[0]
    expect(attr.nodeName).toBe('href')
    expect(attr.nodeValue).toBe('/search?q=test')
