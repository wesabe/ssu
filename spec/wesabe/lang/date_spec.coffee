date = wesabe.require 'lang.date'

describe 'wesabe.lang.date', ->
  describe '.parse method', ->
    it 'warns when the date is not parsable', ->
      spyOn(wesabe, 'warn')
      date.parse('omgwtfbbq')

      expect(wesabe.warn).toHaveBeenCalledWith('unable to parse date: ', 'omgwtfbbq')

    it 'returns null when the date is not parsable', ->
      expect(date.parse('omgwtfbbq')).toBeNull()

    it 'returns a date matching the input string', ->
      expect(date.parse('2000/4/19')).toEqual(new Date(2000, 3, 19))

    it 'parses dates in the format YYYY-MM-DD', ->
      expect(date.parse('2011-07-11')).toEqual(new Date(2011, 6, 11))

    it 'parses dates in the format MMM DD, YYYY', ->
      expect(date.parse('Jul 15, 2011')).toEqual(new Date(2011, 6, 15))
