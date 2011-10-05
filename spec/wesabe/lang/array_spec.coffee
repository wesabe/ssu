array = require 'lang/array'

describe 'lang/array', ->
  simpleArray = null
  arrayWithUniqueEntries = null
  arrayWithDuplicates = null
  arrayWithDuplicatesRemoved = null
  arrayWithArrayEntries = null
  arrayWithFalsyEntries = null

  beforeEach ->
    simpleArray = [1, 2, 3]
    arrayWithUniqueEntries     = ['a', 'b', 'c']
    arrayWithDuplicates        = ['a', 'b', 'a', 'c']
    arrayWithDuplicatesRemoved = ['a', 'b', 'c']
    arrayWithArrayEntries      = [[], simpleArray]
    arrayWithFalsyEntries      = [null, undefined, 0, '', NaN]

  describe '.from function', ->
    it 'returns an array with the same entries as the original', ->
      expect(array.equal(array.from(simpleArray), simpleArray)).toBeTruthy()

    it 'returns a non-identical array', ->
      expect(array.from(simpleArray)).not.toBe(simpleArray)

    it 'copies function arguments', ->
      makeArray = (args...) -> array.from(args)
      expect(array.equal(makeArray(1, 2, 3), simpleArray)).toBeTruthy()

  describe '.uniq function', ->
    it 'does not alter an already-uniq array', ->
      expect(array.uniq(arrayWithUniqueEntries)).toEqual(arrayWithUniqueEntries)

    it 'preserves the first copy of duplicate values in the array', ->
      expect(array.uniq(arrayWithDuplicates)).toEqual(arrayWithDuplicatesRemoved)

  describe '.include function', ->
    it 'returns true if the array contains an identical entry', ->
      expect(array.include(simpleArray, 1)).toBeTruthy()
      expect(array.include(arrayWithArrayEntries, simpleArray)).toBeTruthy()

    it 'returns false if the array does not contain an identical entry', ->
      expect(array.include(simpleArray, 4)).toBeFalsy()
      expect(array.include(arrayWithArrayEntries, [])).toBeFalsy()

  describe '.compact function', ->
    it 'does not alter arrays with all truthy entries', ->
      expect(array.equal(array.compact(simpleArray), simpleArray)).toBeTruthy()
      expect(array.equal(array.compact(arrayWithArrayEntries), arrayWithArrayEntries)).toBeTruthy()

    it 'strips falsy entries', ->
      expect(array.compact(arrayWithFalsyEntries)).toEqual([])

  describe '.equal function', ->
    it 'returns false if the two arrays have different lengths', ->
      expect(array.equal(arrayWithDuplicates, arrayWithDuplicatesRemoved)).toBeFalsy()

    it 'returns false if the two arrays have the same length but different contents', ->
      expect(array.equal(simpleArray, arrayWithUniqueEntries)).toBeFalsy()

    it 'returns true if the two arrays are identical', ->
      expect(array.equal(simpleArray, simpleArray)).toBeTruthy()

    it 'returns true if the two arrays are the same length and have the same contents', ->
      expect(array.equal(array.from(simpleArray), simpleArray)).toBeTruthy()

  describe '.zip function', ->
    it 'returns an array of arrays where each entry has the original values of the arrays at that index', ->
      expect(array.zip(simpleArray, arrayWithUniqueEntries)).toEqual([[1, 'a'], [2, 'b'], [3, 'c']])

    it 'populates the extra spaces with undefined if the arrays are of unequal length', ->
      expect(array.zip([1], [2, 3])).toEqual([[1, 2], [undefined, 3]])
