wesabe.download.Player.register({
  fid: 'us-001758',
  org: 'Wachovia',

  afterDownload: 'logout',

  dispatch: function() {
    tmp.authenticated = page.visible(e.logoutButton);
    wesabe.debug('authenticated=', tmp.authenticated);

    if (page.present(e.errors.onlineServiceError)) {
      job.fail(503, 'fi.unavailable');
    } else if (page.present(e.errors.accountAccessUnavailable)) {
      job.fail(503, 'fi.unavailable');
    }

    if (!tmp.authenticated) {
      if (page.present(e.login.errors.invalid)) {
        job.fail(401, 'auth.creds.invalid');
      } else if (page.present(e.login.username.errors.length)) {
        job.fail(401, 'auth.user.invalid.length');
      } else if (page.present(e.login.username.errors.format)) {
        job.fail(401, 'auth.user.invalid.format');
      } else if (page.visible(e.login.username.field)) {
        action.login();
      } else if (page.visible(e.remindMeLaterButton)) {
        action.clickPastOffer();
      } else if (page.present(e.wachoviaToWellsFargoTransition.indicator)) {
        action.clickPastWellsFargoWelcome();
      }
    } else {
      if (page.visible(e.downloadMoneyFormat)) {
        action.download();
      } else if (page.present(e.page.unavailable.indicator)) {
        job.fail(400, 'account.download.unavailable');
      } else {
        action.goDownloadPage();
      }
    }
  },

  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, "https://onlineservices.wachovia.com/auth/AuthService");
    },

    login: function() {
      job.update('auth.creds');

      // strip out whitespace from the username in case users enters some
      var username = (answers.userId || answers.username).replace(/\s/g, '');

      page.fill(e.login.username.field, username);
      page.fill(e.login.password.field, answers.password);
      page.fill(e.loginDestination, e.loginDestinationBanking);
      page.click(e.loginButton);
    },

    clickPastOffer: function() {
      page.click(e.remindMeLaterButton);
    },

    clickPastWellsFargoWelcome: function() {
      page.click(e.wachoviaToWellsFargoTransition.continueButton);
    },

    goDownloadPage: function() {
      job.update('account.download');
      if (page.visible(e.accountDownloadLink)) {
        page.click(e.accountDownloadLink);
      } else {
        wesabe.warn("the download link isn't here, maybe just try going to the url?");
        wesabe.dom.browser.go(browser, 'AccountDownload.aspx');
      }
    },

    download: function() {
      page.fill(e.downloadMoneyFormat, e.downloadMoneyFormat2008);
      page.click(e.downloadMoneyButton);
    },

    logout: function() {
      job.succeed();
      page.click(e.logoutButton);
    }
  },

  elements: {
    login: {
      username: {
        field: [
          '//form[@name="uidAuthForm"]//input[@name="userid"]',
          '//input[@name="userid"]',
          '//form[@name="uidAuthForm"]//input[@type="text"]',
          '//input[@type="text"]',
        ],

        errors: {
          length: [
            '//text()[contains(., "User ID must be 7-20 characters")]',
            '//*[contains(string(.), "Error Code") and following-sibling::*[contains(string(.), "ASV-226")]]',
          ],

          format: [
            '//text()[contains(., "User ID contains invalid character")]',
            '//*[contains(string(.), "Error Code") and following-sibling::*[contains(string(.), "ASV-227")]]',
          ],
        },
      },

      password: {
        field: [
          '//form[@name="uidAuthForm"]//input[@name="password"]',
          '//input[@name="password"]',
          '//form[@name="uidAuthForm"]//input[@type="password"]',
          '//input[@type="password"]'
        ],
      },

      errors: {
        invalid: [
          '//*[contains(string(.), "entered an invalid User ID and/or Password")]',
          '//*[contains(string(.), "ASV-201")]'
        ],
      },
    },

    errors: {
      onlineServiceError: [
        '//title[contains(string(.), "Online Services Error")]',
      ],

      accountAccessUnavailable: [
        '//text()[contains(., "We are unable to access your account information at this time")]',
        '//text()[contains(., "NRL001")]',
      ],
    },

    page: {
      unavailable: {
        indicator: '//text()[contains(., "error code 170-120")]',
      },
    },

    loginDestination: [
      '//form[@name="uidAuthForm"]//select[@name="systemtarget"]',
      '//select[@name="systemtarget"]',
      '//form[@name="uidAuthForm"]//select'
    ],

    loginDestinationBanking: [
      './/option[@value="gotoBanking"]'
    ],

    loginButton: [
      '//form[@name="uidAuthForm"]//input[@name="submitButton" and (@type="submit" or @type="image")]',
      '//input[@name="submitButton" and (@type="submit" or @type="image")]',
      '//form[@name="uidAuthForm"]//input[@type="submit" or @type="image"]',
      '//input[@type="submit" or @type="image"]'
    ],

    // Wachovia -> Wells Fargo transition (maybe?)
    wachoviaToWellsFargoTransition: {
      indicator: [
        '//title[contains(., "Welcome, Wachovia customers")]',
      ],

      continueButton: [
        '//div[@class="continuebutton"]//*[contains(@onclick, "continue")]',
        '//*[contains(@onclick, "continue")][.//img[contains(@src, "continue")]]',
      ],
    },

    /////////////////////////////////////////////////////////////////////////////
    // accounts page
    /////////////////////////////////////////////////////////////////////////////

    accountDownloadLink: [
      '//a[contains(@href, "AccountDownload")]',
      '//a[contains(string(.), "Account Download")]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // download page
    /////////////////////////////////////////////////////////////////////////////

    downloadMoneyFormat: [
      '//form[@name="frmSawgrass"]//select[@name="ddlMSMoney"]',
      '//select[@name="ddlMSMoney"]',
      '//form[@name="frmSawgrass"]//select[position()=3]',
      '//select[position()=3]'
    ],

    downloadMoneyFormat2008: [
      './/option[@value="Money 1700"]',
      './/option[contains(string(.), "2008")]',
      './/option[position()=2]'
    ],

    downloadMoneyButton: [
      '//form[@name="frmSawgrass"]//input[@name="imgMSMoney" and (@type="submit" or @type="image")]',
      '//input[@name="imgMSMoney" and (@type="submit" or @type="image")]',
      '//input[@value="Download" and position()=3 and (@type="submit" or @type="image")]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // global stuff
    /////////////////////////////////////////////////////////////////////////////

    remindMeLaterButton: [
      '//a[contains(@onclick, "showMeLaterClicked")]',
      '//a[img/@alt="Remind Me Later"]'
    ],

    logoutButton: [
      '//div[@id="logout"]//a[@href="LogOff.aspx" or @title="Log out"]',
      '//a[@href="LogOff.aspx" or @title="Log out"]',
      '//a[contains(string(.), "Log out")]'
    ],
  }
});
