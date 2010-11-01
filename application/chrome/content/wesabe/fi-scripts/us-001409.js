wesabe.download.Player.register({
  fid: 'us-001409',
  org: 'CapitalOne Credit Cards',

  userAgent: 'firefox',
  afterDownload: 'nextAccount',

  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, "https://servicing.capitalone.com/c1/login.aspx");
    },

    login: function() {
      job.update('auth.creds');
      page.fill(e.loginUserId, answers.username);
      page.fill(e.loginPassword, answers.password);
      page.click(e.loginButton);
    },

    goDownloadPage: function() {
      job.update('account.download');
      page.click(e.downloadPageLink);
    },

    collectAccounts: function() {
      tmp.accounts = page.select(e.downloadAccountList).map(function(el){ return el.value });
      wesabe.info('accounts=', tmp.accounts);
    },

    chooseOrDownload: function() {
      var account = page.find(e.downloadAccountList).value;
      if (wesabe.untaint(account) == wesabe.untaint(tmp.account)) {
        action.fillDateRange();
        page.click(e.downloadFormatOFX);
        page.click(e.downloadButton);
      } else {
        // causes a page reload
        page.fill(e.downloadAccountList, tmp.account);
      }
    },

    logout: function() {
      job.succeed();
      page.click(e.logoutButton);
    }
  },

  dispatch: function() {
    // TODO: handle invalid security question answers
    if (page.present(e.security.questions)) {
      action.answerSecurityQuestions();
      return;
    }

    tmp.authenticated = page.visible(e.logoutButton);
    wesabe.debug('authenticated=', tmp.authenticated);

    if (!tmp.authenticated) {
      if (page.present(e.errorWrongUsernameOrPassword)) {
        job.fail(401, 'auth.creds.invalid');
      } else if (page.visible(e.loginPassword)) {
        action.login();
      }
    } else {
      if (!tmp.accounts) {
        if (page.visible(e.downloadAccountList)) {
          action.collectAccounts();
        } else {
          action.goDownloadPage();
          return;
        }
      }

      if (!tmp.account) {
        if (tmp.accounts.length) {
          tmp.account = tmp.accounts.shift();
        } else {
          action.logout();
          return;
        }
      }

      action.chooseOrDownload();
    }
  },

  elements: {
    /////////////////////////////////////////////////////////////////////////////
    // login page
    /////////////////////////////////////////////////////////////////////////////

    loginUserId: [
      '//form[@name="login"]//input[@name="user"]',
      '//input[@name="user"]',
      '//form[@name="login"]//input[@type="text"]',
      '//input[@type="text"]'
    ],

    loginPassword: [
      '//form[@name="login"]//input[@name="password"]',
      '//input[@name="password"]',
      '//form[@name="login"]//input[@type="password"]',
      '//input[@type="password"]'
    ],

    loginButton: [
      '//form[@name="login"]//input[@id="cofisso_btn_login" and (@type="submit" or @type="image")]',
      '//input[@id="cofisso_btn_login" and (@type="submit" or @type="image")]',
      '//form[@name="login"]//input[@type="submit" or @type="image"]',
      '//input[@type="submit" or @type="image"]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // security question page
    /////////////////////////////////////////////////////////////////////////////

    security: {
      questions: [
        '//span[@id="lblChallengeQuestion"]//text()',
      ],

      answers: [
        '//input[@name="txtAnswer"]',
      ],

      continueButton: [
        '//input[@name="btnSubmitAnswers"]',
      ],
    },

    /////////////////////////////////////////////////////////////////////////////
    // download page
    /////////////////////////////////////////////////////////////////////////////

    downloadPageLink: [
      '//a[contains(@href, "Download.aspx") and contains(string(.), "Downloads")]',
      '//a[contains(string(.), "Downloads")]'
    ],

    downloadAccountList: [
      '//select[@name="cboAccountTypeList"]'
    ],

    download: {
      date: {
        from: [
          '//*[@id="txtFromDate"]//input[@type="text"]',
          '//input[@name="txtFromDate:textBox"]'
        ],

        to: [
          '//*[@id="txtToDate"]//input[@type="text"]',
          '//input[@name="txtToDate:textBox"]'
        ],
      },
    },

    downloadFormatOFX: [
      '//input[@type="radio"][@value="OFX"]'
    ],

    downloadButton: [
      '//input[contains(@name, "btnDownload") and (@type="submit" or @type="image")]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // global stuff
    /////////////////////////////////////////////////////////////////////////////

    logoutButton: [
      '//a[contains(@href, "Logout.aspx") or @id="LNKLOGOUT"]'
    ],

    errorWrongUsernameOrPassword: [
      '//*[contains(string(.), "This information doesn\'t match what we have on file")]'
    ]
  }
});
