wesabe.provide('fi-scripts.com.bankofamerica.accounts', {
  actions: {
    goAccountOverview: function() {
      page.click(e.accountsTab);
    },

    goDownloadPage: function() {
      page.click(e.accountDetailDownloadLink);
    },

    collectAccounts: function() {
      job.update('account.list');

      var accounts = page.select(e.overviewAccountLinks);
      tmp.accounts = wesabe.lang.array.uniq(accounts.map(function(a) {
        return a.getAttribute('href');
      }));
      log.debug('accounts=', tmp.accounts);
    },

    chooseAccount: function() {
      browser.go(tmp.account);
    },

    downloadSelectedAccount: function() {
      job.update('account.download');

      // set download format
      if (page.visible(e.downloadFormatMoney))
        page.check(e.downloadFormatMoney);  // Bank

      if(page.visible(e.downloadErrorBadDateRange)) {
        page.check(e.downloadCompletePeriodOption);
      } else {
        // set download date range
        if (page.visible(e.downloadTransactionRangeOption)) {
          action.fillDateRange();
          page.check(e.downloadTransactionRangeOption);
        }
      }

      // start download
      page.click(e.downloadButton);
    },

    logout: function() {
      job.succeed();
      page.click(e.logoutButton);
    },
  },

  dispatch: function() {
    // only dispatch if we're not on the mobile site
    if (page.present(e.mobile.indicator)) return;
    // only dispatch if we're not on the northwest site
    if (page.present(e.nw.indicator)) return;

    tmp.authenticated = page.visible(e.logoutButton);
    if (!tmp.authenticated) return;

    if (tmp.account) {
      if (page.present(e.downloadErrorNoTransactions) ||
          page.present(e.downloadErrorNoStatements)) {
        // we tried to download it but there weren't any
        // transactions in the range we chose, skip it
        skipAccount('Skipping account for lack of transactions ', tmp.account);
        reload();
      } else if (page.present(e.downloadErrorNotAvailableForBusinessCredit)) {
        // apparently bofa is able to list certain Business accounts but is
        // unable to interact with them except to get the balance
        skipAccount('Cannot load account detail for Business account (account=',tmp.account,')');
        reload();
      } else if (page.visible(e.accountDetailDownloadLink)) {
        action.goDownloadPage();
      } else if (page.visible(e.downloadButton)) {
        // account has been selected but not downloaded
        action.downloadSelectedAccount();
      } else if (page.present(e.detail.tab.selected)) {
        // bofa doesn't offer downloads for some types, like CDs and mortgages
        var title = page.find(e.detail.title);
        log.warn('title=', title);
        title = title && wesabe.lang.string.trim(title.innerHTML);

        skipAccount("This account doesn't offer downloads and will be skipped ",
                 "(account=",tmp.account,", title=",title,")");
        reload();
      } else {
        action.chooseAccount();
      }
    } else {
      if (!tmp.accounts) {
        if (page.visible(e.overviewAccountLinks)) {
          action.collectAccounts();
        } else {
          action.goAccountOverview();
          return;
        }
      }

      // account has not been selected yet -- do we have any more?
      if (tmp.accounts.length) {
        tmp.account = tmp.accounts.shift();
        action.goAccountOverview();
      } else {
        action.logout();
      }
    }
  },

  elements: {
    /////////////////////////////////////////////////////////////////////////////
    // account overview
    /////////////////////////////////////////////////////////////////////////////

    accountsTab: [
      '//a[contains(@href, "GotoWelcome")]',                                          // bank
      '//li/a[contains(@href, "acctoverview") and contains(string(.), "Accounts")]',  // credit

      // 2011 redesign
      '//a[contains(@href, "/accounts-overview")][contains(string(.), "Accounts Overview")]',
    ],

    overviewAccountLinks: [
      '//a[contains(@href, "target=acctDetails")]' // 2011 redesign
    ],

    welcomeAccountDetailLink: [
      '//a[contains(@href, "GotoOnlineStatement")]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // account detail
    /////////////////////////////////////////////////////////////////////////////

    accountDetailDownloadLink: [
      '//a[contains(@href, "h2_recent_statements.el_uif") and contains(string(.), "Download")]', // credit
      '//a[contains(@href, "AccountActivityControl") and contains(string(.), "Download")]',      // bank
      '//a[contains(@href, "h2_recent_statements.el_uif")]',                                     // credit
      '//a[contains(@href, "AccountActivityControl?bofaAction=0")]'                              // bank
    ],

    detail: {
      tab: {
        selected: [
          '//li[@class="currentTab" and (contains(string(.), "Account Detail") or .//a[contains(@href, "GotoOnlineStatement")])]',
        ],
      },

      title: [
        '//h1[@class="title1"]',
      ],
    },

    /////////////////////////////////////////////////////////////////////////////
    // download page
    /////////////////////////////////////////////////////////////////////////////

    downloadFormatMoney: [
      '//form[@name="theForm"]//input[@name="downloadtype" and @value="MSMoneyFmt"]',
      '//input[@name="downloadtype" and @value="MSMoneyFmt"]'
    ],

    downloadErrorNoStatements: [
      '//form[@name="downloadform"]//select[@name="STMT" and count(option)=0]',
      '//select[@name="STMT" and count(option)=0]',
      '//form[@name="downloadform"]//select[count(option)=0]'
    ],

    downloadButton: [
      '//form[@name="theForm"]//a[contains(@href, "Download")]',                                                  // bank
      '//input[contains(@onclick, "downloadStatement")]',                                                         // credit
      '//a[contains(@href, "Download")][not(contains(string(.), "Help"))][not(contains(@href, "help"))]',         // bank
      '//input[@value="Download Statements"]',                                                                    // credit
      '//a[contains(@href, "downloadStatement")][contains(string(.), "Download")]',                               // business credit
    ],

    downloadErrorNoTransactions: [
      '//*[contains(string(.), "download has no posted transactions")]',
      '//*[contains(string(.), "no transactions available for the period you have selected")]',
    ],

    downloadErrorBadDateRange: [
      '//label[@for="fromDate"]//span[@class="error"]',
      '//*[contains(string(.), "correct date range")]',
    ],

    downloadCompletePeriodOption: [
      '//form[@name="theForm"]//input[@type="radio" and @name="DownloadPeriod" and @value="stmntPeriods"]'
    ],

    downloadTransactionRangeOption: [
      '//form[@name="theForm"]//input[@type="radio" and @id="transactionRange"]'
    ],

    download: {
      date: {
        from: [
          '//form[@name="theForm"]//input[@type="text" and @name="fromDate"]'
        ],

        to: [
          '//form[@name="theForm"]//input[@type="text" and @name="toDate"]'
        ],
      }
    },

    downloadDatePeriods: [
      '//form[@name="theForm"]//select[@name="view"]//option[contains(string(.), "Transaction Period Ending") or position()>1]'
    ],

    downloadErrorNotAvailableForBusinessCredit: [
      '//text()[contains(., "not available for certain Commercial or Business Credit Card Accounts")]',
    ],

    /////////////////////////////////////////////////////////////////////////////
    // global stuff
    /////////////////////////////////////////////////////////////////////////////

    logoutButton: [
      '//a[contains(@href, "GotoLogout")]',   // bank
      '//a[contains(@href, "BacLogoff")]',    // credit
      '//a[contains(@href, "logoutScreen")]', // small business
      '//div[@class="navheader" or @class="masthead"]//a[contains(string(.), "Sign Off")]', // nw

      // 2011 redesign
      '//a[contains(@href, "target=signOff")]',
      '//div[contains(@class, "header")]//a[contains(string(.), "Sign Off")]',
    ],

    errorWrongOnlineId: [
      '//*[contains(string(.), "Enter another Online ID") and contains(@class, "error")]'
    ],

    errorWrongSecurityAnswer: [
      '//*[contains(string(.), "You have entered an answer that is not recognized")]'
    ],

    errorWrongPasscode: [
      '//*[contains(string(.), "Passcode you entered does not match our records")]',
      '//*[contains(string(.), "did not recognize the Online Passcode you entered")]'
    ],

    errorOfSomeKind: [
      '//img[@alt="Error Message"]'
    ],
  }
});
