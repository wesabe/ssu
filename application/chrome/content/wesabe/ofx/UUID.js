wesabe.provide('ofx.UUID');

/*
uuid.js - Version 0.1
JavaScript Class to create a UUID like identifier

Copyright (C) 2006, Erik Giberti (AF-Design), All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place, Suite 330, Boston, MA 02111-1307 USA

The latest version of this file can be downloaded from
http://www.af-design.com/resources/javascript_uuid.php

HISTORY:
6/5/06 - Initial Release

*/


// on creation of a UUID object, set it's initial value
wesabe.ofx.UUID = function(){
  this.id = this.createUUID();
};

wesabe.lang.extend(wesabe.ofx.UUID.prototype, {
  // When asked what this Object is, lie and return its value
  valueOf: function(){ return this.id; },
  toString: function(){ return this.id; },

  createUUID: function() {
    // JavaScript Version of UUID implementation.
    //
    // Copyright 2006 Erik Giberti, all rights reserved.
    //
    // Loose interpretation of the specification DCE 1.1: Remote Procedure Call
    // described at http://www.opengroup.org/onlinepubs/009629399/apdxa.htm#tagtcjh_37
    // since JavaScript doesn't allow access to internal systems, the last 48 bits
    // of the node section is made up using a series of random numbers (6 octets long).
    //
    var UUID = wesabe.ofx.UUID;
    var dg = UUID.timeInMs(new Date(1582, 10, 15, 0, 0, 0, 0));
    var dc = UUID.timeInMs(new Date());
    var t = dc - dg;
    var h = '-';
    var tl = UUID.getIntegerBits(t,0,31);
    var tm = UUID.getIntegerBits(t,32,47);
    var thv = UUID.getIntegerBits(t,48,59) + '1'; // version 1, security version is 2
    var csar = UUID.getIntegerBits(UUID.randrange(0,4095),0,7);
    var csl = UUID.getIntegerBits(UUID.randrange(0,4095),0,7);

    // since detection of anything about the machine/browser is far to buggy,
    // include some more random numbers here
    // if nic or at least an IP can be obtained reliably, that should be put in
    // here instead.
    var n = UUID.getIntegerBits(UUID.randrange(0,8191),0,7) +
        UUID.getIntegerBits(UUID.randrange(0,8191),8,15) +
        UUID.getIntegerBits(UUID.randrange(0,8191),0,7) +
        UUID.getIntegerBits(UUID.randrange(0,8191),8,15) +
        UUID.getIntegerBits(UUID.randrange(0,8191),0,15); // this last number is two octets long
    return tl + h + tm + h + thv + h + csar + csl + h + n;
  },
});

//
// GENERAL METHODS (Not instance specific)
//

wesabe.lang.extend(wesabe.ofx.UUID, {
  // Pull out only certain bits from a very large integer, used to get the time
  // code information for the first part of a UUID. Will return zero's if there
  // aren't enough bits to shift where it needs to.
  getIntegerBits: function(val,start,end) {
    var base16 = wesabe.ofx.UUID.returnBase(val,16);
    var quadArray = new Array();
    var quadString = '';
    var i = 0;
    for(i=0;i<base16.length;i++){
      quadArray.push(base16.substring(i,i+1));
    }
    for(i=Math.floor(start/4);i<=Math.floor(end/4);i++){
      if(!quadArray[i] || quadArray[i] == '') quadString += '0';
      else quadString += quadArray[i];
    }
    return quadString;
  },

  // Numeric Base Conversion algorithm from irt.org
  // In base 16: 0=0, 5=5, 10=A, 15=F
  returnBase: function(number, base) {
    //
    // Copyright 1996-2006 irt.org, All Rights Reserved.
    //
    // Downloaded from: http://www.irt.org/script/146.htm
    // modified to work in this class by Erik Giberti
    var convert = ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
    if (number < base) var output = convert[number];
    else {
      var MSD = '' + Math.floor(number / base);
      var LSD = number - MSD*base;
      if (MSD >= base) var output = this.returnBase(MSD,base) + convert[LSD];
      else var output = convert[MSD] + convert[LSD];
    }
    return output;
  },

  // This is approximate but should get the job done for general use.
  // It gets an approximation of the provided date in milliseconds. WARNING:
  // some implementations of JavaScript will choke with these large numbers
  // and so the absolute value is used to avoid issues where the implementation
  // begin's at the negative value.
  timeInMs: function(d) {
    var ms_per_second = 100; // constant
    var ms_per_minute = 6000; // ms_per second * 60;
    var ms_per_hour   = 360000; // ms_per_minute * 60;
    var ms_per_day    = 8640000; // ms_per_hour * 24;
    var ms_per_month  = 207360000; // ms_per_day * 30;
    var ms_per_year   = 75686400000; // ms_per_day * 365;
    return Math.abs((d.getUTCFullYear() * ms_per_year) + (d.getUTCMonth() * ms_per_month) + (d.getUTCDate() * ms_per_day) + (d.getUTCHours() * ms_per_hour) + (d.getUTCMinutes() * ms_per_minute) + (d.getUTCSeconds() * ms_per_second) + d.getUTCMilliseconds());
  },

  // pick a random number within a range of numbers
  // int c randrange(int a, int b); where a <= c <= b
  randrange: function(min,max) {
    var num = Math.round(Math.random() * max);
    if(num < min){
      num = min;
    } else if (num > max) {
      num = max;
    }
    return num;
  },
});
