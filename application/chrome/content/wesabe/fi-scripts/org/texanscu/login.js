wesabe.provide("fi-scripts.org.texanscu.login", {
  dispatch: function() {
    // only dispatch when not logged in
    if (page.present(e.logoff.link)) return;

    if (page.present(e.login.error.creds)) {
      job.fail(401, 'auth.creds');
    } else if (page.present(e.login.error.unknown)) {
      job.fail(401, 'auth.unknown');
    } else if (page.present(e.login.indicator)) {
      action.login();
    }
  },

  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, "https://online.texanscu.org/Texans/Login.aspx");
    },

    login: function() {
      job.update('auth.creds');

      page.fill(e.login.user.field, answers.username);
      page.fill(e.login.pass.field, answers.password);
      page.fill(e.login.dest.field, e.login.dest.accountsSummary);
      page.click(e.login.continueButton);
    },

    logoff: function() {
      page.click(e.logoff.link);
      job.succeed();
    },
  },

  elements: {
    login: {
      indicator: [
        '//h1[contains(string(.), "Login")]',
      ],

      user: {
        field: [
          '//input[@name="ctlSignon:txtUserID"][@type="text"]',
          '//form[@action="Login.aspx"]//input[@type="text"]',
        ],
      },

      pass: {
        field: [
          '//input[@name="ctlSignon:txtPassword"][@type="password"]',
          '//form[@action="Login.aspx"]//input[@type="password"]',
        ],
      },

      dest: {
        field: [
          '//select[@name="ctlSignon:ddlSignonDestination"]',
          '//form[@action="Login.aspx"]//select',
        ],

        accountsSummary: [
          './/option[@value="Accounts.Summary"]',
          './/option[contains(string(.), "Accounts Summary")]',
        ],
      },

      error: {
        creds: [
          '//text()[contains(., "Invalid User ID or Password")]',
        ],

        unknown: [
          '//*[@id="SERVERSIDEERROR"]',
        ],
      },

      continueButton: [
        '//input[@name="ctlSignon:btnLogin"]',
        '//form[@action="Login.aspx"]//input[@type="button" or @type="submit" or @type="image"][@value="Login"]',
      ],
    },

    logoff: {
      link: [
        '//a[contains(@href, "Logout.aspx")]',
        '//a[contains(string(.), "Logout")]',
        '//a[contains(@id, "LNKLOGOUT")]',
      ],
    },
  },
});
