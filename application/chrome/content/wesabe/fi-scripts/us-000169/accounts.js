wesabe.provide("fi-scripts.us-000169.accounts", {
  dispatch: function() {
    // only dispatch when logged in
    if (!page.present(e.logoff.link)) return;

    if (page.present(e.download.indicator)) {
      if (!tmp.accounts) {
        action.collectAccounts();
      }

      if (!tmp.account && !tmp.accounts.length) {
        return action.logoff();
      }

      if (!tmp.account) {
        tmp.account = tmp.accounts.shift();
      }

      action.downloadSelectedAccount();
    } else if (page.present(e.nav.download.link)) {
      action.goToDownloadPage();
    } else {
      action.goToAccountsSummary();
    }
  },

  actions: {
    goToAccountsSummary: function() {
      page.click(e.nav.accounts.link);
    },

    goToDownloadPage: function() {
      page.click(e.nav.download.link);
    },

    collectAccounts: function() {
      job.update('account.list');

      var options = page.select(e.download.account.options, e.download.account.select);
      tmp.accounts = options.map(function(option) {
        return {name: option.innerHTML, value: option.value};
      });
      log.info("Found accounts: ", tmp.accounts);
    },

    downloadSelectedAccount: function() {
      job.update('account.download');

      log.info("Downloading account: ", tmp.account);
      page.fill(e.download.account.select, tmp.account.value);
      action.fillDateRange();
      page.fill(e.download.format.select, e.download.format.ofx);
      page.click(e.download.continueButton);
    },
  },

  elements: {
    accounts: {
      summary: {
        indicator: [
          '//h1[contains(string(.), "Account Summary")]',
        ],
      },
    },

    download: {
      indicator: [
        '//h1[contains(string(.), "Transaction Download")]',
      ],

      account: {
        select: [
          '//select[@name="ctlAccountDownloadFilterList:cboAccountTypeList"]',
          '//form[@action="Download.aspx"]//select[contains(string(.), "Checking") or contains(string(.), "Savings")]',
        ],

        options: [
          './/option',
        ],
      },

      date: {
        from: [
          '//input[@type="text"][@name="ctlAccountDownloadFilterList:txtFromDate:textBox"]',
        ],

        to: [
          '//input[@type="text"][@name="ctlAccountDownloadFilterList:txtToDate:textBox"]',
        ],
      },

      format: {
        select: [
          '//select[@name="ctlAccountDownloadFilterList:cboDownloadTypeList"]',
          '//form[@action="Download.aspx"]//select[contains(string(.), "Quicken")]',
        ],

        ofx: [
          './/option[@value="ofx" or contains(string(.), "Money")]',
        ],
      },

      continueButton: [
        '//*[@name="ctlAccountDownloadFilterList:btnDownload"]',
        '//input[@type="button" or @type="submit" or @type="image"][@value="Download"]',
        '//form[@action="Download.aspx"]//input[@type="button" or @type="submit" or @type="image"]',
      ],
    },

    nav: {
      accounts: {
        link: [
          '//a[contains(@href, "Accounts/Summary.aspx")][contains(string(.), "Accounts")]',
        ],
      },

      download: {
        link: [
          '//a[contains(@href, "Accounts/Download.aspx")][contains(string(.), "Download")]',
        ],
      },
    },
  },
});
