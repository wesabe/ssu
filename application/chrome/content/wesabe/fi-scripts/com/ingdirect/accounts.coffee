wesabe.provide "fi-scripts.com.ingdirect.accounts",
  dispatch: ->
    return if job.goal isnt "statements"

    tmp.authenticated = page.visible(e.signOffLink)
    return unless tmp.authenticated

    if page.visible e.errors.noTransactionsForPeriod
      logger.warn "No transactions available, skipping account"
      job.nextGoal()
    else if page.visible e.downloadPeriod
      action.downloadActivity()
    else if page.present e.downloadLink
      action.goDownloadPage()
    else
      action.goMyAccountsPage()

  actions:
    goDownloadPage: ->
      job.update "account.download"
      page.click e.downloadLink

    goMyAccountsPage: ->
      job.update "account"
      page.click e.myAccountsNavLink

    downloadActivity: ->
      page.fill e.downloadPeriod, "60"
      page.fill e.downloadAccount, "ALL"
      page.fill e.downloadType, "OFX"
      page.click e.downloadButton

  elements:
    myAccountsNavLink: [
      '//a[@href="/myaccount/INGDirect.html?command=displayAccountSummary"]'
      '//div[@id="tabs"]//a[contains(string(.), "My Accounts")]'
    ]

    #############################################################################
    ## Account List
    #############################################################################

    accountLink: [
      '//a[@href="/myaccount/INGDirect.html?command=goToAccount&account=:n"]'
    ]

    downloadLink: [
      '//a[contains(@href, "download")][contains(string(.), "Download")]'
    ]

    externalLinksLink: [
      '//a[@href="/myaccount/INGDirect/display_external_links.vm"]'
      '//a[contains(@href, "links")][contains(string(.), "My Links")]'
    ]

    #############################################################################
    ## Download Activity
    #############################################################################

    downloadForm: [
      '//form[@name="MainForm" or @id="MainForm"]'
    ]

    downloadType: [
      '//form[@name="MainForm"]//select[@name="type"]'
      '//select[@name="type"]'
    ]

    downloadPeriod: [
      '//form[@name="MainForm"]//select[@name="FREQ"]'
      '//select[@name="FREQ"]'
    ]

    downloadButton: [
      '//a[@name="download"][contains(string(.), "Download")]'
    ]

    # which account (hidden field), should default to ALL, but doesn't always happen
    downloadAccount: [
      '//form[@name="MainForm"]//input[@name="account"]'
      '//input[@name="account"]'
    ]

    errors:
      general: [
        '//*[has-class("errormsg") or has-class("actionmsg")]'
      ]

      sessionExpired: [
        '//*[has-class("actionmsg")][contains(string(text()), "session")][contains(string(text()), "expired")]'
      ]

      # the user entered their pin directly into the field
      pinLettersNotNumbers: [
        '//*[has-class("errormsg")][contains(string(text()), "LETTERS")][contains(string(text()), "NUMBERS")]'
      ]

      noTransactionsForPeriod: [
        '//*[has-class("errormsg") and contains(string(.), "no transactions for the selected timeframe")]'
      ]
