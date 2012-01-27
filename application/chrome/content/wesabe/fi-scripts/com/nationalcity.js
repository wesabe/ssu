wesabe.download.Player.register({
  fid: 'com.nationalcity',
  org: 'National City - Online Banking',

  dispatchFrames: false,
  afterDownload: 'nextAccount',

  actions: {
    main: function() {
      browser.go("https://signonolb.nationalcity.com/olb/olblogin.jsp");
    },

    username: function() {
      job.update('auth.user');
      page.fill(e.loginId, answers.username);
      page.click(e.loginButton);
    },

    password: function() {
      job.update('auth.pass');
      page.fill(e.loginPassword, answers.password);
      page.submit(e.loginPassword);
    },

    goDownloadPage: function() {
      page.click(e.landingExportAccountActivityLink);
    },

    collectAccounts: function() {
      var list = page.findStrict(e.downloadAccountList);

      tmp.accounts = page.select(e.downloadAccountListItem, list).map(function(el) {
        return {name: el.innerHTML, value: el.value}
      });
      wesabe.info('accounts=', tmp.accounts);
    },

    selectAccount: function() {
      page.fill(e.downloadAccountList, tmp.account.value);
      page.click(e.downloadNextButton);
    },

    download: function() {
      job.update('account.download');
      page.check(e.downloadFormatMoney);
      page.click(e.downloadExportButton);
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
      if (page.present(e.errorWrongUsernameOrPassword)) {
        job.fail(401, 'auth.creds.invalid');
      } else if (page.visible(e.loginPassword)) {
        action.password();
      } else if (page.visible(e.loginId)) {
        action.username();
      }
    } else {
      if (page.visible(e.downloadAccountList)) {
        if (!tmp.accounts)
          action.collectAccounts();

        if (tmp.accounts.length) {
          tmp.account = tmp.accounts.shift();
          action.selectAccount();
        } else {
          action.logout();
        }
      } else if (tmp.account && page.visible(e.downloadExportButton)) {
        action.download();
      } else {
        action.goDownloadPage();
      }

    }
  },

  elements: {
    /////////////////////////////////////////////////////////////////////////////
    // login page
    /////////////////////////////////////////////////////////////////////////////

    loginId: [
      '//form[@name="signon"]//input[@name="USERNAME"]',
      '//input[@name="USERNAME"]',
      '//form[@name="signon"]//input[@type="text"]',
      '//input[@type="text"]'
    ],

    loginPassword: [
      '//form[@name="loginForm"]//input[@name="Bharosa_Password_PadDataField"]',
      '//input[@name="Bharosa_Password_PadDataField"]',
      '//form[@name="loginForm"]//input[@type="password"]',
      '//input[@type="password"]'
    ],

    loginButton: [
      '//form[@name="signon"]//input[@name="Login" and (@type="submit" or @type="image")]',
      '//input[@name="Login" and (@type="submit" or @type="image")]',
      '//form[@name="signon"]//input[@type="submit" or @type="image"]',
      '//input[@type="submit" or @type="image"]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // landing page
    /////////////////////////////////////////////////////////////////////////////

    landingExportAccountActivityLink: [
      '//a[@href="AccountListExportHistory.aspx"]',
      '//a[contains(string(.), "Export Account Activity")]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // download page
    /////////////////////////////////////////////////////////////////////////////

    downloadAccountList: [
      '//form[@name="aspnetForm"]//select[contains(@name, "AcctListDropDown")]',
      '//select[contains(@name, "AcctListDropDown")]',
      '//form[@name="aspnetForm"]//select',
      '//select',
    ],

    downloadAccountListItem: [
      './/option'
    ],

    downloadNextButton: [
      '//form[@name="aspnetForm"]//input[contains(@name, "btExport") and (@type="submit" or @type="image")]',
      '//input[contains(@name, "btExport") and (@type="submit" or @type="image")]',
      '//form[@name="aspnetForm"]//input[@type="submit" or @type="image"]',
      '//input[has-class("defaultButton") and (@type="submit" or @type="image")]'
    ],

    ///////////////////////////////////////////////////////////////////////////
    // confirm download page
    ///////////////////////////////////////////////////////////////////////////

    downloadFormatMoney: [
      '//input[@type="radio" and @value="radMoney"]',
    ],

    downloadExportButton: [
      '//form[@name="aspnetForm"]//input[has-class("defaultButton") and (@type="submit" or @type="image")]',
      '//input[has-class("defaultButton") and (@type="submit" or @type="image")]',
      '//form[@name="aspnetForm"]//input[@type="submit" or @type="image"]',
      '//input[@type="submit" or @type="image"]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // global stuff
    /////////////////////////////////////////////////////////////////////////////

    logoutButton: [
      '//a[contains(@href, "LogOut.aspx")]',
      '//a[contains(string(.), "Log Off")]',
      '//a[contains(string(.), "Log Out")]',
      '//a[contains(string(.), "Logoff")]',
      '//a[contains(string(.), "Logout")]',
    ],

    errorWrongUsernameOrPassword: [
      '//*[contains(string(.), "Log-in ID and / or Password that you have entered is invalid")]'
    ]
  }
});
