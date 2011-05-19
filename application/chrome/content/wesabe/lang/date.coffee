wesabe.provide('lang.date')

wesabe.lang.date =
  MONTH_NAMES: [
    'January','February','March','April','May','June','July',
    'August','September','October','November','December',
    'Jan','Feb','Mar','Apr','May','Jun','Jul',
    'Aug','Sep','Oct','Nov','Dec'
  ]

  DAY_NAMES: [
    'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday',
    'Sun','Mon','Tue','Wed','Thu','Fri','Sat'
  ]

  LZ: (x) ->
   "#{if x<0 || x>9 then "" else "0"}#{x}"

  SECOND: 1000
  SECONDS: 1000

  parse: (string) ->
    idate = Date.parse(string)
    if isNaN(idate)
      wesabe.warn('unable to parse date: ', string)
      return null

    return new Date(idate)

  add: (date, duration) ->
    new Date(date.getTime() + duration)

  format: (date, format) ->
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
    value["MM"] = @LZ(M)
    value["MMM"] = @MONTH_NAMES[M-1]
    value["NNN"] = @MONTH_NAMES[M+11]
    value["d"] = d
    value["dd"] = @LZ(d)
    value["E"] = @DAY_NAMES[E+7]
    value["EE"] = @DAY_NAMES[E]
    value["H"] = H
    value["HH"] = @LZ(H)
    value["h"] = if H == 0
                   12
                 else if H>12
                   H-12
                 else
                   H
    value["hh"] = @LZ(value["h"])
    value["K"] = if H > 11
                   H-12
                 else
                   H
    value["k"] = H+1;
    value["KK"] = @LZ(value["K"])
    value["kk"] = @LZ(value["k"])
    value["a"] = if H > 11
                   "PM"
                 else
                   "AM"
    value["m"] = m
    value["mm"] = @LZ(m)
    value["s"] = s
    value["ss"] = @LZ(s)

    while i_format < format.length
      c = format.charAt(i_format)
      token = ""
      while (format.charAt(i_format) == c) && (i_format < format.length)
        token += format.charAt(i_format++)
      result += value[token] || token

    return result

wesabe.lang.date.MINUTE = wesabe.lang.date.MINUTES = 60 * wesabe.lang.date.SECONDS
wesabe.lang.date.HOUR   = wesabe.lang.date.HOURS   = 60 * wesabe.lang.date.MINUTES
wesabe.lang.date.DAY    = wesabe.lang.date.DAYS    = 24 * wesabe.lang.date.HOURS
