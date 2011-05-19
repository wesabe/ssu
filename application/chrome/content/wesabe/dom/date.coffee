wesabe.require('lang.date')

wesabe.provide 'dom.date',
  forElement: (element, format) ->
    if wesabe.untaint(element).tagName.toLowerCase() == 'input'
      new @TextInput(element, format);
    else
      new @SelectGroup(element);


class wesabe.dom.date.TextInput
  constructor: (element, format) ->
    @element = wesabe.untaint(element)
    @format  = format

  this::__defineGetter__ 'date', ->
    wesabe.lang.date.parse(@element.value)

  this::__defineSetter__ 'date', ->
    @element.value = wesabe.lang.date.format(date, @format)


class wesabe.dom.date.SelectGroup
  constructor: (container) ->
    @container = wesabe.untaint(container)
    @locateYearSelect()
    @locateMonthSelect()
    @locateDaySelect()

  this::__defineGetter__ 'date', ->
    new Date(@year, @month, @day)

  this::__defineSetter__ 'date', ->
    @year = date.getFullYear()
    @month = date.getMonth()
    @day = date.getDate()

  this::__defineGetter__ 'year', ->
    @yearSelect && parseInt(@yearSelect.value, 10)

  this::__defineSetter__ 'year', ->
    (@yearSelect.value = year.toString() if @yearSelect)

  this::__defineGetter__ 'month', ->
    @monthSelect && parseInt(@monthSelect.value, 10)

  this::__defineSetter__ 'month', ->
    (@monthSelect.value = month.toString() if @monthSelect)

  this::__defineGetter__ 'day', ->
    @daySelect && parseInt(@daySelect.value, 10)

  this::__defineSetter__ 'day', ->
    (@daySelect.value = day.toString() if @daySelect)

  locateYearSelect: ->
    # assume that one of the values is the current year
    thisYear = new Date().getFullYear()
    xpath = wesabe.xpath.bind('.//select[.//option[contains(string(.), ":year")]]', {year: thisYear})
    @yearSelect = wesabe.untaint(wesabe.dom.page.find(@container.ownerDocument, xpath, @container))

    wesabe.warn("Unable to find a <select> element containing years") unless @yearSelect

  locateMonthSelect: ->
    for month in wesabe.lang.date.MONTH_NAMES
      xpath = wesabe.xpath.bind('.//select[.//option[contains(string(.), ":month")]]', {month: month})
      @monthSelect = wesabe.untaint(wesabe.dom.page.find(@container.ownerDocument, xpath, @container))

      return if @monthSelect

    wesabe.warn("Unable to find a <select> element containing months")

  locateDaySelect: ->
    for select in wesabe.untaint(wesabe.dom.page.select(@container.ownerDocument, './/select', @container))
      return @daySelect = select if select.options.length >= 30

    wesabe.warn("Unable to find a <select> element containing days")
