wesabe.provide('ofx.Request')
wesabe.require('lang.date')

## Request - build an OFX request message

## Construct with the ORG and FID of the financial institution, and then
## call methods for each request type you want to generate.  Return values
## are strings suitable for sending to OFX servers.  Currently supports
## account info, bank statement, and credit card statement requests.

class wesabe.ofx.Request
  constructor: (@fi, @username = 'anonymous00000000000000000000000', @password = 'anonymous00000000000000000000000', @job) ->

  request: (data, callback, metadata) ->
    # log the request if we *really* need to
    wesabe.radioactive('OFX Request: ', data)

    wesabe.io.post @fi.ofxUrl, null, data,
      before: (request) =>
        request.setRequestHeader("Content-type", "application/x-ofx")
        request.setRequestHeader("Accept", "*/*, application/x-ofx")
        if not wesabe.isFunction(callback)
          wesabe.lang.func.executeCallback(callback, 'before', [this].concat(metadata || []))

      success: (request) =>
        ofxresponse = new wesabe.ofx.Response(request.responseText, @job)
        wesabe.success(callback, [this, ofxresponse, request])

      failure: (request) =>
        ofxresponse = null
        try
          ofxresponse = new wesabe.ofx.Response(request.responseText, @job)
        catch e
          wesabe.error("Could not parse response as OFX: ", request.responseText)

        wesabe.failure(callback, [this, ofxresponse, request])

      after: (request) =>
        if not wesabe.isFunction(callback)
          wesabe.lang.func.executeCallback(callback, 'after', [this].concat(metadata || []))

  fiProfile: ->
    @_init()

    @_header() +
    "<OFX>\r\n" +
    @_signon() +
    @_fiprofile() +
    "</OFX>\r\n"

  requestFiProfile: (callback) ->
    data = @fiProfile()

    @request data,
      success: (self, response, request) ->
        wesabe.lang.func.executeCallback(callback, 'success', [self, response, request])

      failure: (self, response, request) ->
        wesabe.lang.func.executeCallback(callback, 'failure', [self, response, request])

  accountInfo: ->
    @_init()

    @_header() +
    "<OFX>\r\n" +
    @_signon() +
    @_acctinfo() +
    "</OFX>\r\n"

  requestAccountInfo: (callback) ->
    data = @accountInfo()

    @request data,
      success: (self, response, request) ->
        accounts = []
        if response.isSuccess()
          accounts = accounts.concat(response.bankAccounts)
                             .concat(response.creditcardAccounts)
                             .concat(response.investmentAccounts)

          wesabe.success(callback, [{ accounts: accounts, text: request.responseText }])
        else
          wesabe.error("ofx.Request#requestAccountInfo: login failure")
          wesabe.failure(callback, [{ accounts: null, text: request.responseText, ofx: response }])

      failure: (self, response, request) ->
        wesabe.error('ofx.Request#requestAccountInfo: error: ', request.responseText)
        wesabe.failure(callback, [{ accounts: null, text: request.responseText}])

  bank_stmt: (ofx_account, dtstart) ->
    @_init()

    @_header() +
    "<OFX>\r\n" +
    @_signon() +
    @_bankstmt(ofx_account.bankid, ofx_account.acctid, ofx_account.accttype, dtstart) +
    "</OFX>\r\n"

  creditcard_stmt: (ofx_account, dtstart) ->
    @_init();
    @_header() +
    "<OFX>\r\n" +
    @_signon() +
    @_ccardstmt(ofx_account.acctid, dtstart) +
    "</OFX>\r\n"

  investment_stmt: (ofx_account, dtstart) ->
    @_init()
    @_header() +
    "<OFX>\r\n" +
    @_signon() +
    @_investstmt(ofx_account.acctid, dtstart) +
    "</OFX>\r\n"

  requestStatement: (account, options, callback) ->
    account = wesabe.untaint(account)

    data = switch account.accttype
             when 'CREDITCARD'
               @creditcard_stmt(account, options.dtstart)
             when 'INVESTMENT'
               @investment_stmt(account, options.dtstart)
             else
               @bank_stmt(account, options.dtstart)

    @request data, {
      success: (self, response, request) ->
        if response.response && response.isSuccess()
          wesabe.success(callback, [{ statement: response.getSanitizedResponse(), text: request.responseText }])
        else
          wesabe.error('ofx.Request#requestStatement: response failure')
          wesabe.failure(callback, [{ statement: null, text: request.responseText, ofx: response }])

      failure: (self, response, request) ->
        wesabe.error('ofx.Request#requestStatement: error: ', request.responseText)
        wesabe.failure(callback, [{ statement: null, text: request.responseText }])
    }, [{
      request: this
      type: 'ofx.statement'
      url: @fi.ofxUrl
      job: @job
    }]

  this::__defineGetter__ 'appId', ->
    @_appId || 'Money'

  this::__defineSetter__ 'appId', ->
    @_appId = appId

  this::__defineGetter__ 'appVersion', ->
    @_appVersion || '1700'

  this::__defineSetter__ 'appVersion', (appVersion) ->
    @_appVersion = appVersion

  # Private methods

  _init: ->
    @uuid = new wesabe.ofx.UUID()
    @datetime = wesabe.lang.date.format(new Date(), 'yyyyMMddHHmmss')

  _header: ->
    "OFXHEADER:100\r\n" +
    "DATA:OFXSGML\r\n" +
    "VERSION:102\r\n" +
    "SECURITY:NONE\r\n" +
    "ENCODING:USASCII\r\n" +
    "CHARSET:1252\r\n" +
    "COMPRESSION:NONE\r\n" +
    "OLDFILEUID:NONE\r\n" +
    "NEWFILEUID:" + @uuid + "\r\n\r\n"

  _signon: ->
    "<SIGNONMSGSRQV1>\r\n" +
    "<SONRQ>\r\n" +
    "<DTCLIENT>#{@datetime}\r\n" +
    "<USERID>#{@username}\r\n" +
    "<USERPASS>#{@password}\r\n" +
    "<LANGUAGE>ENG\r\n" +
    (if @fi.ofxOrg || @fi.ofxFid then "<FI>\r\n" else '') +
    (if @fi.ofxOrg then "<ORG>#{@fi.ofxOrg}\r\n" else '') +
    (if @fi.ofxFid then "<FID>#{@fi.ofxFid}\r\n" else '') +
    (if @fi.ofxOrg || @fi.ofxFid then "</FI>\r\n" else '') +
    "<APPID>#{@appId}\r\n" +
    "<APPVER>#{@appVersion}\r\n" +
    "</SONRQ>\r\n" +
    "</SIGNONMSGSRQV1>\r\n"

  _fiprofile: ->
    "<PROFMSGSRQV1>\r\n" +
    "<PROFTRNRQ>\r\n" +
    "<TRNUID>#{@uuid}\r\n" +
    "<CLTCOOKIE>4\r\n" +
    "<PROFRQ>\r\n" +
    "<CLIENTROUTING>NONE\r\n" +
    "<DTPROFUP>19980101\r\n" +
    "</PROFRQ>\r\n" +
    "</PROFTRNRQ>\r\n" +
    "</PROFMSGSRQV1>\r\n"

  _acctinfo: ->
    "<SIGNUPMSGSRQV1>\r\n" +
    "<ACCTINFOTRNRQ>\r\n" +
    "<TRNUID>#{@uuid}\r\n" +
    "<CLTCOOKIE>4\r\n" +
    "<ACCTINFORQ>\r\n" +
    "<DTACCTUP>19980101\r\n" +
    "</ACCTINFORQ>\r\n" +
    "</ACCTINFOTRNRQ>\r\n" +
    "</SIGNUPMSGSRQV1>\r\n"

  _bankstmt: (bankid, acctid, accttype, dtstart) ->
    "<BANKMSGSRQV1>\r\n" +
    "<STMTTRNRQ>\r\n" +
    "<TRNUID>#{@uuid}\r\n" +
    "<CLTCOOKIE>4\r\n" +
    "<STMTRQ>\r\n" +
    "<BANKACCTFROM>\r\n" +
    "<BANKID>#{bankid}\r\n" +
    "<ACCTID>#{acctid}\r\n" +
    "<ACCTTYPE>#{accttype}\r\n" +
    "</BANKACCTFROM>\r\n" +
    "<INCTRAN>\r\n" +
    "<DTSTART>#{wesabe.lang.date.format(dtstart, 'yyyyMMdd')}\r\n" +
    "<INCLUDE>Y\r\n" +
    "</INCTRAN>\r\n" +
    "</STMTRQ>\r\n" +
    "</STMTTRNRQ>\r\n" +
    "</BANKMSGSRQV1>\r\n"

  _ccardstmt: (acctid, dtstart) ->
    "<CREDITCARDMSGSRQV1>\r\n" +
    "<CCSTMTTRNRQ>\r\n" +
    "<TRNUID>#{@uuid}\r\n" +
    "<CLTCOOKIE>4\r\n" +
    "<CCSTMTRQ>\r\n" +
    "<CCACCTFROM>\r\n" +
    "<ACCTID>#{acctid}\r\n" +
    "</CCACCTFROM>\r\n" +
    "<INCTRAN>\r\n" +
    "<DTSTART>#{wesabe.lang.date.format(dtstart, 'yyyyMMdd')}\r\n" +
    "<INCLUDE>Y\r\n" +
    "</INCTRAN>\r\n" +
    "</CCSTMTRQ>\r\n" +
    "</CCSTMTTRNRQ>\r\n" +
    "</CREDITCARDMSGSRQV1>\r\n"

  _investstmt: (acctid, dtstart) ->
    "<INVSTMTMSGSRQV1>\r\n" +
    "<INVSTMTTRNRQ>\r\n" +
    "<TRNUID>#{@uuid}\r\n" +
    "<CLTCOOKIE>4\r\n" +
    "<INVSTMTRQ>\r\n" +
    "<INVACCTFROM>\r\n" +
    "<BROKERID>#{@fi.ofxBroker}\r\n" +
    "<ACCTID>#{acctid}\r\n" +
    "</INVACCTFROM>\r\n" +
    "<INCTRAN>\r\n" +
    "<DTSTART>#{wesabe.lang.date.format(dtstart, 'yyyyMMdd')}\r\n" +
    "<INCLUDE>Y\r\n" +
    "</INCTRAN>\r\n" +
    "<INCOO>Y\r\n" +
    "<INCPOS>\r\n" +
    "<INCLUDE>Y\r\n" +
    "</INCPOS>\r\n" +
    "<INCBAL>Y\r\n" +
    "</INVSTMTRQ>\r\n" +
    "</INVSTMTTRNRQ>\r\n" +
    "</INVSTMTMSGSRQV1>\r\n"
