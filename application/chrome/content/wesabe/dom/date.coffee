{parse, format, MONTH_NAMES} = require 'lang/date'
number = require 'lang/number'

forElement = (element, format) ->
  if wesabe.untaint(element).tagName.toLowerCase() is 'input'
    new TextInput element, format
  else
    new SelectGroup element


class TextInput
  constructor: (element, @format) ->
    @element = wesabe.untaint element

  @::__defineGetter__ 'date', ->
    parse @element.value

  @::__defineSetter__ 'date', (date) ->
    @element.value = format date, @format


class SelectGroup
  constructor: (container) ->
    @container = wesabe.untaint container
    @locateYearSelect()
    @locateMonthSelect()
    @locateDaySelect()

  @::__defineGetter__ 'date', ->
    new Date @year, @month, @day

  @::__defineSetter__ 'date', (date) ->
    @year = date.getFullYear()
    @month = date.getMonth()
    @day = date.getDate()

  @::__defineGetter__ 'year', ->
     number.parse(@yearSelect.value) if @yearSelect

  @::__defineSetter__ 'year', (year) ->
    @yearSelect.value = year.toString() if @yearSelect

  @::__defineGetter__ 'month', ->
    number.parse(@monthSelect.value) if @monthSelect

  @::__defineSetter__ 'month', (month) ->
    @monthSelect.value = month.toString() if @monthSelect

  @::__defineGetter__ 'day', ->
    number.parse(@daySelect.value) if @daySelect

  @::__defineSetter__ 'day', (day) ->
    @daySelect.value = day.toString() if @daySelect

  locateYearSelect: ->
    # assume that one of the values is the current year
    thisYear = new Date().getFullYear()
    xpath = Pathway.bind('.//select[.//option[contains(string(.), ":year")]]', year: thisYear)
    @yearSelect = wesabe.untaint Page.wrap(@container.ownerDocument).find(xpath, @container)

    wesabe.warn "Unable to find a <select> element containing years" unless @yearSelect

  locateMonthSelect: ->
    for month in MONTH_NAMES
      xpath = Pathway.bind('.//select[.//option[contains(string(.), ":month")]]', month: month)
      @monthSelect = wesabe.untaint Page.wrap(@container.ownerDocument).find(xpath, @container)

      return if @monthSelect

    wesabe.warn "Unable to find a <select> element containing months"

  locateDaySelect: ->
    for select in wesabe.untaint Page.wrap(@container.ownerDocument).select('.//select', @container)
      return @daySelect = select if select.options.length >= 30

    wesabe.warn "Unable to find a <select> element containing days"


module.exports = {forElement}
