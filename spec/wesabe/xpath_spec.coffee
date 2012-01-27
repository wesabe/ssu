xpath = require 'xpath'

describe 'xpath.Pathway', ->
  it 'converts the XPath 2.0 function upper-case() into the XPath 1.0 function translate()', ->
    expect((new xpath.Pathway "//*[upper-case(name())=\"INPUT\"]").value).toEqual("//*[translate(name(), \"abcdefghijklmnopqrstuvwxyz\", \"ABCDEFGHIJKLMNOPQRSTUVWXYZ\")=\"INPUT\"]")

  it 'converts the XPath 2.0 function lower-case() into the XPath 1.0 function translate()', ->
    expect((new xpath.Pathway "//*[lower-case(name())=\"input\"]").value).toEqual("//*[translate(name(), \"ABCDEFGHIJKLMNOPQRSTUVWXYZ\", \"abcdefghijklmnopqrstuvwxyz\")=\"input\"]")
    expect((new xpath.Pathway "//input[lower-case(@type)=\"submit\"]").value).toEqual("//input[translate(@type, \"ABCDEFGHIJKLMNOPQRSTUVWXYZ\", \"abcdefghijklmnopqrstuvwxyz\")=\"submit\"]")
    
  it 'can combine upper-case() and lower-case()', ->
    expect((new xpath.Pathway "//*[upper-case(lower-case(name()))=\"INPUT\"]").value).toEqual("//*[translate(translate(name(), \"ABCDEFGHIJKLMNOPQRSTUVWXYZ\", \"abcdefghijklmnopqrstuvwxyz\"), \"abcdefghijklmnopqrstuvwxyz\", \"ABCDEFGHIJKLMNOPQRSTUVWXYZ\")=\"INPUT\"]")
    
  it 'adds a has-class() function', ->
    expect((new xpath.Pathway "//span[has-class(\"error\")]").value).toEqual("//span[contains(concat(\" \", @class, \" \"), \" error \")]")