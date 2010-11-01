wesabe.download.Player.register({
  fid: 'us-002337',
  org: 'EverBank',

  dispatchFrames: false,
  afterDownload: 'logout',

  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, "https://cibng.ibanking-services.com/cib/CEBMainServlet/Signon?BRCHID=220&FIFID=063092110&FIORG=220");
    },

    userId: function() {
      job.update('auth.user');
      page.fill(e.login.user.field, answers.userId || answers.username);
      page.click(e.continueButton);
    },

    password: function() {
      job.update('auth.pass');
      page.fill(e.login.pass.field, answers.password);
      page.click(e.login.pass.submit);
    },

    goToDownloadPage: function() {
      job.update('account.download');
      wesabe.dom.browser.go(browser, '/cib/CEBMainServlet/DownloadTxns');
    },

    download: function() {
      page.fill(e.downloadAccountSelect, 'All accounts');
      page.click(e.downloadSelectedFormatOFX);
      page.click(e.continueButton);
    },

    logout: function() {
      job.succeed();
      page.click(e.signoffLink);
    }
  },

  dispatch: function() {
    tmp.authenticated = page.visible(e.signoffLink);
    wesabe.debug('authenticated=', tmp.authenticated);

    if (!tmp.authenticated) {
      if (page.present(e.onlineBankingUnavailable)) {
        job.fail(503, 'fi.unavailable');
      } else if (page.present(e.errorInvalidUserId)) {
        job.fail(401, 'auth.user.invalid');
      } else if (page.present(e.errorInvalidSecurityAnswer)) {
        job.fail(401, 'auth.security.invalid');
      } else if (page.present(e.errorInvalidPassword)) {
        job.fail(401, 'auth.pass.invalid');
      } else if (page.present(e.login.pass.expired)) {
        job.fail(403, 'auth.pass.expired');
      } else if (page.visible(e.login.user.field)) {
        action.userId();
      } else if (page.visible(e.security.answers)) {
        action.answerSecurityQuestions();
      } else if (page.visible(e.login.pass.field)) {
        action.password();
      }
    } else {
      if (page.visible(e.downloadAccountSelect)) {
        action.download();
      } else {
        action.goToDownloadPage();
      }
    }
  },

  elements: {
    /////////////////////////////////////////////////////////////////////////////
    // user challenge
    //
    //   EverBank's security questions are annoying in that they don't have
    //   unique names associated with them (like userChallengeQuestion1), so
    //   we have to read the actual text of the question and then find the
    //   associated text box, filling in the answer.
    //
    /////////////////////////////////////////////////////////////////////////////

    security: {
      questions: [
        '//form[@name="login"]//text()[contains(.,"?") and following::input[contains(@name,"userChallengeAnswer")]]',
        '//text()[contains(.,"?") and following::input[contains(@name,"userChallengeAnswer")]]',
      ],

      answers: [
        '//form[@name="login"]//input[contains(@name,"userChallengeAnswer")]',
        '//input[contains(@name,"userChallengeAnswer")]',
      ],

      setCookieCheckbox: [
        '//form[@name="login"]//input[@name="registerDevice"]',
        '//input[@name="registerDevice"]',
        '//input[@type="checkbox"]'
      ],

      continueButton: [
        '//form[@name="login"]//input[@name="__eventContinue__"]',
        '//input[@name="__eventContinue__"]',
        '//form[@name="login"]//input[@type="submit"]',
        '//input[@type="submit"]',
      ],
    },

    login: {
      user: {
        field: [
          '//form[@name="login"]//input[@name="userid"]',
          '//input[@name="userid"]',
          '//form[@name="login"]//input[@type="text"]',
          '//input[@type="text"]',
        ],
      },

      pass: {
        field: [
          '//form[@name="login"]//input[@name="password"]',
          '//input[@name="password"]',
          '//form[@name="login"]//input[@type="password"]',
          '//input[@type="password"]',
        ],

        submit: [
          '//form[@name="login"]//input[@name="__eventSubmit__"]',
          '//input[@name="__eventSubmit__"]',
          '//input[@value="Sign on"]',
          '//form[@name="login"]//input[@type="submit"]',
          '//input[@type="submit"]',
        ],

        expired: [
          '//text()[contains(., "Your current password has expired")]',
        ],
      },
    },

    /////////////////////////////////////////////////////////////////////////////
    // download transactions
    /////////////////////////////////////////////////////////////////////////////

    downloadAccountSelect: [
      '//form[@name="txnDownload"]//select[@name="bankacctfrom"]',
      '//select[@name="bankacctfrom"]',
      '//form[@name="txnDownload"]//select',
      '//select'
    ],

    downloadSelectedFormatOFX: [
      '//form[@name="txnDownload"]//input[@type="radio" and @name="selectedFormat" and @value="Money"]',
      '//input[@type="radio" and @name="selectedFormat" and @value="Money"]',
      '//input[@type="radio" and @value="Money"]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // global stuff
    /////////////////////////////////////////////////////////////////////////////

    continueButton: [
      '//form[@name="login"]//input[@name="__eventContinue__"]',
      '//input[@name="__eventContinue__"]',
      '//form[@name="login"]//input[@type="submit"]',
      '//input[@type="submit"]'
    ],

    loginError: [
      '//text()[contains(.,"Sign-on unsuccessful")]',
      '//*[contains(@class,"errorTextTop")]'
    ],

    errorInvalidUserId: [
      '//text()[contains(.,"Your user ID is invalid")]'
    ],

    errorInvalidSecurityAnswer: [
      '//*[contains(string(.), "One or more of your answers are invalid")]'
    ],

    errorInvalidPassword: [
      '//*[contains(string(.), "Your password is invalid")]'
    ],

    signoffLink: [
      '//a[contains(@href, "Logout")]',
      '//a[contains(@href, "logout")]',
      '//a[contains(., "Sign Off")]',
      '//a[contains(., "Log Out")]'
    ],

    onlineBankingUnavailable: [
      '//text()[contains(., "Online Banking service is temporarily unavailable")]',
    ],
  }
});
