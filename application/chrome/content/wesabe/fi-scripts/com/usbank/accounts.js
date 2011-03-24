wesabe.provide('fi-scripts.com.usbank.accounts', {
  dispatch: function() {
    // only dispatch if we're logged in
    if (!page.present(e.logout.link)) return;

    // no accounts found yet
    if (!tmp.accounts) {
      if (page.present(e.download.account.selector)) {
        action.collectAccounts();
      } else if (page.present(e.nav.download.link)) {
        return action.goDownloadPage();
      } else {
        return log.warn("Could not find any accounts or the link to get to the download page!");
      }
    }

    if (page.present(e.errors.download.noTransactionsInRange)) {
      skipAccount('Skipping account for lack of transactions (account=', tmp.account, ')');
    }

    if (tmp.account) {
      // have account, will download
      return action.beginDownload();
    } else {
      // choose an account to download
      if (!page.present(e.download.account.selector)) {
        return action.goDownloadPage();
      } else if (tmp.accounts.length) {
        tmp.account = tmp.accounts.shift();
        return action.chooseAccount();
      } else {
        // or log out if there are no more
        return action.logout();
      }
    }
  },

  actions: {
    goDownloadPage: function() {
      page.click(e.nav.download.link);
    },

    collectAccounts: function() {
      job.update('account.list');

      var selector = page.findStrict(e.download.account.selector);
      tmp.accounts =
        page
          .select(e.download.account.options, selector)
          .map(function(op){ return {name: op.innerHTML.replace(/^\s+|\s+$/g, ''), value: op.value} });

      log.info("accounts=", tmp.accounts);
    },

    chooseAccount: function() {
      job.update('account.download');
      log.debug('account=', tmp.account);

      page.fill(e.download.account.selector, tmp.account.value); // should trigger reload
    },

    beginDownload: function() {
      page.fill(e.download.format.selector, e.download.format.ofx);
      action.fillDateRange();
      page.click(e.download.continueButton);
    },
  },

  elements: {
    nav: {
      download: {
        link: [
          '//a[contains(text(),"Download Transaction Data")]',
          '//a[contains(@href, "DisplayTransactionDownload")]',
        ],
      },
    },

    download: {
      account: {
        selector: [
          '//form[@name="download"]//select[@name="TDACCOUNTLIST"]',
        ],

        options: [
          './/option[not(@value="")][not(contains(text(), "Select an Account"))]',
        ],
      },

      format: {
        selector: [
          '//form[@name="download"]//select[@name="TDSOFTWARE"]',
        ],

        ofx: 'OFX',
      },

      date: {
        format: 'MM/dd/yy',

        from: [
          '//form[@name="download"]//input[@type="text"][@name="StartDate"]',
        ],

        to: [
          '//form[@name="download"]//input[@type="text"][@name="EndDate"]',
        ],
      },

      continueButton: [
        '//form[@name="download"]//a[img[@alt="Download"]]',
        '//form[@name="download"]//a[img[contains(@src, "download-button")]]',
      ],
    },

    logout: {
      link: [
        '//a[contains(@href, "Logout")]',
        '//a[img[contains(@alt, "Log Out") or contains(@src, "logout") or contains(@src, "logoff")]]',
      ],
    },

    errors: {
      general: [
        '//text()[contains(., "Error Code = A90002")]',
      ],

      login: {
        invalid: [
          '//text()[contains(., "Error Code = A90000")]',
        ],
      },

      download: {
        noTransactionsInRange: [
          '//text()[contains(., "no transaction history for the date range selected")]',
          '//text()[contains(., "Error Code = E0765")]',
        ],
      },
    },
  },
});
