wesabe.provide('ofx.Request');
wesabe.require('lang.date');

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

// Request - build an OFX request message

// Construct with the ORG and FID of the financial institution, and then
// call methods for each request type you want to generate.  Return values
// are strings suitable for sending to OFX servers.  Currently supports
// account info, bank statement, and credit card statement requests.

/* Constructor */

wesabe.ofx.Request = function(fi, username, password, job) {
  this.fi = fi;
  this.username = username || 'anonymous00000000000000000000000';
  this.password = password || 'anonymous00000000000000000000000';
  this.job = job;
};

/* Public methods */

wesabe.lang.extend(wesabe.ofx.Request.prototype, {
  request: function(data, callback, metadata) {
    var self = this;

    // log the request if we *really* need to
    wesabe.radioactive('OFX Request: ', data);

    wesabe.io.post(this.fi.ofxUrl, null, data, {
      before: function(request) {
        request.setRequestHeader("Content-type", "application/x-ofx");
        request.setRequestHeader("Accept", "*/*, application/x-ofx");
        if (!wesabe.isFunction(callback))
          wesabe.lang.func.executeCallback(callback, 'before', [self].concat(metadata || []));
      },

      success: function(request) {
        var ofxresponse = new wesabe.ofx.Response(request.responseText, self.job);
        wesabe.success(callback, [self, ofxresponse, request]);
      },

      failure: function(request) {
        var ofxresponse = null;
        try {
          ofxresponse = new wesabe.ofx.Response(request.responseText, self.job);
        } catch(e) {
          wesabe.error("Could not parse response as OFX: ", request.responseText);
        }
        wesabe.failure(callback, [self, ofxresponse, request]);
      },

      after: function(request) {
        if (!wesabe.isFunction(callback))
          wesabe.lang.func.executeCallback(callback, 'after', [self].concat(metadata || []));
      },
    });
  },

  fiProfile: function() {
    this._init();
    return this._header() +
           "<OFX>\r\n" +
           this._signon() +
           this._fiprofile() +
           "</OFX>\r\n";
  },

  requestFiProfile: function(callback) {
    var data = this.fiProfile(), self = this;

    this.request(data, {
      success: function(self, response, request) {
        wesabe.lang.func.executeCallback(callback, 'success', [self, response, request]);
      },

      failure: function(self, response, request) {
        wesabe.lang.func.executeCallback(callback, 'failure', [self, response, request]);
      },
    });
  },

  accountInfo: function() {
    this._init();
    return this._header() +
           "<OFX>\r\n" +
           this._signon() +
           this._acctinfo() +
           "</OFX>\r\n";
  },

  requestAccountInfo: function(callback) {
    var data = this.accountInfo();

    this.request(data, {
      success: function(self, response, request) {
        var accounts = [];
        if (response.isSuccess()) {
          for (var i = 0; i < response.bankAccounts.length; i++) {
            accounts.push(response.bankAccounts[i]);
          }
          for (var i = 0; i < response.creditcardAccounts.length; i++) {
            accounts.push(response.creditcardAccounts[i]);
          }
          for (var i = 0; i < response.investmentAccounts.length; i++) {
            accounts.push(response.investmentAccounts[i]);
          }
          wesabe.success(callback, [{
            accounts: accounts,
                text: request.responseText }]);
        } else {
          wesabe.error("ofx.Request#requestAccountInfo: login failure");
          wesabe.failure(callback, [{
            accounts: null,
                text: request.responseText,
                 ofx: response }]);
        }
      },

      failure: function(self, response, request) {
        wesabe.error('ofx.Request#requestAccountInfo: error: ', request.responseText);
        wesabe.failure(callback, [{
          accounts: null,
              text: request.responseText}]);
      },
    });
  },

  bank_stmt: function(ofx_account, dtstart) {
    this._init();
    return this._header() +
           "<OFX>\r\n" +
           this._signon() +
           this._bankstmt(ofx_account.bankid, ofx_account.acctid, ofx_account.accttype, dtstart) +
           "</OFX>\r\n";
  },

  creditcard_stmt: function(ofx_account, dtstart) {
    this._init();
    return this._header() +
           "<OFX>\r\n" +
           this._signon() +
           this._ccardstmt(ofx_account.acctid, dtstart) +
           "</OFX>\r\n";
  },

  investment_stmt: function(ofx_account, dtstart) {
    this._init();
    return this._header() +
           "<OFX>\r\n" +
           this._signon() +
           this._investstmt(ofx_account.acctid, dtstart) +
           "</OFX>\r\n";
  },

  requestStatement: function(account, options, callback) {
    account = wesabe.untaint(account);

    var data;
    switch (account.accttype) {
      case 'CREDITCARD':
        data = this.creditcard_stmt(account, options.dtstart);
        break;
      case 'INVESTMENT':
        data = this.investment_stmt(account, options.dtstart);
        break;
      default:
        data = this.bank_stmt(account, options.dtstart);
        break;
    }

    this.request(data, {
      success: function(self, response, request) {
        if (response.response && response.isSuccess()) {
          wesabe.success(callback, [{
            statement: response.getSanitizedResponse(),
                 text: request.responseText }]);
        } else {
          wesabe.error('ofx.Request#requestStatement: response failure');
          wesabe.failure(callback, [{
            statement: null,
                 text: request.responseText,
                  ofx: response }]);
        }
      },

      failure: function(self, response, request) {
        wesabe.error('ofx.Request#requestStatement: error: ', request.responseText);
        wesabe.failure(callback, [{
          statement: null,
               text: request.responseText }]);
      },
    }, [{
      request: this,
         type: 'ofx.statement',
          url: this.fi.ofxUrl,
          job: this.job
    }]);
  },

  get appId() {
    return this._appId || 'Money';
  },

  set appId(appId) {
    this._appId = appId;
  },

  get appVersion() {
    return this._appVersion || '1700';
  },

  set appVersion(appVersion) {
    this._appVersion = appVersion;
  },

  /* Private methods */

  _init: function() {
    this.uuid = new wesabe.ofx.UUID();
    this.datetime = wesabe.lang.date.format(new Date(), 'yyyyMMddHHmmss');
  },

  _header: function() {
    return "OFXHEADER:100\r\n" +
           "DATA:OFXSGML\r\n" +
           "VERSION:102\r\n" +
           "SECURITY:NONE\r\n" +
           "ENCODING:USASCII\r\n" +
           "CHARSET:1252\r\n" +
           "COMPRESSION:NONE\r\n" +
           "OLDFILEUID:NONE\r\n" +
           "NEWFILEUID:" + this.uuid + "\r\n\r\n";
  },

  _signon: function() {
    return "<SIGNONMSGSRQV1>\r\n" +
           "<SONRQ>\r\n" +
           "<DTCLIENT>" + this.datetime + "\r\n" +
           "<USERID>" + this.username + "\r\n" +
           "<USERPASS>" + this.password + "\r\n" +
           "<LANGUAGE>ENG\r\n" +
           (this.fi.ofxOrg || this.fi.ofxFid ? ("<FI>\r\n") : '') +
           (this.fi.ofxOrg ? ("<ORG>" + this.fi.ofxOrg + "\r\n") : '') +
           (this.fi.ofxFid ? ("<FID>" + this.fi.ofxFid + "\r\n") : '') +
           (this.fi.ofxOrg || this.fi.ofxFid ? ("</FI>\r\n") : '') +
           "<APPID>" + this.appId + "\r\n" +
           "<APPVER>" + this.appVersion + "\r\n" +
           "</SONRQ>\r\n" +
           "</SIGNONMSGSRQV1>\r\n"
  },

  _fiprofile: function() {
    return "<PROFMSGSRQV1>\r\n" +
           "<PROFTRNRQ>\r\n" +
           "<TRNUID>" + this.uuid + "\r\n" +
           "<CLTCOOKIE>4\r\n" +
           "<PROFRQ>\r\n" +
           "<CLIENTROUTING>NONE\r\n" +
           "<DTPROFUP>19980101\r\n" +
           "</PROFRQ>\r\n" +
           "</PROFTRNRQ>\r\n" +
           "</PROFMSGSRQV1>\r\n";
  },

  _acctinfo: function() {
    return "<SIGNUPMSGSRQV1>\r\n" +
           "<ACCTINFOTRNRQ>\r\n" +
           "<TRNUID>" + this.uuid + "\r\n" +
           "<CLTCOOKIE>4\r\n" +
           "<ACCTINFORQ>\r\n" +
           "<DTACCTUP>19980101\r\n" +
           "</ACCTINFORQ>\r\n" +
           "</ACCTINFOTRNRQ>\r\n" +
           "</SIGNUPMSGSRQV1>\r\n";
  },

  _bankstmt: function(bankid, acctid, accttype, dtstart) {
    return "<BANKMSGSRQV1>\r\n" +
           "<STMTTRNRQ>\r\n" +
           "<TRNUID>" + this.uuid + "\r\n" +
           "<CLTCOOKIE>4\r\n" +
           "<STMTRQ>\r\n" +
           "<BANKACCTFROM>\r\n" +
           "<BANKID>" + bankid + "\r\n" +
           "<ACCTID>" + acctid + "\r\n" +
           "<ACCTTYPE>" + accttype + "\r\n" +
           "</BANKACCTFROM>\r\n" +
           "<INCTRAN>\r\n" +
           "<DTSTART>" + wesabe.lang.date.format(dtstart, 'yyyyMMdd') + "\r\n" +
           "<INCLUDE>Y\r\n" +
           "</INCTRAN>\r\n" +
           "</STMTRQ>\r\n" +
           "</STMTTRNRQ>\r\n" +
           "</BANKMSGSRQV1>\r\n";
  },

  _ccardstmt: function(acctid, dtstart) {
    return "<CREDITCARDMSGSRQV1>\r\n" +
           "<CCSTMTTRNRQ>\r\n" +
           "<TRNUID>" + this.uuid + "\r\n" +
           "<CLTCOOKIE>4\r\n" +
           "<CCSTMTRQ>\r\n" +
           "<CCACCTFROM>\r\n" +
           "<ACCTID>" + acctid + "\r\n" +
           "</CCACCTFROM>\r\n" +
           "<INCTRAN>\r\n" +
           "<DTSTART>" + wesabe.lang.date.format(dtstart, 'yyyyMMdd') + "\r\n" +
           "<INCLUDE>Y\r\n" +
           "</INCTRAN>\r\n" +
           "</CCSTMTRQ>\r\n" +
           "</CCSTMTTRNRQ>\r\n" +
           "</CREDITCARDMSGSRQV1>\r\n";
  },

  _investstmt: function(acctid, dtstart) {
    return "<INVSTMTMSGSRQV1>\r\n" +
           "<INVSTMTTRNRQ>\r\n" +
           "<TRNUID>" + this.uuid + "\r\n" +
           "<CLTCOOKIE>4\r\n" +
           "<INVSTMTRQ>\r\n" +
           "<INVACCTFROM>\r\n" +
           "<BROKERID>" + this.fi.ofxBroker + "\r\n" +
           "<ACCTID>" + acctid + "\r\n" +
           "</INVACCTFROM>\r\n" +
           "<INCTRAN>\r\n" +
           "<DTSTART>" + wesabe.lang.date.format(dtstart, 'yyyyMMdd') + "\r\n" +
           "<INCLUDE>Y\r\n" +
           "</INCTRAN>\r\n" +
           "<INCOO>Y\r\n" +
           "<INCPOS>\r\n" +
           "<INCLUDE>Y\r\n" +
           "</INCPOS>\r\n" +
           "<INCBAL>Y\r\n" +
           "</INVSTMTRQ>\r\n" +
           "</INVSTMTTRNRQ>\r\n" +
           "</INVSTMTMSGSRQV1>\r\n";
  },
});
