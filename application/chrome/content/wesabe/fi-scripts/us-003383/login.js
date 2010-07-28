wesabe.provide('fi-scripts.us-003383.login', {
  dispatch: function() {
    tmp.authenticated = page.present(e.logout.link);

    if (!tmp.authenticated) {
      if (page.present(e.login.error.general)) {
        job.fail(401, 'auth.creds.invalid');
      } else if (page.present(e.login.error.blank)) {
        job.fail(401, 'auth.creds.invalid.blank');
      } else if (page.present(e.login.user.field)) {
        action.login();
      }
    }
  },

  alertReceived: function() {
    if (message.match(/Please fill in both the "User ID" and "Password" fields/)) {
      job.fail(401, 'auth.creds.invalid.blank');
    }
  },

  actions: {
    login: function() {
      job.update('auth.creds');
      page.fill(e.login.user.field, answers.username);
      page.fill(e.login.pass.field, answers.password);
      page.click(e.login.continueButton);
    },

    logout: function() {
      job.succeed();
      page.click(e.logout.link);
    },
  },

  elements: {
    login: {
      user: {
        field: [
          // home page
          '//form[@name="ssoform"]//input[@name="Userid"][@type="text"]',
          '//input[@name="Userid"][@type="text"]',
          '//form[@name="ssoform"]//input[@type="text"]',
          // login page
          '//form[@name="frmLogin"]//input[@name="UserID"][@type="text"]',
          '//input[@name="UserID"][@type="text"]',
          '//form[@name="frmLogin"]//input[@type="text"]',
        ],
      },

      pass: {
        field: [
          // home page
          '//form[@name="ssoform"]//input[@name="Pword"][@type="password"]',
          '//input[@name="Pword"][@type="password"]',
          '//form[@name="ssoform"]//input[@type="password"]',
          // login page
          '//form[@name="frmLogin"]//input[@name="Password"][@type="password"]',
          '//input[@name="Password"][@type="password"]',
          '//form[@name="frmLogin"]//input[@type="password"]',
        ],
      },

      error: {
        general: [
          '//text()[contains(., "User ID or Password is incorrect")]',
        ],

        blank: [
          '//text()[contains(., "You\'ve left a field blank")]',
        ],
      },

      continueButton: [
        // home page
        '//form[@name="ssoform"]//*[contains(@onclick, "validate")]',
        '//form[@name="ssoform"]//*[@name="btn"][@onclick]',
        // login page
        '//a[@onclick][.//img[contains(@onclick, "frmLogon")]]',
        '//form[@name="frmLogin"]//a[contains(@onclick, "logon")]',
      ],
    },

    logout: {
      link: [
        '//a[contains(@href, "Logoff")]',
        '//a[contains(@href, "Logout")]',
        '//a[contains(string(.), "Log Off")]',
        '//a[contains(string(.), "Log Out")]',
        '//a[contains(string(.), "Logout")]',
        '//a[contains(string(.), "Logoff")]',
      ],
    },
  },
});
