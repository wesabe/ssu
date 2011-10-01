{parse, format, MONTH_NAMES} = require 'lang/date'
number  = require 'lang/number'
privacy = require 'util/privacy'

forElement = (element, format) ->
  if privacy.untaint(element).tagName.toLowerCase() is 'input'
    new TextInput element, format
  else
    new SelectGroup element


class TextInput
  constructor: (element, @format) ->
    @element = privacy.untaint element

  @::__defineGetter__ 'date', ->
    parse @element.value

  @::__defineSetter__ 'date', (date) ->
    @element.value = format date, @format


class SelectGroup
  constructor: (container) ->
    @container = privacy.untaint container
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
    @yearSelect = privacy.untaint Page.wrap(@container.ownerDocument).find(xpath, @container)

    logger.warn "Unable to find a <select> element containing years" unless @yearSelect

  locateMonthSelect: ->
    for month in MONTH_NAMES
      xpath = Pathway.bind('.//select[.//option[contains(string(.), ":month")]]', month: month)
      @monthSelect = privacy.untaint Page.wrap(@container.ownerDocument).find(xpath, @container)

      return if @monthSelect

    logger.warn "Unable to find a <select> element containing months"

  locateDaySelect: ->
    for select in privacy.untaint Page.wrap(@container.ownerDocument).select('.//select', @container)
      return @daySelect = select if select.options.length >= 30

    logger.warn "Unable to find a <select> element containing days"


module.exports = {forElement}
