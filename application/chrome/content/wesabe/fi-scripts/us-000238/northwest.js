wesabe.provide('fi-scripts.us-000238.northwest', {
  dispatch: function() {
    // only dispatch if we're on the northwest site
    if (!page.present(e.nw.indicator)) return;

    if (page.present(e.nw.errors.noTransactions) && tmp.account) {
      // this account has no transactions, so skip it
      skipAccount("No transactions for account (account=", tmp.account, ")");
    }

    if (page.present(e.nw.page.balanceSheet.indicator)) {
      // we're on the landing page (i.e. Balance Sheet)

      if (!tmp.accounts) {
        // no account list yet, get it
        action.nwCollectAccounts();
      }

      // already collected the account list
      if (!tmp.accounts.length) {
        // no more accounts to process
        action.nwLogoff();
      } else {
        // still have accounts left to process
        tmp.account = tmp.accounts.shift();
        action.nwGoAccount();
      }
    } else if (page.present(e.nw.page.downloadConfirm.indicator)) {
      // on the download confirmation page

      if (!tmp.account) {
        // no account, go back to the Balance Sheet
        action.nwGoBalanceSheet();
      } else {
        // yes, we do want to download this account
        action.nwConfirmDownload();
      }
    } else if (page.present(e.nw.page.account.indicator)) {
      // we're on an account page (e.g. Myaccess Checking)

      if (!tmp.account) {
        // no account, go back to the Balance Sheet
        action.nwGoBalanceSheet();
      } else {
        if (page.present(e.nw.page.downloadForm.indicator)) {
          // on the download form page
          action.nwComplexDownloadForm();
        } else if (page.present(e.nw.account.download.button)) {
          // downloads are available
          if (page.present(e.nw.account.download.types.selector)) {
            // old-style download form
            action.nwStartSimpleDownload();
          } else {
            // new-style download page
            action.nwStartComplexDownload();
          }
        } else {
          // downloads not available?
          skipAccount("I don't see a download link, so skipping (account=", tmp.account, ")");
          action.nwGoBalanceSheet();
        }
      }
    } else {
      return true; // tell the dispatcher to continue, as I didn't handle this page
    }

    return false; // handled this page, stop dispatch chain
  },

  actions: {
    nwGoBalanceSheet: function() {
      // click the "Balance Sheet" link in the left nav
      page.click(e.nw.nav.balanceSheet.link);
    },

    nwCollectAccounts: function() {
      // get a list of account links
      var accountLinks = page.select(wesabe.xpath.bind(e.nw.account.link, {n: ''}));
      // get the ids of all the accounts
      tmp.accounts = accountLinks.map(function(link) {
        return link.href.replace(/^.*accountHistory\.jsp\?idKey=(\d+).*$/i, '$1');
      });
      log.info('accounts=', tmp.accounts);
    },

    nwGoAccount: function() {
      // click the link on the Balance Sheet for the current account
      page.click(wesabe.xpath.bind(e.nw.account.link, {n: tmp.account}));
    },

    // FIXME: <brian@wesabe.com> 2008-12-10: The simple -> complex change may apply to all NW accounts
    // account page has both the format dropdown and the download link
    nwStartSimpleDownload: function() {
      log.debug("download page type is simple");
      // choose OFX
      page.fill(e.nw.account.download.types.selector, e.nw.account.download.types.ofx);
      // click the "Download" button
      page.click(e.nw.account.download.button);
    },

    // FIXME: <brian@wesabe.com> 2008-12-10: The simple -> complex change may apply to all NW accounts
    // account page has only the format dropdown
    nwStartComplexDownload: function() {
      log.debug("download page type is complex");
      // click the "Download" button
      page.click(e.nw.account.download.button);
    },

    // FIXME: <brian@wesabe.com> 2008-12-10: The simple -> complex change may apply to all NW accounts
    nwComplexDownloadForm: function() {
      // Step 1: Select Account
      // already selected
      // Step 2: Choose Date
      page.click(e.nw.account.download.complex.date.period.option);
      page.fill(e.nw.account.download.complex.date.period.select, e.nw.account.download.complex.date.period.sixtyDays);
      // Step 3: Choose File Type
      page.click(e.nw.account.download.complex.type.ofx);
      // Step 4: Download
      page.click(e.nw.account.download.complex.continueButton);
    },

    nwConfirmDownload: function() {
      // click the "Continue with download" button
      page.click(e.nw.account.download.confirmation.button);
    },

    nwLogoff: function() {
      page.click(e.nw.logoff.link);
      job.succeed();
    },
  },

  elements: {
    nw: {
      indicator: [
        '//table[@id="contentLeftnav"]//*[@title="View My Accounts"][contains(string(.), "Balance Sheet")]',
      ],

      page: {
        balanceSheet: {
          indicator: [
            '//*[name()="h1" or contains(@class, "h1Text")][contains(string(.), "Balance Sheet")]',
          ],
        },

        account: {
          indicator: [
            '//form[@id="acctHist"]',
            '//a[@id="downloadButton" or contains(string(.), "Download")]',
          ],
        },

        downloadForm: {
          indicator: [
            '//form[@name="acctHistDownload"]',
            '//*[name()="h1" or contains(@class, "h1Text")][contains(string(.), "Download Transactions")]',
          ],
        },

        downloadConfirm: {
          indicator: [
            '//*[name()="h1" or contains(@class, "h1Text")][contains(string(.), "Account Detail Download")]',
            '//text()[contains(., "Continue with download")]',
            '//*[attribute::*="Continue with download"]',
          ],
        },
      },

      errors: {
        noTransactions: [
          '//*[@class="alertError"][contains(string(.), "The time period you have requested to download has no posted transactions.")]',
        ],
      },

      nav: {
        balanceSheet: {
          cell: [
            '//table[@id="contentLeftnav"]//td[contains(string(.), "Balance Sheet")]',
          ],

          link: [
            '//table[@id="contentLeftnav"]//a[contains(string(.), "Balance Sheet")]',
          ],
        },
      },

      account: {
        link: [
          '//a[contains(@href, "accountHistory.jsp?idKey=:n")]',
        ],

        download: {
          button: [
            '//a[@id="downloadButton" or contains(string(.), "Download")]',
          ],

          types: {
            selector: [
              '//select[@name="filetype"]',
              '//select[.//option[contains(string(.), "Quicken") or contains(string(.), "OFX")]]',
            ],

            ofx: [
              './/option[@value="OFX"]',
              './/option[contains(string(.), "OFX")]',
            ],
          },

          // FIXME: <brian@wesabe.com> 2008-12-10: The simple -> complex change may apply to all NW accounts
          complex: {
            date: {
              // pre-defined date ranges
              period: {
                option: [
                  '//form[@name="acctHistDownload"]//input[@type="radio"][@name="chooseDate"][@value="chooseDatePeriod"]',
                  '//form[@name="acctHistDownload"]//input[@type="radio"][@id="chooseDatePeriod"]',
                  '//input[@type="radio"][@name="chooseDate"][@value="chooseDatePeriod"]',
                  '//input[@type="radio"][@id="chooseDatePeriod"]',
                ],

                select: [
                  '//form[@name="acctHistDownload"]//select[@name="selectPeriod"]',
                  '//select[@name="selectPeriod"]',
                  '//form[@name="acctHistDownload"]//select[contains(string(.), "30 days")]',
                ],

                sixtyDays: [
                  './/option[contains(string(.), "60 days")]',
                ],
              },

              // user-defined date ranges
              range: {
                option: [
                  '//form[@name="acctHistDownload"]//input[@type="radio"][@name="chooseDate"][@value="chooseDateRange"]',
                  '//form[@name="acctHistDownload"]//input[@type="radio"][@id="chooseDateRange"]',
                  '//input[@type="radio"][@name="chooseDate"][@value="chooseDateRange"]',
                  '//input[@type="radio"][@id="chooseDateRange"]',
                ],

                from: [
                  '//form[@name="acctHistDownload"]//input[@type="text"][@name="dateRangeBegin"]',
                ],

                to: [
                  '//form[@name="acctHistDownload"]//input[@type="text"][@name="dateRangeEnd"]',
                ],
              },
            },

            type: {
              ofx: [
                '//form[@name="acctHistDownload"]//input[@type="radio"][@name="chooseFileType"][@value="OFX"]',
                '//form[@name="acctHistDownload"]//input[@type="radio"][@id="chooseFileTypeOFX"]',
              ],
            },

            continueButton: [
              '//form[@name="acctHistDownload"]//a[contains(string(.), "Download Transactions")]',
              '//form[@name="acctHistDownload"]//a[contains(@href, "doDownload")]',
            ],
          },

          confirmation: {
            button: [
              '//input[(@type="button" or @type="image" or @type="submit") and @name="exp"]',
              '//input[(@type="button" or @type="image" or @type="submit") and contains(@onclick, "doExport()")]',
              '//input[contains(@value, "Continue with download")]',
            ],
          },
        },
      },

      logoff: {
        link: [
          '//a[contains(@href, "logoff") and contains(string(.), "Sign Off")]',
          '//a[@href="JavaScript:logoff();"]',
          '//*[@class="masthead"]//a[contains(@href, "logoff") or contains(string(.), "Sign Off")]',
        ],
      },
    },
  },
});
