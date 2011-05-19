wesabe.provide('download.OFXPlayer')
wesabe.require('ofx.*')

# public methods

class wesabe.download.OFXPlayer
  DAYS_OF_HISTORY: 365

  @register: (params) ->
    klass = @create(params)

    # make sure we put it where wesabe.require expects it
    wesabe.provide("fi-scripts.#{params.fid}", klass)

    return klass

  @create: (params) ->
    return ->
      # inherit from OFXPlayer
      wesabe.lang.extend(this, wesabe.download.OFXPlayer.prototype)
      # subclass it
      wesabe.lang.extend(this, params)

  #
  # Starts retrieving statements from the FI's OFX server.
  #
  start: (creds) ->
    @creds = creds
    @beginGetAccounts()

  #
  # An opportunity to do post-processing, called by Job.
  #
  finish: ->

  # private methods

  #
  # Gets the list of accounts from the FI, called by #start.
  #
  beginGetAccounts: ->
    # tell the user we're logging in
    @job.update('auth.creds')

    @buildRequest().requestAccountInfo({
      success: (response) =>
        @onGetAccounts(response)

      failure: (response) =>
        @onGetAccountsFailure(response)
    })

  #
  # Handles the response containing the account list.
  #
  onGetAccounts: (response) ->
    @job.update('account.list')

    @accounts = wesabe.taint(response.accounts)
    wesabe.debug('accounts=', @accounts)

    if !@accounts.length
      wesabe.warn('There are no accounts! This might not be right...')

    # start downloading accounts in serial
    @processAccounts()

  #
  # Handles a failure to get the account list.
  #
  onGetAccountsFailure: (response) ->
    wesabe.error('Error retrieving list of accounts!')
    @onOFXError response, ->
      wesabe.warn("Document did not contain an OFX error, so just give up.")
      @job.fail(503, 'fi.unavailable')

  #
  # Processes the next account in the list (FIFO). Called after the
  # accounts list is retrieved and after each upload until there are no
  # more accounts.
  #
  processAccounts: ->
    job = @job
    options = job.options || {}

    job.update('account.download')
    wesabe.tryThrow 'OFXPlayer#processAccounts', (log) =>
      if !@accounts.length
        # no more accounts, we're done
        job.succeed()
        return

      @account = @accounts.shift()
      dtstart = if options.since
                  new Date(options.since)
                else
                  wesabe.lang.date.add(new Date(), -@DAYS_OF_HISTORY * wesabe.lang.date.DAYS)

      @buildRequest().requestStatement @account, {dtstart: dtstart},
        before: =>
          # tell anyone who cares that we're starting to download an account
          job.update('account.download')
          job.timer.start('Download')

        success: (response) =>
          @onDownloadComplete(response)

        failure: (response) =>
          @onDownloadFailure(response)

        after: (response) =>
          job.timer.end('Download')

  #
  # Skips the current account and continues with the rest.
  #
  skipAccount: ->
    if arguments.length
      args = arguments
    else
      args = ["Skipping account=", @account]
    wesabe.warn.apply(wesabe, args)
    delete @account;
    @processAccounts()

  #
  # Handles an unsuccessful OFX response.
  #
  onOFXError: (response, callback) ->
    wesabe.error(response.text)
    if response.ofx
      if response.ofx.isGeneralError()
        @job.fail(503, 'fi.unavailable')
        return
      else if response.ofx.isAuthenticationError()
        @job.fail(401, 'auth.creds.invalid')
        return
      else if response.ofx.isAuthorizationError()
        this.job.fail(403, 'auth.noaccess')
        return;
      # doh! didn't recognize any status
    else
      # wow, this wasn't even an OFX error, it was some sort of
      # HTTP error or something. sometimes happens when passing
      # data to the FI that it didn't expect causing them to
      # send back a 500 Internal Server Error

    # couldn't make sense of what the FI said
    callback.call(this) if wesabe.isFunction(callback)

  #
  # Handles an OFX response containing a statement to be imported.
  #
  onDownloadComplete: (response) ->
    wesabe.trigger('downloadSuccess', [response.statement])

    # done with this account
    @account.completed = true
    delete @account
    # now do the rest
    @processAccounts()

  #
  # Handles a failure to get a statement.
  #
  onDownloadFailure: (response) ->
    wesabe.error('Error retrieving statement for account=', @account)
    if response.ofx?.isGeneralError()
      # Document contained a general error, which often means that they had trouble
      # getting a specific account (or it's not available for download via OFX,
      # yet they list it anyway). Maybe it's ephemeral, maybe not. The prevailing
      # wisdom right now is to just skip the account and go on with our lives.
      wesabe.warn("General error while downloading account: ", response.text)
      @skipAccount()
    else
      # some more serious/unknown error
      @onOFXError response, =>
        # called when there's no clear way to handle the response
        wesabe.warn("Document did not contain an OFX error!")
        @skipAccount()

  #
  # Returns a new Request instance ready to be used.
  #
  buildRequest: ->
    request = new wesabe.ofx.Request(@fi, @creds.username, @creds.password, @job)
    request.appId = @appId if @appId
    request.appVersion = @appVersion if @appVersion
    return request
