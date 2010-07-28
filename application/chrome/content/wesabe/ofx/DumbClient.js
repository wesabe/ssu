wesabe.provide('ofx.DumbClient', function(fi_url, fi_org, fi_id, username, password, logger) {
  this.fi_url   = fi_url;
  this.request  = new wesabe.ofx.OFXRequest(fi_org, fi_id);
  this.username = username;
  this.password = password;
  this.logger   = logger;
});

wesabe.lang.extend(wesabe.ofx.DumbClient.prototype, {
  get_all_statements: function() {
    var acct_info_req = request.account_info(this.username, this.password);
    var acct_info   = this.send_request(acct_info_req);
    var statements  = [];

    for (var i = 0; i < acct_info.bank_accounts.length; i++) {
      var stmt_req = request.bank_stmt(this.username, this.password, acct_info.bank_accounts[i]);
      statements.push(this.send_request(stmt_req));
    }

    for (var i = 0; i < acct_info.creditcard_accounts.length; i++) {
      var stmt_req = request.creditcard_stmt(this.username, this.password, acct_info.creditcard_accounts[i]);
      statements.push(this.send_request(stmt_req));
    }

    return statements;
  },

  send_request: function(request_body) {
    // this needs to be implemented
    // send request to this.fi_url
    // send body of request_body

    var response = new wesabe.ofx.OFXResponse(response_body);

    if (response.is_success()) {
      return response;
    } else {
      // throw an exception
    }
  },
});
