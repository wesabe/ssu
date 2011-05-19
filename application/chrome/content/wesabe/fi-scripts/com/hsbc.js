wesabe.download.Player.register({
  fid: 'com.hsbc',
  org: 'HSBC (US)',

  dispatchFrames: false,
  afterDownload: 'nextAccount',

  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, "https://www.us.hsbc.com/1/2/3/personal/online-services/personal-internet-banking/log-on");
    },

    login: function() {
      job.update('auth.user');
      page.fill(e.loginUserIdField, answers.userId || answers.username);
      page.click(e.loginContinueButton);
    },

    passwordAndSecurityKey: function() {
      job.update('auth.pass');
      page.fill(e.passwordPasswordField, answers.password);
      // click on each letter in turn on the virtual keyboard
      for (var i = 0; i < answers.securityKey.length; i++) {
        try {
          page.click(wesabe.xpath.bind(e.passwordSecurityKey, {n: answers.securityKey[i].toUpperCase()}));
        } catch (e) {
          log.warn("Skipping character in security key because: ", e);
        }
      }
      page.click(e.passwordContinueButton);
    },

    goDownloadPage: function() {
      job.update('account.download');
      page.click(e.accountsDownloadLink);
    },

    beginDownloads: function() {
      var select = page.findStrict(e.downloadAccountSelect);
      var options = page.select(e.downloadAccountOption, select);
      tmp.accounts = options.map(function(option){ return option.value });
      log.debug('accounts=', tmp.accounts);
    },

    download: function() {
      page.fill(e.downloadAccountSelect, tmp.account);
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

  dispatch: function() {
    tmp.authenticated = page.visible(e.logoutButton);
    wesabe.debug('authenticated=', tmp.authenticated);

    if (!tmp.authenticated) {
      if (page.visible(e.errorInvalidUsername)) {
        job.fail(401, 'auth.user.invalid');
      } else if (page.visible(e.errorInvalidPasswordOrKey)) {
        job.fail(401, 'auth.creds.invalid');
      } else if (page.visible(e.loginUserIdField)) {
        action.login();
      } else if (page.visible(e.passwordPasswordField)) {
        action.passwordAndSecurityKey();
      } else if (page.present(e.pages.message.indicator)) {
        log.error("WE'RE ON THAT BLASTED MESSAGE PAGE! taking private snapshot");
        page.dumpPrivately();
        job.fail(500, "promo.unknown.hsbc");
      } else {
        log.warn('no markers for non-authenticated pages. where are we?');
      }
    } else {
      if (page.present(e.errorNoEligibleAccountToDownload)) {
        log.warn("No accounts for this user can be downloaded!");
        action.logout();
      } else if (page.visible(e.downloadAccountSelect)) {
        // get the account list
        if (!tmp.accounts) {
          action.beginDownloads();
        }

        if (tmp.accounts.length) {
          tmp.account = tmp.accounts.shift();
          action.download();
        } else {
          action.logout();
        }
      } else if (tmp.account && page.visible(e.confirmDownloadButton)) {
        action.confirmDownload();
      } else if (page.visible(e.accountsDownloadLink)) {
        action.goDownloadPage();
      }
    }
  },

  elements: {
    /////////////////////////////////////////////////////////////////////////////
    // username page
    /////////////////////////////////////////////////////////////////////////////

    loginUserIdField: [
      '//form[@name="ibLogonForm"]//input[@name="userid"]',
      '//input[@name="userid"]',
      '//form[@name="ibLogonForm"]//input[@type="text" or @type="Username"]' // type="Username"? wtf HSBC?
    ],

    loginContinueButton: [
      '//form[@name="ibLogonForm"]//input[(@value="Continue" or @name="submit") and (@type="submit" or @type="image")]',
      '//input[(@value="Continue" or @name="submit") and (@type="submit" or @type="image")]',
      '//input[@type="submit" or @type="image"]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // password page
    /////////////////////////////////////////////////////////////////////////////

    passwordPasswordField: [
      '//form[@name="inputForm"]//input[@name="memorableAnswer" and @type="password"]',
      '//input[@name="memorableAnswer" and @type="password"]',
      '//form[@name="inputForm"]//input[@type="password" and @name!="password"]' // security key is named "password"
    ],

    passwordSecurityKey: [
      '//form[@name="inputForm"]//*[@class="id_key" and string(text())=":n"]',
      '//*[@class="id_key" and string(text())=":n"]',
      '//*[string(text())=":n"]'
    ],

    passwordContinueButton: [
      '//form[@name="inputForm"]//input[(@value="Continue" or @name="submit") and (@type="submit" or @type="image")]',
      '//input[(@value="Continue" or @name="submit") and (@type="submit" or @type="image")]',
      '//input[@type="submit" or @type="image"]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // account list
    /////////////////////////////////////////////////////////////////////////////

    accountsDownloadLink: [
      '//a[contains(string(text()), "Download") and contains(@href, "Download")]',
      '//a[contains(@href, "Download")]',
      '//a[contains(string(text()), "Download")]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // download page
    /////////////////////////////////////////////////////////////////////////////

    downloadAccountSelect: [
      '//form[@name="downloadviewform"]//select[@name="PC_7_1_AEO_account_id"]',
      '//form[@name="downloadviewform"]//select[@id="Account"]',
      '//select[@name="PC_7_1_AEO_account_id"]',
      '//select[@name="Account"]',
      '//form[@name="downloadviewform"]/select'
    ],
    // relative to <select>
    downloadAccountOption: [
      './/option[not(@value="-1") and not(contains(string(text()), "Select an Account"))]'
    ],

    downloadButton: [
      '//form[@name="downloadviewform"]//input[@type="image" and contains(@src, "money")]',
      '//form[@name="downloadviewform"]//input[@type="image" or @type="submit"]',
      '//input[@type="image" and contains(@src, "money")]',
      '//input[@type="image" or @type="submit"]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // download confirmation
    /////////////////////////////////////////////////////////////////////////////

    confirmDownloadButton: [
      '//form[@name="downloadconfirmform"]//input[@type="button" and contains(@name, "Start")]',
      '//form[@name="downloadconfirmform"]//input[contains(@onclick, "startDownload")]',
      '//form[@name="downloadconfirmform"]//input[@value="Submit"]',
      '//input[@type="button" and contains(@name, "Start")]',
      '//input[contains(@onclick, "startDownload")]',
      '//input[@value="Submit"]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // global stuff
    /////////////////////////////////////////////////////////////////////////////

    logoutButton: [
      '//a[contains(@href, "Logoff") and contains(string(text()), "Logoff")]',
      '//a[contains(@href, "Logoff")]',
      '//a[contains(string(text()), "Logoff")]'
    ],

    alert: [
      '//*[@id="alert"]'
    ],

    errorAlert: [
      '//*[@id="alert"]'
    ],

    errorInvalidUsername: [
      '//*[@id="alert" and contains(string(.), "Username")]',
      '//*[contains(string(.), "Your Username has not been recognized")]'
    ],

    errorInvalidPasswordOrKey: [
      '//*[@id="alert" and contains(string(.), "do not match")]',
      '//*[contains(string(.), "details you have entered do not match our records")]'
    ],

    errorNoEligibleAccountToDownload: [
      '//text()[contains(., "No eligible account is available for transaction download")]',
    ],

    pages: {
      message: {
        indicator: '//title[contains(string(.), "HSBC - Message")]',
      },
    },
  },
});

wesabe.util.privacy.registerSanitizer('HSBC Keyboard Key', /\bid\d+_key\b/g);
