wesabe.provide('fi-scripts.us-003383.accounts', {
  dispatch: function() {
    if (page.present(e.accounts.download.activity.indicator)) {
      // Download Card Activity
      action.download();
    } else if (page.present(e.accounts.activity.indicator)) {
      // Card Activity
      action.goToDownloadPage();
    } else if (page.present(e.accounts.summary.indicator)) {
      // Summary of Accounts
      action.goToActivityPage();
    }
  },

  actions: {
    goToActivityPage: function() {
      job.update('account.list');
      page.click(e.accounts.summary.recentActivityLink);
    },

    goToDownloadPage: function() {
      // clicking the download link creates an in-page modal dialog that has
      // a hidden input field with the url to go to for OFX downloads, so first
      // we click that link
      page.click(e.accounts.activity.downloadLink);
      // and then we navigate to the url we get from the hidden input
      wesabe.dom.browser.go(browser, page.findStrict(e.accounts.activity.ofxDownloadLinkHiddenField).value);
    },

    changeFormat: function() {
      page.click(e.accounts.download.activity.format.changeLink);
    },

    selectFormat: function() {
      page.check(e.accounts.download.format.ofx);
      page.click(e.accounts.download.format.continueButton);
    },

    download: function() {
      job.update('account.download');

      var accountElements = page.select(e.accounts.download.activity.account.container);
      accountElements.forEach(function(element) {
        var name = page.find(e.accounts.download.activity.account.name, element);
        log.info("Selecting last 90 days for account: ", name);
        // choose last 90 days
        page.click(page.findStrict(e.accounts.download.activity.statements.timeFrame.last90Days, element));
      });

      page.click(e.accounts.download.activity.continueButton);
    },
  },

  elements: {
    accounts: {
      summary: {
        indicator: [
          '//div[@id="summary_header"]',
        ],

        recentActivityLink: [
          '//a[contains(@href, "loadEstatement")][contains(string(.), "Recent Activity")]',
          '//a[contains(string(.), "Recent Activity")]',
        ],
      },

      activity: {
        indicator: [
          '//a[@id="topLinkDownload"]',
        ],

        downloadLink: [
          '//a[@id="topLinkDownload"]',
        ],

        ofxDownloadLinkHiddenField: [
          '//input[@id="OFXLink"]',
        ],
      },

      download: {
        activity: {
          indicator: [
            '//text()[contains(., "Download Card Activity")][not(ancestor::a)]',
          ],

          account: {
            container: [
              '//div[contains(@id, "cardDetails")]',
            ],

            name: [
              './/*[@class="cardDesc"]', // relative to container
            ],
          },

          statements: {
            timeFrame: {
              last90Days: [
                './/input[@type="radio"][@value="download90Days"]',
              ],

              selectedDatesChoice: [
                './/input[@type="radio"][@value="downloadDates"][contains(@name, "timeFrame")]',
              ],
            },
          },

          continueButton: [
            '//a[@onclick][contains(string(.), "DOWNLOAD")]',
            '//form[contains(@name, "Download")]//input[@type="submit" or @type="image"]',
          ],
        },
      },
    },
  },
});
