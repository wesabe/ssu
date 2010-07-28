wesabe.require('lang.date');

wesabe.provide('dom.date', {
  TextInput: function(element, format) {
    this.element = wesabe.untaint(element);
    this.format  = format;
  },

  SelectGroup: function(container) {
    this.container = wesabe.untaint(container);
    this.locateYearSelect();
    this.locateMonthSelect();
    this.locateDaySelect();
  },

  forElement: function(element, format) {
    if (wesabe.untaint(element).tagName.toLowerCase() == 'input')
      return new wesabe.dom.date.TextInput(element, format);
    else
      return new wesabe.dom.date.SelectGroup(element);
  },
});

wesabe.dom.date.TextInput.prototype = {
  get date() {
    return wesabe.lang.date.parse(this.element.value);
  },

  set date(date) {
    this.element.value = wesabe.lang.date.format(date, this.format);
  },
};

wesabe.dom.date.SelectGroup.prototype = {
  get date() {
    return new Date(this.year, this.month, this.day);
  },

  set date(date) {
    this.year = date.getFullYear();
    this.month = date.getMonth();
    this.day = date.getDate();
  },

  get year() {
    return this.yearSelect && parseInt(this.yearSelect.value, 10);
  },

  set year(year) {
    if (this.yearSelect) this.yearSelect.value = year.toString();
  },

  get month() {
    return this.monthSelect && parseInt(this.monthSelect.value, 10);
  },

  set month(month) {
    if (this.monthSelect) this.monthSelect.value = month.toString();
  },

  get day() {
    return this.daySelect && parseInt(this.daySelect.value, 10);
  },

  set day(day) {
    if (this.daySelect) this.daySelect.value = day.toString();
  },

  locateYearSelect: function() {
    // assume that one of the values is the current year
    var year = new Date().getFullYear();
    this.yearSelect = wesabe.untaint(wesabe.dom.page.find(
      this.container.ownerDocument,
      wesabe.xpath.bind('.//select[.//option[contains(string(.), ":year")]]', {year: year}),
      this.container));

    if (!this.yearSelect) wesabe.warn("Unable to find a <select> element containing years");
  },

  locateMonthSelect: function() {
    var months = wesabe.lang.date.MONTH_NAMES;

    for (var i = 0; i < months.length; i++) {
      this.monthSelect = wesabe.untaint(wesabe.dom.page.find(
        this.container.ownerDocument,
        wesabe.xpath.bind('.//select[.//option[contains(string(.), ":month")]]', {month: months[i]}),
        this.container));

      if (this.monthSelect) return;
    }

    wesabe.warn("Unable to find a <select> element containing months");
  },

  locateDaySelect: function() {
    var selects = wesabe.untaint(wesabe.dom.page.select(this.container.ownerDocument, './/select', this.container));

    for (var i = 0; i < selects.length; i++) {
      if (selects[i].options.length >= 30) {
        return this.daySelect = selects[i];
      }
    }

    wesabe.warn("Unable to find a <select> element containing days");
  },
};
