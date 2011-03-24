// This is the login part of the Vancity
// script, included by com.vancity.js one level up.
//
// This part handles logging in, and contains all the
// logic and page element references related to it.
//
wesabe.provide("fi-scripts.com.vancity.accounts", {
  dispatch: function() {
    if (!page.present(e.logoff.link)) return;

    if (page.present(e.accounts.download.warningForm.indicator)) {
      action.bypassDownloadWarning();
    } else if (page.present(e.accounts.download.preparationForm.indicator)) {
      action.prepareDownload();
    } else {
      action.goToDownloadPage();
    }
  },

  actions: {
    prepareDownload: function() {
      job.update('account.download.prepare');

      // fillDateRange requires e.download.from and e.download.to
      e.download = e.accounts.download.preparationForm;
      action.fillDateRange();

      page.fill(e.download.accounts.select, e.download.accounts.options.all);
      page.check(e.download.downloadTransactionsCheckbox);
      page.fill(e.download.type.select, e.download.type.options.ofx);
      page.click(e.download.continueButton);
    },

    bypassDownloadWarning: function() {
      page.click(e.accounts.download.warningForm.continueButton);
    },

    goToDownloadPage: function() {
      page.click(e.accounts.nav.activityLink);
    },
  },

  elements: {
    accounts: {
      nav: {
        activityLink: [
          '//a[contains(@href, "/OnlineBanking/Accounts/Activity")]',
        ],
      },

      download: {
        preparationForm: {
          indicator: [
            '//form[contains(@action, "Accounts/Activity")]',
          ],

          accounts: {
            select: [
              '//select[@name="fromAcct"]',
            ],

            options: {
              all: [
                './/option[@value="-3" or contains(string(.), "All Accounts")]',
              ],
            },
          },

          date: {
            from: [
              '//input[@name="StartDateValue"]',
            ],

            to: [
              '//input[@name="EndDateValue"]',
            ],

            options: {
              range: [
                '//input[@type="radio"][@name="RadioTimeTypeValue"][@value="DateRangeFilter"]',
              ],
            },
          },

          downloadTransactionsCheckbox: [
            '//input[@type="checkbox"][@name="DownloadOptionCheckBox"]',
          ],

          type: {
            select: [
              '//select[@name="stype"]',
            ],

            options: {
              ofx: [
                './/option[@value="MONEY" or contains(string(.), "Microsoft Money")]',
              ],
            },
          },

          continueButton: [
            '//input[@type="submit" or @type="image"][@id="getAccountActivity"]',
          ],
        },

        warningForm: {
          indicator: [
            '//form[@id="DownloadWarning"]',
          ],

          continueButton: [
            '//form[@id="AccountHistory"]//input[@type="submit" or @type="image"][@name="CONTINUE_DOWNLOAD"]',
            '//input[@type="submit" or @type="image"][@name="CONTINUE_DOWNLOAD"]',
          ],
        },
      },
    },
  },
});
