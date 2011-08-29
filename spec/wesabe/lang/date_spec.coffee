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

  describe '.add method', ->
    it 'adds a certain number of milliseconds', ->
      expect(date.add(new Date(2011, 6, 1, 0, 0, 0), 10*date.SECONDS).getSeconds()).toEqual(10)

  describe '.addDays method', ->
    it 'adds a certain number of days', ->
      expect(date.addDays(new Date(2011, 6, 1), 1)).toEqual(new Date(2011, 6, 2))

    it 'adds days to wrap the month', ->
      expect(date.addDays(new Date(2011, 6, 30), 2)).toEqual(new Date(2011, 7, 1))

  describe '.addMonths method', ->
    it 'adds a certain number of months', ->
      expect(date.addMonths(new Date(2011, 6, 1), 1)).toEqual(new Date(2011, 7, 1))

    it 'adds months to wrap the year', ->
      expect(date.addMonths(new Date(2011, 6, 1), 6)).toEqual(new Date(2012, 0, 1))

    it 'adds negative months to wrap the year', ->
      expect(date.addMonths(new Date(2011, 0, 1), -15)).toEqual(new Date(2009, 9, 1))

  describe '.addYears method', ->
    it 'adds a certain number of years', ->
      expect(date.addYears(new Date(2011, 0, 1), 1)).toEqual(new Date(2012, 0, 1))
