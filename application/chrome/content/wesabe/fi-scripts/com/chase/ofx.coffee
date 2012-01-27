privacy = require 'util/privacy'

wesabe.provide 'fi-scripts.com.chase.ofx',
  # afterDownload: (browser, page) ->
  #   # we need to go back to the card selection page to download
  #   # the next card since there's no way to do it on the download page
  #   if @processingCredit
  #     page.back()

  dispatch: (browser, page) ->
    return unless @job.goal is 'statements'

    ## Download Account Activity (Banking)

    if userAccountsSelect = page.field 'UserAccounts'
      logger.debug "BANKING: Found 'Download Account Activity' page"

      if not @accounts
        job.update 'account.list'
        @accounts = (option.value for option in userAccountsSelect.options when option.value?.length > 0)
        logger.info "BANKING: Found ", @accounts.length, " account(s)"

      if @account = @accounts.shift()
        logger.info "BANKING: Processing account ", privacy.taint(@account)
        job.update 'account.download'
        page.fill userAccountsSelect, @account
        page.fill (page.field 'DownloadTypes'), 'OFX'
        page.click page.button 'Download Activity'
      else if @accounts.length is 0
        logger.info "BANKING: Finished processing accounts"
        @hasProcessedBanking = yes
        delete @accounts
        delete @account
        page.click page.link 'Customer Center'

      return

    ## Select Account (Credit)

    if cardAccountsSelect = page.field 'AI'
      logger.debug "CREDIT: Found 'Select Account' page"
      nextButton = page.button 'Next'

      if not @accounts
        job.update 'account.list'
        @accounts = (option.value for option in cardAccountsSelect.options when option.value?.length > 0)
        logger.info "CREDIT: Found ", @accounts.length, " account(s)"

      if @account = @accounts.shift()
        logger.info "CREDIT: Processing account ", privacy.taint(@account)
        @processingCredit = yes
        page.fill cardAccountsSelect, @account
        page.click nextButton
      else if @accounts.length is 0
        logger.info "CREDIT: Finished processing accounts"
        @hasProcessedCredit = yes
        delete @accounts
        delete @account
        page.click page.link 'Customer Center'

      return

    ## Download Activity (Credit)

    if formatSelect = page.field 'DownloadType'
      logger.debug "CREDIT: Found 'Download Activity' page"

      if page.present '//*[has-class("confrow")][contains(string(.), "Transaction Complete")]'
        logger.info "CREDIT: Download succeeded"
        page.click page.link 'Customer Center'
      else if page.present '//*[has-class("errorRow")][contains(lower-case(string(.)), "unable to complete your request")]'
        logger.warn "CREDIT: Failed to download account - there may not be any recent transactions for this account"
        page.click page.link 'Customer Center'
      else
        job.update 'account.download'
        page.fill formatSelect, 'OFX'
        page.click page.button 'Download Activity'

      return

    ## Select Download Method

    if downloadNowOption = page.field 'DownloadNowRadioButton'
      logger.debug "BANKING: Found 'Select Download Method' page"
      page.click downloadNowOption
      page.click page.button 'Continue'

      return

    ## Customer Center

    if not @hasProcessedBanking
      if financialManagementSoftwareLink = page.link 'Financial Management Software'
        logger.debug "BANKING: Navigating to download center"
        return page.click financialManagementSoftwareLink

    if not @hasProcessedCredit
      if downloadActivityLink = page.link 'Download activity'
        logger.debug "CREDIT: Navigating to download center"
        return page.click downloadActivityLink

    if @hasProcessedBanking and @hasProcessedCredit
      @job.nextGoal()
      return

    ## My Accounts

    if customerCenterLink = (page.link 'Go to Customer Center') or (page.link 'Customer Center')
      return page.click customerCenterLink
