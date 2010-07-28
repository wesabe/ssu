wesabe.provide('lang.date');

wesabe.lang.date = {
  MONTH_NAMES: [
    'January','February','March','April','May','June','July',
    'August','September','October','November','December',
    'Jan','Feb','Mar','Apr','May','Jun','Jul',
    'Aug','Sep','Oct','Nov','Dec'
  ], 
  
  DAY_NAMES: [
    'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday',
    'Sun','Mon','Tue','Wed','Thu','Fri','Sat'
  ], 
  
  LZ: function(x) {
    return (x<0||x>9?"":"0")+x;
  }, 
  
  SECOND: 1000, 
  SECONDS: 1000, 
  
  parse: function(string) {
    var idate = Date.parse(string);
    if (isNaN(idate)) {
      wesabe.warn('unable to parse date: ', string);
      return null;
    }
    return new Date(idate);
  }, 
  
  add: function(date, duration) {
    return new Date(date.getTime() + duration);
  }, 
  
  format: function(date, format) {
    var LZ = wesabe.lang.date.LZ;
    
    format = format + "";
    var result = "";
    var i_format = 0;
    var c = "";
    var token = "";
    var y = date.getYear()+"";
    var M = date.getMonth()+1;
    var d = date.getDate();
    var E = date.getDay();
    var H = date.getHours();
    var m = date.getMinutes();
    var s = date.getSeconds();
    var yyyy,yy,MMM,MM,dd,hh,h,mm,ss,ampm,HH,H,KK,K,kk,k;
    // Convert real date parts into formatted versions
    var value = new Object();
    if (y.length < 4) {
      y=""+(y-0+1900);
    }
    value["y"] = ""+y;
    value["yyyy"] = y;
    value["yy"] = y.substring(2,4);
    value["M"] = M;
    value["MM"] = LZ(M);
    value["MMM"] = wesabe.lang.date.MONTH_NAMES[M-1];
    value["NNN"] = wesabe.lang.date.MONTH_NAMES[M+11];
    value["d"] = d;
    value["dd"] = LZ(d);
    value["E"] = wesabe.lang.date.DAY_NAMES[E+7];
    value["EE"] = wesabe.lang.date.DAY_NAMES[E];
    value["H"] = H;
    value["HH"] = LZ(H);
    if (H == 0) {
      value["h"] = 12;
    } else if (H>12) {
      value["h"] = H-12;
    } else {
      value["h"] = H;
    }
    value["hh"] = LZ(value["h"]);
    if (H>11) {
      value["K"] = H-12;
    } else {
      value["K"] = H;
    }
    value["k"] = H+1;
    value["KK"] = LZ(value["K"]);
    value["kk"] = LZ(value["k"]);
    if (H > 11) {
      value["a"] = "PM";
    } else {
      value["a"] = "AM";
    }
    value["m"] = m;
    value["mm"] = LZ(m);
    value["s"] = s;
    value["ss"] = LZ(s);
    while (i_format < format.length) {
      c = format.charAt(i_format);
      token = "";
      while ((format.charAt(i_format) == c) && (i_format < format.length)) {
        token += format.charAt(i_format++);
      }
      if (value[token] != null) {
        result = result + value[token];
      } else {
        result = result + token;
      }
    }
    return result;
  }
};

wesabe.lang.date.MINUTE = wesabe.lang.date.MINUTES = 60 * wesabe.lang.date.SECONDS;
wesabe.lang.date.HOUR   = wesabe.lang.date.HOURS   = 60 * wesabe.lang.date.MINUTES;
wesabe.lang.date.DAY    = wesabe.lang.date.DAYS    = 24 * wesabe.lang.date.HOURS;
