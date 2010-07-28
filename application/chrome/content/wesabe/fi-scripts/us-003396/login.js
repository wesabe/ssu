wesabe.provide('fi-scripts.us-003396.login', {
  dispatch: function() {
    tmp.authenticated = page.present(e.logoff.link);

    if (!tmp.authenticated) {
      if (page.present(e.login.error.general)) {
        job.fail(401, 'auth.creds.invalid');
      } else if (page.present(e.login.error.lockedOut)) {
        job.fail(403, 'auth.noaccess');
      } else if (page.present(e.login.user.field)) {
        action.login();
      }
    }
  },

  alertReceived: function() {
    if (message.match(/(Error Message LO001|Please enter both your User ID and Password)/i)) {
      job.fail(401, 'auth.creds.invalid.blank');
    } else if (message.match(/(Error Message LO011|Your User ID and Password must consist only of letters and numbers)/i)) {
      job.fail(401, 'auth.creds.invalid.characters');
    }
  },

  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, "https://chaseonline.chase.com/Logon.aspx");
    },

    login: function() {
      job.update('auth.creds');
      page.fill(e.login.user.field, answers.username);
      page.fill(e.login.pass.field, answers.password);
      page.click(e.login.continueButton);
    },

    logoff: function() {
      job.succeed();
      page.click(e.logoff.link);
    },
  },

  elements: {
    login: {
      user: {
        field: [
          '//input[@type="text"][@name="UserID"]',
          '//form[@name="Started"]//input[@type="text"]',
          '//input[@type="text"][@name="usr_name"]',
          '//form[@name="logonform"]//input[@type="text"]',
        ],
      },

      pass: {
        field: [
          '//input[@type="password"][@name="Password"]',
          '//form[@name="logonform"]//input[@type="password"]',
          '//input[@type="password"][@name="usr_password"]',
          '//form[@name="logonform"]//input[@type="password"]',
        ],
      },

      error: {
        general: [
          '//text()[contains(., "User ID or Password you entered is not correct")]',
        ],

        lockedOut: [
          '//text()[contains(., "Your User ID is Locked")]',
        ],
      },

      continueButton: [
        '//form[@name="logonform"]//input[@type="image" or @type="submit"]',
        '//*[contains(@id, "Logon") or contains(@id, "logon")]//input[@type="image" or @type="submit"]',
      ],
    },

    logoff: {
      link: [
        '//a[@id="logoffbutton"]',
        '//a[contains(@href, "LogOff")]',
        '//a[img[@alt="Log Off"]]',
      ],
    },
  },
});
