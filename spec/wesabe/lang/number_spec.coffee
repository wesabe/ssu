number = require 'lang/number'

describe 'lang/number', ->
  describe '.parseOrdinalPhrase function', ->
    it 'works with nth', ->
      expect(number.parseOrdinalPhrase('the 145th item')).toEqual(145)

    it 'works with nst', ->
      expect(number.parseOrdinalPhrase('1st prize!')).toEqual(1)

    it 'works with nrd', ->
      expect(number.parseOrdinalPhrase('Ranked 1,283rd in Entertainment')).toEqual(1283)

    it 'works with ordinal words', ->
      expect(number.parseOrdinalPhrase('safety first')).toEqual(1)
      expect(number.parseOrdinalPhrase('second string')).toEqual(2)
      expect(number.parseOrdinalPhrase('third rate')).toEqual(3)
      expect(number.parseOrdinalPhrase('fourth floor')).toEqual(4)
      expect(number.parseOrdinalPhrase('fifth element')).toEqual(5)
      expect(number.parseOrdinalPhrase('sixth avenue')).toEqual(6)
      expect(number.parseOrdinalPhrase('seventh generation')).toEqual(7)
      expect(number.parseOrdinalPhrase('eighth leg')).toEqual(8)
      expect(number.parseOrdinalPhrase('ninth symphony')).toEqual(9)
      expect(number.parseOrdinalPhrase('tenth amendment')).toEqual(10)

    it 'treats "last" as 0', ->
      expect(number.parseOrdinalPhrase('the last samurai')).toEqual(0)

    it 'parses nth from last/from the end as a negative number', ->
      expect(number.parseOrdinalPhrase('20th from last')).toEqual(-20)
      expect(number.parseOrdinalPhrase('second from the end')).toEqual(-2)

  describe '.parse function', ->
    it 'works with untainted numeric strings', ->
      expect(number.parse('12')).toEqual(12)

    it 'works with tainted numeric strings', ->
      expect(number.parse(wesabe.taint('12'))).toEqual(12)

    it 'returns NaN for non-numeric strings', ->
      for string in ['', 'hey there', '!!0']
        expect(isNaN(number.parse(string))).toBeTruthy()
