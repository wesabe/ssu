wesabe.provide('ofx.Account');
wesabe.require('util.privacy');

/***
 * Wesabe Firefox Uploader
 * Copyright (C) 2007 Wesabe, Inc.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */

// Account - simple data container for account information

/* Constructor */

wesabe.ofx.Account = function(accttype, acctid, bankid, desc) {
  this.accttype = accttype;
  this.acctid   = acctid;
  this.bankid   = bankid;
  this.desc   = desc;

  this.masked_acctid = this._mask_acctid();
}

// Mask the account number for this account, replacing all but the
// last four digits of the account number with 'X's.  See also
// Response.get_sanitized_response().

wesabe.ofx.Account.prototype._mask_acctid = function() {
  if (this.acctid.length > 4) {
    var sensitive = this.acctid.slice(0, -4);
    var mask = "";

    for (var i = 0; i < sensitive.length; i++) {
      mask = mask.concat("X");
    }

    return this.acctid.replace(sensitive, mask.concat("-"));

  } else {
    return this.acctid;
  }
};

wesabe.ready('wesabe.util.privacy', function() {
  wesabe.util.privacy.taint.registerWrapper({
    detector: function(o){ return wesabe.is(o, wesabe.ofx.Account) },
    getters: ["accttype", "acctid", "bankid", "desc", "masked_acctid"]
  });
});
