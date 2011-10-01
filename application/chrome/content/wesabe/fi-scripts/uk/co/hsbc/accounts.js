wesabe.provide('fi-scripts.uk.co.hsbc.accounts', {
  dispatch: function() {
    // My accounts
    if (page.present(e.accounts.page.listing.indicator)) {
      if (!tmp.accounts) {
        action.collectAccounts();
      }

      if (!tmp.account) {
        if (!tmp.accounts.length) {
          return action.logoff();
        }

        tmp.account = tmp.accounts.shift();
      }

      return action.goToAccountPage();
    }

    // An error, like "no transactions available"
    var downloadError = page.find(e.accounts.page.downloadError.indicator);
    if (downloadError) {
      skipAccount("skipping account because of the following error: ", downloadError);
    }

    if (!tmp.account && page.present(e.accounts.nav.myAccounts.link)) {
      return action.goToMyAccounts();
    }

    // View/download transactions (credit card downloads)
    if (page.present(e.accounts.page.downloadCredit.indicator)) {
      return action.downloadCredit();
    }

    // Recent transactions (download step 1)
    if (page.present(e.accounts.page.downloadStep1.indicator)) {
      return action.downloadStep1();
    }

    // Recent transactions (download step 2)
    if (page.present(e.accounts.page.downloadStep2.indicator)) {
      return action.downloadStep2();
    }

    // Recent transactions (listing)
    if (page.present(e.accounts.page.txactionList.indicator)) {
      return action.goToDownloadPage();
    }
  },

  actions: {
    collectAccounts: function() {
      job.update('account.list');

      var keys =
        wesabe.lang.array.uniq(
          page.select(e.accounts.page.listing.activeAccountKey)
            .map(function(el){ return el.value }));

      tmp.accounts = keys.map(function(key) {
        var link = page.findStrict(bind(e.accounts.page.listing.accountLink, {value: key}));
        return {key: key, name: link.innerHTML};
      });

      log.info('found accounts=', tmp.accounts);
    },

    goToMyAccounts: function() {
      page.click(e.accounts.nav.myAccounts.link);
    },

    goToAccountPage: function() {
      log.info("going to account ", tmp.account);
      page.click(bind(e.accounts.page.listing.accountLink, {value: tmp.account.key}));
    },

    goToDownloadPage: function() {
      job.update('account.download');
      page.click(e.accounts.page.txactionList.downloadLink);
    },

    downloadCredit: function() {
      page.fill(e.accounts.page.downloadCredit.period.select, e.accounts.page.downloadCredit.period.current);
      page.fill(e.accounts.page.downloadCredit.format.select, e.accounts.page.downloadCredit.format.ofx);
      page.click(e.accounts.page.downloadCredit.continueButton);
    },

    downloadStep1: function() {
      page.fill(e.accounts.page.downloadStep1.format.select, e.accounts.page.downloadStep1.format.ofx);
      page.click(e.accounts.page.downloadStep1.continueButton);
    },

    downloadStep2: function() {
      page.click(e.accounts.page.downloadStep2.continueButton);
    },

    logoff: function() {
      page.click(e.logoff.button);
      job.succeed();
    },
  },

  elements: {
    accounts: {
      page: {
        listing: {
          indicator: [
            '//h1[contains(string(.), "My accounts")]',
          ],

          activeAccountKey: [
            '//input[@name="ActiveAccountKey"]',
          ],

          accountLink: [
            '//td[position()=1]//form[contains(@action, "recent-transaction") or contains(@action, "credit-card-transactions")]//a[../input[@name="ActiveAccountKey"][@value=":value"]]',
            '//td//form[contains(@action, "recent-transaction") or contains(@action, "credit-card-transactions")]//a[../input[@name="ActiveAccountKey"][@value=":value"]]',
          ],
        },

        txactionList: {
          indicator: [
            '//h1[contains(string(.), "Recent transactions")]',
            '//h1[contains(string(.), "View statements and more recent transactions")]',
          ],

          downloadLink: [
            // bank
            '//a[@title="Download the transactions displayed on this page"]',
            '//a[contains(@href, "DownloadTransactionHistoryCommand")]',
            '//a[contains(string(.), "Download transactions")]',
            // credit
            '//a[@title="View/download more transactions"]',
            '//a[contains(@href, "cmd_download_transactions")]',
            '//a[contains(string(.), "download more transactions")]',
          ],
        },

        downloadError: {
          indicator: [
            '//text()[contains(., "You have no transactions to display")]',
            '//text()[contains(., "currently no transactions on your account")]',
            '//text()[contains(., "no transactions to display")]',
          ],
        },

        downloadCredit: {
          indicator: [
            '//text()[contains(., "View/download transactions")]',
          ],

          format: {
            select: [
              '//select[@name="formats"]',
              '//select[.//option[contains(@value, "OFX")]]',
            ],

            ofx: [
              './/option[@value="OFX1"]',
              './/option[contains(string(.), "Money 98 onwards (OFX)")]',
              './/option[contains(@value, "OFX")]',
              './/option[contains(string(.), "OFX")]',
            ],
          },

          period: {
            select: [
              '//select[@name="transactionPeriodSelected"]',
              '//select[.//option[contains(@value, "CURRENTPERIOD")]]',
            ],

            current: [
              './/option[contains(@value, "CURRENTPERIOD")]',
            ],
          },

          continueButton: [
            '//a[contains(string(.), "Download transactions")]',
            '//a[contains(@title, "Download transactions")]',
          ],
        },

        downloadStep1: {
          indicator: [
            '//text()[contains(., "Download transactions - step 1 of 2")]',
          ],

          format: {
            select: [
              '//select[@name="downloadType"]',
              '//select[.//option[contains(@value, "OFX")]]',
            ],

            ofx: [
              './/option[@value="M_OFXMainstream"]',
              './/option[contains(string(.), "Money 98 onwards (OFX)")]',
              './/option[contains(@value, "OFX")]',
              './/option[contains(string(.), "OFX")]',
            ],
          },

          continueButton: [
            '//a[contains(string(.), "Continue")]',
            '//a[contains(@title, "Continue")]',
          ],
        },

        downloadStep2: {
          indicator: [
            '//text()[contains(., "Download transactions - step 2 of 2")]',
          ],

          continueButton: [
            '//a[contains(string(.), "Confirm")]',
            '//a[contains(@title, "Confirm")]',
          ],
        },
      },

      nav: {
        myAccounts: {
          link: [
            '//a[contains(string(.), "My accounts")]',
            '//a[@title="My accounts"]',
          ],
        },
      },
    },
  },
});
