wesabe.download.Player.register
  fid: 'com.etrade'
  org: 'E*Trade'

  dispatchFrames: false
  afterDownload: 'nextAccount'
  afterLastGoal: 'logout'

  actions:
    main: ->
      wesabe.dom.browser.go browser, "https://us.etrade.com/e/t/user/login"

    login: ->
      job.update 'auth.creds'
      page.fill e.loginUserIdField, answers.username
      page.fill e.loginPasswordField, answers.password
      page.click e.loginButton

    goDownloadPage: ->
      job.update 'account.download'
      wesabe.dom.browser.go browser, "https://bankus.etrade.com/e/t/ibank/downloadofxtransactions"

    beginDownloads: ->
      options = page.select(e.downloadAccountOption)
      tmp.accounts = options.map (option) -> option.value
      log.debug 'found ', tmp.accounts.length, ' account(s)'
      log.radioactive 'accounts=', tmp.accounts

    chooseAccount: ->
      # should trigger a page change
      page.fill e.downloadAccountSelect, tmp.account

    download: ->
      page.check e.downloadFormatMoney
      page.click e.downloadButton

    logout: ->
      job.succeed()
      page.click e.logoutButton

  dispatch: ->
    if not page.visible e.logoutButton
      if page.visible e.errorInvalidUsernameOrPassword
        job.fail 401, 'auth.creds.invalid'
      else if page.visible e.loginUserIdField
        action.login()
    else
      # on the download page?
      if page.visible e.downloadFormatMoney
        # get the account list
        if not tmp.accounts
          action.beginDownloads()

        if tmp.account
          wesabe.debug "DOWNLOADING: ", tmp.account
          action.download()
        else if not tmp.accounts.length
          job.nextGoal()
        else
          wesabe.debug "GETTING NEXT ACCOUNT"
          tmp.account = tmp.accounts.shift()
          action.chooseAccount()
      else
        action.goDownloadPage()

  elements:
    #############################################################################
    ## login
    #############################################################################

    loginUserIdField: [
      '//form[@name="LOGIN_FORM"]//input[@name="USER"]'
      '//input[@name="USER"]'
      '//form[@name="LOGIN_FORM"]//input[@type="text"]'
      '//input[@type="text"]'
    ]

    loginPasswordField: [
      '//form[@name="LOGIN_FORM"]//input[@name="PASSWORD"]'
      '//input[@name="PASSWORD"]'
      '//form[@name="PASSWORD"]//input[@type="text"]'
      '//input[@type="text"]'
    ]

    loginButton: [
      '//form[@name="LOGIN_FORM"]//input[@name="Logon" and (@type="image" or @type="submit")]'
      '//form[@name="LOGIN_FORM"]//input[@type="image" or @type="submit"]'
      '//input[@name="Logon" and (@type="image" or @type="submit")]'
      '//input[@type="image" or @type="submit"]'
    ]


    #############################################################################
    ## download page
    #############################################################################

    downloadAccountSelect: [
      '//form[@name="downloadForm"]//select[@name="AcctNum"]'
      '//select[@name="AcctNum"]'
      '//form[@name="downloadForm"]//select'
    ]

    downloadAccountOption: [
      '//form[@name="downloadForm"]//select[@name="AcctNum"]/option'
      '//select[@name="AcctNum"]/option'
      '//form[@name="downloadForm"]//select/option'
    ]

    downloadFormatMoney: [
      '//form[@name="downloadForm"]//input[@name="DownloadFormat" and @value="msmoney"]'
      '//input[@name="DownloadFormat" and @value="msmoney"]'
    ]

    downloadButton: [
      '//form[@name="downloadForm"]//input[@type="image" or @type="submit"]'
      '//input[@type="image" or @type="submit"]'
    ]

    logoutButton: [
      '//a[contains(@href, "logout")]'
    ]

    errorInvalidUsernameOrPassword: [
      '//*[contains(string(.), "user ID or password you entered does not match our records")]'
    ]
