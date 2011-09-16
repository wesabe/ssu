type = require 'util/type'

wesabe.require 'util.privacy'

# Account - simple data container for account information
class Account
  constructor: (accttype, acctid, bankid, desc) ->
    @accttype = accttype
    @acctid   = acctid
    @bankid   = bankid
    @desc     = desc

    @masked_acctid = @maskAccountId()

  # Mask the account number for this account, replacing all but the
  # last four digits of the account number with 'X's.  See also
  # Response.get_sanitized_response().

  maskAccountId: ->
    return @acctid if @acctid.length <= 4

    ('X' for i in [0...@acctid.length-4]).join('') + @acctid[-4..-1]

wesabe.util.privacy.registerTaintWrapper
  detector: (o) -> type.is(o, Account)
  getters: ["accttype", "acctid", "bankid", "desc", "masked_acctid"]


module.exports = Account
