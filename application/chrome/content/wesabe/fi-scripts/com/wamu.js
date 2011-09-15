wesabe.download.Player.register({
  fid: 'com.wamu',
  org: 'Washington Mutual',

  dispatchFrames: false,
  afterDownload: 'nextAccount',

  dispatch: function() {
    tmp.authenticated = page.visible(e.logoutButton);
    wesabe.debug('authenticated=', tmp.authenticated);

    if (page.present(e.security.page.indicator)) {
      return action.answerSecurityQuestions();
    }

    if (!tmp.authenticated) {
      if (page.present(e.errorWrongUsernameOrPassword)) {
        return job.fail(401, 'auth.creds.invalid');
      } else if (page.visible(e.loginPassword)) {
        return action.login();
      }
    } else {
      if (page.present(e.confirmDownloadError)) {
        wesabe.warn('Skipping account ', tmp.account, ' because: ', page.select(e.confirmDownloadErrorReason));
        delete tmp.account;
      }

      if (page.present(e.downloadInvalidDateFormat)) {
        wesabe.warn('Skipping account ', tmp.account, ' because: ', page.select(e.downloadInvalidDateFormatReason));
        delete tmp.account;
      }

      if (page.visible(e.downloadFormat)) {
        // collect the account elements if we don't already have them
        if (!tmp.accounts) {
          action.collectAccounts();
        }

        if (tmp.accounts.length) {
          tmp.account = tmp.accounts.shift();
          return action.download();
        } else {
          return action.logout();
        }
      } else if (tmp.account && page.visible(e.confirmDownloadForm)) {
        return action.confirmDownload();
      } else {
        return action.goDownloadPage();
      }
    }

    if (page.visible(e.offers.decline.link)) {
      // don't actually click "No, thanks", just click the
      // Your Accounts link to bypass the whole screen
      page.click(e.offers.bypass.link);
    }
  },

  actions: {
    main: function() {
      browser.go("https://online.wamu.com/IdentityManagement/Logon.aspx");
    },

    login: function() {
      job.update('auth.creds');
      // if we're cookied, we won't be asked for username
      page.present(e.loginUserId) && page.fill(e.loginUserId, answers.userId || answers.username);
      page.fill(e.loginPassword, answers.password);
      page.click(e.loginButton);
    },

    goDownloadPage: function() {
      browser.go('/Servicing/Servicing.aspx?targetPage=TransactionDownload');
    },

    collectAccounts: function() {
      tmp.accounts = page.select(e.downloadAccountCheckbox).map(function(el) {
        var account = { value: el.name };
        try { account.name = page.find(bind(e.downloadAccountLabel, { id: el.id })).innerHTML }
        catch (e) { /* oh well, no name */ }
        return account;
      });
      wesabe.info('accounts=', tmp.accounts);
    },

    download: function() {
      job.update('account.download');

      // uncheck any that might already be checked
      page.select(e.downloadAccountCheckbox).forEach(function(account) {
        page.uncheck(account);
      });

      // select this account
      page.check(bind(e.downloadSpecificAccountCheckbox, {name: tmp.account.value}));

      // fill in the dates
      action.fillDateRange();

      // choose OFX format
      page.fill(e.downloadFormat, e.downloadFormatOFX);
      page.click(e.downloadButton);
    },

    confirmDownload: function() {
      page.click(e.confirmDownloadButton);
    },

    logout: function() {
      job.succeed();
      page.click(e.logoutButton);
    }
  },

  elements: {
    /////////////////////////////////////////////////////////////////////////////
    // login page
    /////////////////////////////////////////////////////////////////////////////

    loginUserId: [
      '//form[@name="frmLogin"]//input[@name="txtUserID"]',
      '//input[@name="txtUserID"]',
      '//form[@name="frmLogin"]//input[@type="text"]',
      '//input[@type="text"]'
    ],

    loginPassword: [
      '//form[@name="frmLogin"]//input[@name="password"]',
      '//input[@name="password"]',
      '//form[@name="frmLogin"]//input[@type="password"]',
      '//input[@type="password"]'
    ],

    loginButton: [
      '//form[@name="frmLogin"]//input[@id="LoginButton" and (@type="submit" or @type="image")]',
      '//input[@id="LoginButton" and (@type="submit" or @type="image")]',
      '//form[@name="frmLogin"]//input[@type="submit" or @type="image"]',
      '//input[@type="submit" or @type="image"]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // splash pages
    /////////////////////////////////////////////////////////////////////////////

    offers: {
      decline: {
        link: [
          '//a[contains(string(.), "No thanks, not right now")]',
        ],
      },

      bypass: {
        link: [
          '//a[contains(string(.), "Your Accounts")]',
        ],
      },
    },

    security: {
      page: {
        indicator: [
          '//title[contains(string(.), "WaMu | Security")]',
          '//text()[contains(., "Please answer the following security questions")]',
        ],
      },

      questions: [
        '//form[@name="challenge"]//label[contains(@id, "Question")]//text()',
      ],

      answers: [
        '//form[@name="challenge"]//input[contains(@id, "Answer")]',
      ],

      continueButton: [
        '//form[@name="challenge"]//input[@type="submit" or @type="image"][@value="SUBMIT"]',
        '//form[@name="challenge"]//input[@type="submit" or @type="image"]',
      ],
    },

    /////////////////////////////////////////////////////////////////////////////
    // download page
    /////////////////////////////////////////////////////////////////////////////

    downloadAccountCheckbox: [
      '//input[@type="checkbox" and contains(@name, "accountSelection")]',
      '//input[@type="checkbox"]'
    ],

    downloadAccountLabel: [
      '//label[@for=":id"]'
    ],

    downloadSpecificAccountCheckbox: [
      '//input[@type="checkbox" and @name=":name"]'
    ],

    downloadFormat: [
      '//select[contains(@name, "softwareFormat")]'
    ],

    downloadFormatOFX: [
      './/option[@value="OFX"]'
    ],

    downloadButton: [
      '//input[contains(@name, "btnNextButton") and (@type="submit" or @type="image")]'
    ],

    download: {
      date: {
        from: [
          '//input[contains(@name, "txtFromDate")]',
        ],

        to: [
          '//input[contains(@name, "txtToDate")]',
        ],
      },
    },

    downloadInvalidDateFormat: [
      '//div[@class="error" and contains(string(.), "enter a valid date")]'
    ],

    downloadInvalidDateFormatReason: [
      '//div[@class="error"]//*[@class="validation"]//text()'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // confirm download page
    /////////////////////////////////////////////////////////////////////////////

    confirmDownloadForm: [
      '//form[contains(@action, "TransactionDownloadVerify")]'
    ],

    confirmDownloadButton: [
      '//input[contains(@name, "btnDownload") and (@type="submit" or @type="image")]',
      '//input[@type="submit" or @type="image"]'
    ],

    confirmDownloadError: [
      '//h1[contains(string(.), "Transaction Download Error")]'
    ],

    confirmDownloadErrorReason: [
      '//div[@id="PageFormBox"]//table[@class="datagrid"]//tr//td[position()=3]/text()'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // global stuff
    /////////////////////////////////////////////////////////////////////////////

    logoutButton: [
      '//a[contains(@href, "Logout.ashx") or contains(string(.), "Log out")]',
      '//a[contains(string(.), "Log out")]'
    ],

    errorWrongUsernameOrPassword: [
      '//*[contains(string(.), "We\'re sorry, your entry is not valid")]'
    ]
  }
});
