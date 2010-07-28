wesabe.provide('ofx.Response');
wesabe.require('ofx.Status');
wesabe.require('util.privacy');
wesabe.require('xml.*');

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

// Response - parse an OFX response message for needed information

// Takes the raw text of an OFX response of any supported kind (account info,
// bank statement, or credit card statement) and parses it just enough to
// extract information a client would need from it.  The Response object
// can be used to check for OFX errors in the response message, to get a list
// of bank and credit card accounts listed in the response, and to get a
// "sanitized" version of the response that masks any account numbers and
// removes other sensitive information (particularly, INTU tags that may
// reveal the user's bank username or other credentials) from the response
// text.
//
// Note that one OFX response file may contain multiple status responses,
// and some may be successful while others are not.  Response provides
// one isSuccess() method that checks *all* status blocks for any errors,
// and returns false if any errors exist.  You can retrieve all of the
// Status objects for this response in the Response.statuses array.
//
// Usage:
//
// //....build OFX account info request....
// var acctinfo_text = ofx_client.send_request(acctinfo_request);
// var acctinfo = new wesabe.ofx.Response(acctinfo_text);
// if (acctinfo.isSuccess()) {
//     for (var i = 0; i < acctinfo.bankAccounts.length; i++) {
//         // ....build OFX bank statement request....
//         var statement_text = ofx_client.send_request(bankstmt_request);
//         var statement = new wesabe.ofx.Response(statement_text);
//         if (statement.isSuccess()) {
//             wesabe_client.upload_statement(statement.get_sanitized_statement());
//         } else {
//             // report error
//         }
//     }
//
//     for (var i = 0; i < acctinfo.creditcardAccounts.length; i++) {
//         // ....build OFX bank statement request....
//         var statement_text = ofx_client.send_request(creditcardstmt_request);
//         var statement = new wesabe.ofx.Response(statement_text);
//         if (statement.isSuccess()) {
//             wesabe_client.upload_statement(statement.get_sanitized_statement());
//         } else {
//             // report error
//         }
//     }
// } else {
//     // report error
// }

/* Constructor */

wesabe.ofx.Response = function(response, job) {
  this.response = response;
  this.job = job;
  wesabe.radioactive('ofx.Response: response=', response);

  this.statuses = [];
  this._find_statuses();
};

wesabe.lang.extend(wesabe.ofx.Response.prototype, {
  /* Public methods */

  // Response OFX presented as a DOM tree.

  get responseXML() {
    if (!this.__responseXML__) {
      var self = this;
      var parse = function() {
        self.__responseXML__ = new wesabe.ofx.Document(self.response, /BANKTRANLIST/i);
      };
      if (!this.job) {
        parse();
      } else {
        this.job.timer.start('Parse OFX', parse);
      }
    }
    return this.__responseXML__;
  },

  // Response OFX presented as a complete DOM tree, including BANKTRANLIST nodes.

  parseFullResponseXML: function() {
    if (!this.__fullResponseXML__) {
      this.__partialResponseXML__ = this.__responseXML__;

      var self = this;
      var parse = function() {
        self.__fullResponseXML__ = new wesabe.ofx.Document(self.response);
      };
      if (!this.job) {
        parse();
      } else {
        this.job.timer.start('Parse OFX', parse);
      }
    }
    return this.__responseXML__ = this.__fullResponseXML__;
  },

  // List of all deposit accounts.

  get bankAccounts() {
    if (!this.__bankAccounts__) this._find_accounts();
    return this.__bankAccounts__;
  },

  // List of all credit accounts.

  get creditcardAccounts() {
    if (!this.__creditcardAccounts__) this._find_accounts();
    return this.__creditcardAccounts__;
  },

  // List of all investment accounts.

  get investmentAccounts() {
    if (!this.__investmentAccounts__) this._find_accounts();
    return this.__investmentAccounts__;
  },

  hasOFX: function() {
    var documentElement = this.responseXML.documentElement;
    if (!documentElement)
      return false;

    return documentElement.tagName.toLowerCase() == 'ofx';
  },

  // Check to see if the server returned any errors
  // in the OFX response.

  isSuccess: function() {
    if (!this.hasOFX())
      return false;

    if (this._firstErrorStatus())
      return false;

    return true;
  },

  isError: function() {
    return !this.isSuccess();
  },

  isGeneralError: function() {
    var status = this._firstErrorStatus();
    return status && status.isGeneralError();
  },

  isAuthenticationError: function() {
    var status = this._firstErrorStatus();
    return status && status.isAuthenticationError();
  },

  isAuthorizationError: function() {
    var status = this._firstErrorStatus();
    return status && status.isAuthorizationError();
  },

  // Get a list of Account objects representing bank
  // accounts found anywhere in this response.

  get_bank_accounts: function() {
    return this.bankAccounts;
  },

  // Get a list of Account objects representing credit card
  // accounts found anywhere in this response.

  get_creditcard_accounts: function() {
    return this.creditcardAccounts;
  },

  // Remove everything from this response that should never hit
  // the server -- account numbers, usernames, Intuit tags.

  getSanitizedResponse: function() {
    var sanitized_text = this.response;
    var all_accounts = this.bankAccounts.concat(this.creditcardAccounts);

    for (var i = 0; i < all_accounts.length; i++) {
      var acctid        = all_accounts[i].acctid;
      var masked_acctid = all_accounts[i].masked_acctid;
      sanitized_text = sanitized_text.replace(acctid, masked_acctid);
    }

    var intu_pattern = /<INTU.[^>]*>[^<]*(?:<\/INTU.[^>]*>[^<]*)?/ig;
    while ((result = intu_pattern.exec(this.response)) != undefined) {
      var intu_tag   = result[0];
      sanitized_text = sanitized_text.replace(intu_tag, "");
    }

    return sanitized_text;
  },

  /* Private methods */


  _firstErrorStatus: function() {
    if (!this.statuses) return null;

    for (var i = 0; i < this.statuses.length; i++) {
      var status = this.statuses[i];
      if (status.isError()) return status;
    }

    return null;
  },

  _find_accounts: function() {
    var self = this,
        bank = this.__bankAccounts__ = [],
        credit = this.__creditcardAccounts__ = [],
        investment = this.__investmentAccounts__ = [];

    this.responseXML.getElementsByTagName('ACCTINFO').forEach(function(acct) {
      wesabe.radioactive(acct);
      var acctid   = acct.getElementsByTagName('ACCTID')[0];
      var bankid   = acct.getElementsByTagName('BANKID')[0];
      var accttype = acct.getElementsByTagName('ACCTTYPE')[0];
      var desc     = acct.getElementsByTagName('DESC')[0];
      var account  = acct.getElementsByTagName('CREDITCARD')[0];

      acctid   = acctid && wesabe.lang.string.trim(acctid.text);
      accttype = accttype && wesabe.lang.string.trim(accttype.text);
      bankid   = bankid && wesabe.lang.string.trim(bankid.text);
      desc     = desc && wesabe.lang.string.trim(desc.text);
      account  = account && wesabe.lang.string.trim(account.text);

      if (acct.getElementsByTagName('BANKACCTFROM').length) {
        bank.push(new wesabe.ofx.Account(accttype, acctid, bankid, desc));
      } else if (acct.getElementsByTagName('CCACCTFROM').length) {
        credit.push(new wesabe.ofx.Account("CREDITCARD", acctid, null, desc));
      } else if (acct.getElementsByTagName('INVACCTFROM').length) {
        investment.push(new wesabe.ofx.Account("INVESTMENT", acctid, null, desc));
      } else {
        wesabe.warn("Skipping unknown account type: ", acct);
      }
    });
  },

  _find_statuses: function() {
    var self = this, ofx = this.response;
    wesabe.tryThrow('Response#_find_statuses', function() {
      self.responseXML.getElementsByTagName('STATUS').forEach(function(status) {
        wesabe.radioactive(status);
        var code      = status.getElementsByTagName('CODE')[0];
        var severity  = status.getElementsByTagName('SEVERITY')[0];
        var message   = status.getElementsByTagName('MESSAGE')[0];

        code      = code && wesabe.lang.string.trim(code.text);
        severity  = severity && wesabe.lang.string.trim(severity.text);
        message   = message && wesabe.lang.string.trim(message.text);

        self.statuses.push(new wesabe.ofx.Status(code, severity, message));
      })
    });
  },
});
