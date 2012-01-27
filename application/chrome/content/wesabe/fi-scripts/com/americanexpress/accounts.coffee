wesabe.provide 'fi-scripts.com.americanexpress.accounts',
  dispatch: (browser, page) ->
    return unless @job.goal is 'statements'

    if page.present @e.accounts.download.activity.indicator
      # Download Card Activity
      @download browser, page
    else if page.present @e.accounts.activity.indicator
      # Card Activity
      @goToDownloadPage browser, page
    else if page.present @e.accounts.summary.indicator
      # Summary of Accounts
      @goToActivityPage browser, page

  actions:
    goToActivityPage: (browser, page) ->
      @job.update 'account.list'
      page.click @e.accounts.summary.recentActivityLink

    goToDownloadPage: (browser, page) ->
      # clicking the download link creates an in-page modal dialog that has
      # a hidden input field with the url to go to for OFX downloads, so first
      # we click that link
      page.click @e.accounts.activity.downloadLink
      # and then we navigate to the url we get from the hidden input
      browser.go page.findStrict(@e.accounts.activity.ofxDownloadLinkHiddenField).value

    changeFormat: (browser, page) ->
      page.click @e.accounts.download.activity.format.changeLink

    selectFormat: (browser, page) ->
      page.check @e.accounts.download.format.ofx
      page.click @e.accounts.download.format.continueButton

    download: (browser, page) ->
      activity = @e.accounts.download.activity

      @job.update 'account.download'

      for element in page.select activity.account.container
        name = page.text activity.account.name, element
        last90Days = page.find activity.statements.timeFrame.last90Days, element
        sinceLast = page.find activity.statements.timeFrame.sinceLastDownload, element

        if last90Days
          logger.info "Selecting last 90 days for account: ", name
          page.click last90Days
        else
          log.info "Selecting since last download for account: ", name
          page.click sinceLast

      page.click @e.accounts.download.activity.continueButton

  elements:
    accounts:
      summary:
        indicator: [
          '//div[@id="summary_header"]'
        ]

        recentActivityLink: [
          '//a[contains(@href, "loadEstatement")][contains(string(.), "Recent Activity")]'
          '//a[contains(string(.), "Recent Activity")]'
        ]

      activity:
        indicator: [
          '//a[@id="topLinkDownload"]'
        ]

        downloadLink: [
          '//a[@id="topLinkDownload"]'
        ]

        ofxDownloadLinkHiddenField: [
          '//input[@id="OFXLink"]'
        ]

      download:
        activity:
          indicator: [
            '//text()[contains(., "Download Card Activity")][not(ancestor::a)]'
          ]

          account:
            container: [
              '//div[contains(@id, "cardDetails")]'
            ]

            name: [
              './/*[has-class("cardDescription")]' # relative to container
            ]

          statements:
            timeFrame:
              last90Days: [
                './/input[@type="radio"][@value="download90Days"]'
              ]

              sinceLastDownload: [
                './/input[@type="radio"][@value="downloadSince"]'
              ]

              selectedDatesChoice: [
                './/input[@type="radio"][@value="downloadDates"][contains(@name, "timeFrame")]'
              ]

          continueButton: [
            '//form[@id="DownloadFormBean"]//button[@id="downloadFormButton"]'
            '//button[contains(translate(string(.), "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz"), "DOWNLOAD")]'
          ]
