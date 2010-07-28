wesabe.provide('fi-scripts.us-000238.login', {
  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, "https://www.bankofamerica.com/");
    },

    login: function() {
      job.update('auth.user');
      page.fill(e.login.user.field, answers.userId || answers.username);
      // if we're cookied we won't be asked for state
      page.present(e.login.state.field) && page.fill(e.login.state.field, answers.state);
      page.click(e.login.continueButton);
    },

    chooseState: function() {
      page.fill(e.login.state.field, answers.state);
      page.click(e.stateGoButton);
    },

    splash: function() {
      page.click(e.splashPageClickthru);
    },

    sitekey: function() {
      job.update('auth.pass');
      page.fill(e.sitekey.passcode.field, answers.passcode || answers.password);
      if (page.present(e.sitekeySignInButton)) {
        page.click(e.sitekeySignInButton);
      } else if (page.present(e.login.continueButton)) {
        page.click(e.login.continueButton);
      } else {
        log.error("Cannot find a continue button on the sitekey page!");
      }
    },
  },

  alertReceived: function() {
    if (message.match(/Please re-enter your Online ID/)) {
      job.fail(401, 'auth.user.invalid.blank');
    } else if (message.match(/Please enter the location where your account is held and try again/)) {
      job.fail(401, 'auth.state.invalid.blank');
    }
  },

  dispatch: function() {
    // only dispatch if we're not on the mobile site
    if (page.present(e.mobile.indicator)) return;

    tmp.authenticated = page.visible(e.logoutButton);

    if (!tmp.authenticated) {
      if (page.present(e.errorWrongOnlineId)) {
        job.fail(401, 'auth.user.invalid');
      } else if (page.present(e.errorWrongSecurityAnswer)) {
        job.fail(401, 'auth.security.invalid');
      } else if (page.present(e.errorWrongPasscode)) {
        job.fail(401, 'auth.pass.invalid');
      } else if (page.present(e.login.errors.invalidCreds)) {
        job.fail(401, 'auth.creds.invalid');
      } else if (page.visible(e.security.answers)) {
        action.answerSecurityQuestions();
      } else if (page.present(e.sitekey.safepass.indicator)) {
        log.info("User has SafePass enabled");
        if (page.present(e.sitekey.passcode.field)) {
          log.warn("Cannot bypass SafePass, as it it required for login");
          job.fail(403, 'auth.security.safepass');
        } else {
          log.info("Attempting to bypass SafePass");
          action.mobileMain();
        }
      } else if (page.visible(e.sitekey.passcode.field)) {
        action.sitekey();
      } else if (page.visible(e.login.user.field)) {
        action.login();
      } else if (page.visible(e.login.state.field)) {
        action.chooseState();
      } else if (page.visible(e.splashPageCreateSitekey)) {
        job.fail(403, 'auth.incomplete.sitekey');
      } else if (page.visible(e.splashPageClickthru)) {
        action.splash();
      } else if (page.present(e.splashPageTitle)) {
        wesabe.warn('We seem to be on a splash page, but with no way to get past it. bail!');
        job.fail(403, 'auth.incomplete.splash');
      }
    }
  },

  elements: {
    /////////////////////////////////////////////////////////////////////////////
    // login
    /////////////////////////////////////////////////////////////////////////////

    login: {
      user: {
        field: [
          '//form[@name="frmSignIn"]//input[@name="id"]',
          '//input[@name="id"]',
          '//form[@name="frmSignIn"]//input[@type="text"]',
          '//input[@type="text"]'
        ],
      },

      state: {
        field: [
          '//form[@name="frmSignIn"]//select[@name="state"]',
          '//select[@name="state"]',
          '//form[@name="frmSignIn"]//select',
        ],
      },

      continueButton: [
        '//form[@name="frmSignIn"]//a[contains(@href, "signon")]',
        '//a[contains(@href, "signon")]',
      ],

      errors: {
        invalidCreds: [
          '//text()[contains(., "information you entered does not match our records")]',
        ],
      },
    },

    sitekey: {
      passcode: {
        field: [
          '//form[@name="verifyImageForm"]//input[@name="passcode"]',
          '//input[@name="passcode"]',
          '//form[@name="verifyImageForm"]//input[@type="password"]',
          '//input[@type="password"]',
        ],
      },

      safepass: {
        indicator: [
          '//form[@name="verifyImageForm"]//embed',
          '//text()[contains(., "a new SafePass")]',
        ],
      },
    },

    /////////////////////////////////////////////////////////////////////////////
    // state select form
    /////////////////////////////////////////////////////////////////////////////

    stateGoButton: [
      '//a[contains(@href,"stateSelectForm") and contains(string(.), "Go")]',
      '//a[contains(string(.), "Go")]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // splash page
    /////////////////////////////////////////////////////////////////////////////

    splashPageTitle: [
      '//title[contains(string(.), "Splash Page")]'
    ],

    // this one is for when BofA is just bugging them
    splashPageClickthru: [
      '//a[contains(@href, "Continue") and contains(string(.), "Continue to Online Banking")]',
      '//a[contains(string(.), "Continue to Online Banking")]',
      '//a[contains(@href, "Continue")][not(contains(@href, "Investing"))]',
      '//*[contains(string(.), "Continue to Online Banking") and (name()="A" or name()="INPUT")]',

      '//a[contains(@href, "javascript:showMeLater") and contains(string(.), "Show Me Later")]',
      '//a[contains(string(.), "Show Me Later")]',
      '//a[contains(@href, "javascript:showMeLater")]',
      '//*[contains(string(.), "Show Me Later") and (name()="A" or name()="INPUT")]'
    ],

    // this one is when they actually haven't created a sitekey
    splashPageCreateSitekey: [
      '//a[contains(@href, "TellMeMore") and contains(string(.), "Create your SiteKey Now")]',
      '//a[contains(string(.), "Create your SiteKey Now")]',
      '//a[contains(@href, "TellMeMore")]',
      '//*[contains(string(.), "Create your SiteKey Now") and (name()="A" or name()="INPUT")]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // sitekey challenge question
    /////////////////////////////////////////////////////////////////////////////

    security: {
      questions: [
        '//form[@name="challengeQandAForm"]//*[contains(.//text(), "?") and following::input[@name="sitekeyChallengeAnswer"]]//text()[contains(string(.), "?")]',
        '//form[contains(@action, "challengeQandAMobile")]//text()[contains(., "?") and following-sibling::text()[contains(., "Answer")]]',
      ],

      answers: [
        '//form[@name="challengeQandAForm"]//input[@name="sitekeyChallengeAnswer"]',
        '//input[@name="sitekeyChallengeAnswer"]',
      ],

      setCookieCheckbox: [
        '//form[@name="challengeQandAForm"]//input[@type="radio" and @name="sitekeyDeviceBind" and @value="true"]',
        '//input[@type="radio" and @name="sitekeyDeviceBind" and @value="true"]',
        '//form[@name="challengeQandAForm"]//input[@type="radio" and @value="true"]',
      ],

      continueButton: [
        '//form[@name="challengeQandAForm"]//a[@id="sitekey_confirm" and contains(@href, "challengeQandAForm_0_submit")]',
        '//form[@name="challengeQandAForm"]//a[contains(@href, "challengeQandAForm_0_submit")]',
        '//form[@name="challengeQandAForm"]//a[@id="sitekey_confirm"]',
        '//a[@id="sitekey_confirm"]',
        '//form[contains(@action, "challengeQandAMobile")]//input[@type="submit" or @type="image"]',
      ],
    },

    /////////////////////////////////////////////////////////////////////////////
    // sitekey
    /////////////////////////////////////////////////////////////////////////////

    sitekeySignInButton: [
      '//form[@name="verifyImageForm"]//a[@id="signon" and contains(@href, "verifyImageForm_0_submit")]',
      '//form[@name="verifyImageForm"]//a[contains(@href, "verifyImageForm_0_submit")]',
      '//form[@name="verifyImageForm"]//a[@id="signon"]',
      '//a[@id="signon"]'
    ],
  },
});
