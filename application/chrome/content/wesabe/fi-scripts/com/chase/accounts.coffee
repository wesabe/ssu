wesabe.provide 'fi-scripts.com.chase.accounts',
  dispatch: ->
    return unless job.goal is 'statements'

    # only dispatch on authenticated pages
    return unless page.present e.logoff.link

    # Download (Account) Activity
    if page.present e.accounts.page.downloadAccountActivity.indicator
      if tmp.uploading and page.present(e.accounts.page.alreadyDownloadedAccountActivity.indicator)
        # Step 7: Wait for Upload to Finish (then back to Step 3)
        log.debug "Waiting for upload to finish"
        delete tmp.uploading
        return

      # Step 6: Fill out Download Form and Submit
      return action.downloadSelectedAccount() if tmp.account

      # Step 8: Next goal
      return job.nextGoal() if tmp.accounts.length is 0

      # Step 3: Go to Account Activity Page
      tmp.account = tmp.accounts.shift()
      return action.goToNextAccount()

    # Select Download Method
    if page.present e.accounts.page.selectDownloadMethod.indicator
      # Step 5: Choose Download Method (now, free)
      return action.selectDownloadNowMethod()

    # Account Activity
    if page.present e.accounts.page.accountDetail.indicator
      # Step 4: Go to Download Page
      return action.goToDownloadPage()

    # My Accounts
    if page.present e.accounts.page.my.indicator
      # Step 1: Get Account List
      if not tmp.accounts
        action.collectAccounts()
        if tmp.accounts.length is 0
          logger.warn "No accounts found! This is probably a bug."
          page.dumpPrivately()
          return

      # Step 2: Get Account
      if !tmp.account and tmp.accounts.length
        tmp.account = tmp.accounts.shift()

      # Done!
      if !tmp.account and !tmp.accounts.length
        return job.nextGoal()

      # Step 3: Go to Account Activity Page
      return action.goToNextAccount() if tmp.account

  actions:
    goToNextAccount: ->
      browser.go tmp.account

    selectDownloadNowMethod: ->
      page.click e.download.method.choices.now.radio
      page.click e.download.method.continueButton

    collectAccounts: ->
      job.update 'account.list'
      links = page.select e.accounts.page.my.accountLink
      urls  = links.map (link) -> link.href
      urls = wesabe.lang.array.uniq(urls)

      # copy the list so we have a record of all the urls
      tmp.accounts = wesabe.lang.array.from(urls)
      tmp.accounts.original = urls

      wesabe.info "Found accounts: ", tmp.accounts

    goToDownloadPage: ->
      page.click e.accounts.page.accountDetail.downloadActivityLink

    downloadSelectedAccount: ->
      if page.present e.accounts.errors.noDataInRange
        skipAccount "Skipping account for lack of transactions"
        return reload()

      log.debug "Downloading account: ", tmp.account
      job.update 'account.download'

      form = page.findStrict e.download.form.element
      tmp.uploading = true

      page.fill e.download.form.accounts.select, tmp.account if page.present e.download.form.accounts.select
      page.click e.download.form.dateRange.choices.allAvailable
      page.fill e.download.form.format.select, e.download.form.format.ofx
      page.click e.download.form.continueButton

  elements:
    accounts:
      tab:
        indicator: [
          '//*[@class="tabaccountson"][contains(@title, "My Accounts")]'
        ]

        link: [
          '//a[contains(@href, "MyAccounts")][@name="My Accounts"]'
          '//td[@title="Go to My Accounts"]//a'
          '//td[contains(@class, "tabaccounts")]//a'
        ]

      page:
        my:
          indicator: [
            '//*[@class="pageTitle" or @class="pagetitle"][contains(string(.), "My Accounts")][not(contains(string(.), "Loading"))]'
          ]

          accountLink: [
            '//a[contains(@href, "AccountActivity/AccountDetails.aspx?AI=")]'  # bank
            '//a[contains(@href, "Account/AccountDetail.aspx?AI=")]'           # credit
          ]

        accountDetail:
          indicator: [
            '//*[@class="pageTitle" or @class="pagetitle"][contains(string(.), "Account Activity")]'
            '//*[@class="pageTitle" or @class="pagetitle"][contains(string(.), "Account Details")]'
            '//*[@class="pageTitle" or @class="pagetitle"][contains(string(.), "Balances")]'
          ]

          downloadActivityLink: [
            '//a[contains(string(.), "Download Account Activity")]'  # bank
            '//a[contains(string(.), "Download activity")]'          # credit
            '//a[contains(@href, "SelectDownloadMethod.aspx")]'      # credit
            '//a[contains(@href, "DownloadActivity.aspx")]'          # credit
          ]

        selectDownloadMethod:
          indicator: [
            '//*[@class="pageTitle" or @class="pagetitle"][contains(string(.), "Select Download Method")]'
          ]

        downloadAccountActivity:
          indicator: [
            '//*[@class="pageTitle" or @class="pagetitle"][contains(string(.), "Download Account Activity")]'
            '//*[@class="pageTitle" or @class="pagetitle"][contains(string(.), "Download Activity")]'
          ]

        alreadyDownloadedAccountActivity:
          indicator: [
            '//script[contains(string(.), "DownloadActivityFile.aspx")]'
          ]

      errors:
        noDataInRange: [
          '//text()[contains(., "No items have been downloaded")]'
        ]

    customerCenter:
      tab:
        indicator: [
          '//*[@class="tabcustomercenteron"][contains(@title, "Customer Center")]'
        ]

        link: [
          '//a[contains(@href, "CustomerCenter")][@name="Customer Center"]'
          '//td[@title="Go to Customer Center"]//a'
          '//td[contains(@class, "tabcustomercenter")]//a'
        ]

      pfmLink: [
        '//a[contains(@href, "SelectDownloadMethod")]'
        '//a[contains(string(.), "Financial Management Software")]'
      ]

    download:
      method:
        choices:
          now:
            radio: [
              '//input[@name="DownloadMethodGroup"][@value="DownloadNowRadioButton"][@type="radio"]'
              '//form[@name="SelectDownloadMethod"]//input[ancestor::*[contains(@title, "Download now")]][@type="radio"]'
            ]

            cost: [
              '//text()[contains(., "$") or contains(., "no charge")][preceding-sibling::*[contains(string(.), "Download Now")]]'
            ]

          directAccess:
            radio: [
              '//input[@name="DownloadMethodGroup"][@value="ActivateQuickenRadioButton"]'
              '//form[@name="SelectDownloadMethod"]//input[ancestor::*[contains(@title, "Direct Access")]]'
            ]

            cost: [
              '//text()[contains(., "$") or contains(., "no charge")][preceding-sibling::*[contains(string(.), "Activate Direct Access through the PFM service")]]'
            ]

        continueButton: [
          '//input[@type="submit" or @type="image"][@name="ContinueButton"]'
          '//form[@name="SelectDownloadMethod"]//input[@type="submit" or @type="image"]'
        ]

      form:
        element: [
          '//form[@name="DownloadActivity"]'  # bank
          '//form[@name="Form1"]'             # credit
        ]

        accounts:
          select: [
            '//select[@name="UserAccounts"]'
          ]

          options: [
            './/option[not(contains(string(.), "Select Account"))][not(@value="")]'
          ]

        dateRange:
          choices:
            allAvailable: [
              '//input[@name="DateRangeGroup"][@value="WithOutDateRange"][@type="radio"]'  # bank
              '//input[@id="SelectAllTransactions"][@type="radio"]'                        # credit
            ],

            specificRange: [
              '//input[@name="DateRangeGroup"][@value="WithDateRange"][@type="radio"]'   # bank
              '//input[@id="SelectDateRange"][@type="radio"]'                            # credit
            ],

        format:
          select: [
            '//select[@name="DownloadTypes"]' # bank
            '//select[@name="DownloadType"]'  # credit
          ]

          ofx: [
            './/option[@value="OFX"]'
            './/option[contains(string(.), "Microsoft Money")]'
          ]

        continueButton: [
          '//input[@type="submit" or @type="image" or @type="button"][@name="BtnDownloadActivity"]'
          '//form[@name="DownloadActivity"]//input[@type="submit" or @type="image" or @type="button"][@value="Download Activity"]'
        ]
