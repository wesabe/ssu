string = require 'lang/string'

describe 'lang/string', ->
  describe '.trim function', ->
    it 'trims preceding whitespace', ->
      expect(string.trim(' \n\tabc')).toEqual('abc')

    it 'trims following whitespace', ->
      expect(string.trim('abc\n  \t ')).toEqual('abc')

    it 'trims both preceding and following whitespace at once', ->
      expect(string.trim('   abc\n\t ')).toEqual('abc')

  describe '.substring function', ->
    describe 'with positive offsets', ->
      it 'is the same as the String#substring function', ->
        expect(string.substring('abcdefg', 1, 3)).toEqual('abcdefg'.substring(1, 3))

    describe 'with negative offsets', ->
      it 'uses offset from the end of the string', ->
        expect(string.substring('abcdefg', -3, -1)).toEqual('ef')

