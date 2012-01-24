MONTH_NAMES = [
  'January','February','March','April','May','June','July',
  'August','September','October','November','December',
  'Jan','Feb','Mar','Apr','May','Jun','Jul',
  'Aug','Sep','Oct','Nov','Dec'
]

MONTH_NAME_PATTERN = "(?:#{MONTH_NAMES.join('|')})"
DAY_PATTERN   = "\\b(?:[0-3]?[0-9])\\b"
MONTH_PATTERN = "\\b(?:0?[0-9]|1[0-2])\\b"

DATE_FORMATS = [
  # "may 5", "june 12, 2012"
  {pattern: new RegExp("(#{MONTH_NAME_PATTERN})\\s+(#{DAY_PATTERN})(?:,?\\s+(\\d{4}))?", 'i'), y: 3, m: 1, d: 2}
  # "2011-7-11", "2012-10-29"
  {pattern: /^(\d{4})[-\/]?(\d{1,2})[-\/]?(\d{1,2})$/, y: 1, m: 2, d: 3}
]

DAY_NAMES = [
  'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday',
  'Sun','Mon','Tue','Wed','Thu','Fri','Sat'
]

LZ = (x) ->
 "#{if x<0 || x>9 then "" else "0"}#{x}"

SECOND = 1000
SECONDS = 1000
MINUTE = MINUTES = 60 * SECONDS
HOUR   = HOURS   = 60 * MINUTES
DAY    = DAYS    = 24 * HOURS

{trim}  = require 'lang/string'
privacy = require 'util/privacy'

parse = (string) ->
  string = trim privacy.untaint(string)

  # try to parse it ourselves
  for {pattern, y, m, d} in DATE_FORMATS
    if match = string.match pattern
      year = y? and match[y] or new Date().getFullYear()
      month = m? and match[m] or new Date().getMonth()+1
      day = match[d]

      for name, i in MONTH_NAMES
        if name.toLowerCase() is month.toLowerCase()
          month = (i%12)+1
          break

      return new Date Number(year), Number(month)-1, Number(day)

  idate = Date.parse string
  if isNaN(idate)
    logger.warn 'unable to parse date: ', string
    return null

  return new Date idate

add = (date, duration) ->
  new Date date.getTime() + duration

addDays = (date, days) ->
  add date, days*DAYS

addMonths = (date, months) ->
  year = date.getFullYear()
  month = date.getMonth() + months

  while month >= 12
    month -= 12
    year++

  while month < 0
    month += 12
    year--

  new Date year, month, date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds()

addYears = (date, years) ->
  new Date date.getFullYear() + years, date.getMonth(), date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds()

format = (date, format) ->
  format = format + ""
  result = ""
  i_format = 0
  c = ""
  token = ""
  y = date.getYear()+""
  M = date.getMonth()+1
  d = date.getDate()
  E = date.getDay()
  H = date.getHours()
  m = date.getMinutes()
  s = date.getSeconds()
  # Convert real date parts into formatted versions
  value = {}
  y=""+(y-0+1900) if y.length < 4
  value["y"] = ""+y
  value["yyyy"] = y
  value["yy"] = y.substring(2,4)
  value["M"] = M
  value["MM"] = LZ(M)
  value["MMM"] = MONTH_NAMES[M-1]
  value["NNN"] = MONTH_NAMES[M+11]
  value["d"] = d
  value["dd"] = LZ(d)
  value["E"] = DAY_NAMES[E+7]
  value["EE"] = DAY_NAMES[E]
  value["H"] = H
  value["HH"] = LZ(H)
  value["h"] = if H == 0
                 12
               else if H>12
                 H-12
               else
                 H
  value["hh"] = LZ(value["h"])
  value["K"] = if H > 11
                 H-12
               else
                 H
  value["k"] = H+1;
  value["KK"] = LZ(value["K"])
  value["kk"] = LZ(value["k"])
  value["a"] = if H > 11
                 "PM"
               else
                 "AM"
  value["m"] = m
  value["mm"] = LZ(m)
  value["s"] = s
  value["ss"] = LZ(s)

  while i_format < format.length
    c = format.charAt(i_format)
    token = ""
    while (format.charAt(i_format) == c) && (i_format < format.length)
      token += format.charAt(i_format++)
    result += value[token] || token

  return result


module.exports = {parse, add, addDays, addMonths, addYears, format,
                  SECOND, SECONDS, MINUTE, MINUTES, HOUR, HOURS, DAY, DAYS,
                  DAY_NAMES, MONTH_NAMES}
