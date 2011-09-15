wesabe.provide('fi-scripts.com.americanexpress.accounts', {
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
      browser.go(page.findStrict(e.accounts.activity.ofxDownloadLinkHiddenField).value);
    },

    changeFormat: function() {
      page.click(e.accounts.download.activity.format.changeLink);
    },

    selectFormat: function() {
      page.check(e.accounts.download.format.ofx);
      page.click(e.accounts.download.format.continueButton);
    },

    download: function() {
      var activity = e.accounts.download.activity;

      job.update('account.download');

      var accountElements = page.select(activity.account.container);
      accountElements.forEach(function(element) {
        var name = page.find(activity.account.name, element),
            last90Days = page.find(activity.statements.timeFrame.last90Days, element),
            sinceLast = page.find(activity.statements.timeFrame.sinceLastDownload, element);

        if (last90Days) {
          log.info("Selecting last 90 days for account: ", name);
          page.click(last90Days);
        } else {
          log.info("Selecting since last download for account: ", name);
          page.click(sinceLast);
        }
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

              sinceLastDownload: [
                './/input[@type="radio"][@value="downloadSince"]',
              ],

              selectedDatesChoice: [
                './/input[@type="radio"][@value="downloadDates"][contains(@name, "timeFrame")]',
              ],
            },
          },

          continueButton: [
            '//form[@id="DownloadFormBean"]//button[@id="downloadFormButton"]',
            '//button[contains(translate(string(.), "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz"), "DOWNLOAD")]',
          ],
        },
      },
    },
  },
});
