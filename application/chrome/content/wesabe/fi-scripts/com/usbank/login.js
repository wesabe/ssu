wesabe.provide('fi-scripts.com.usbank.login', {
  dispatch: function() {
    // only dispatch if we're not logged in
    if (page.present(e.logout.link)) return;

    if (page.present(e.errors.login.invalid)) {
      job.fail(401, 'auth.creds.invalid');
    } else if (page.present(e.errors.general)) {
      job.fail(401, 'auth.error.unknown');
    } else if (page.present(e.login.user.field)) {
      action.user();
    } else if (page.present(e.login.pass.field)) {
      action.pass();
    }
  },

  actions: {
    user: function() {
      job.update('auth.user');

      page.fill(e.login.user.field, answers.username);
      page.click(e.login.user.continueButton);
    },

    pass: function() {
      job.update('auth.pass');

      page.fill(e.login.pass.field, answers.password);
      page.click(e.login.pass.continueButton);
    },

    logout: function() {
      page.click(e.logout.link);
      job.succeed();
    },
  },

  elements: {
    login: {
      user: {
        field: [
          '//form[@name="logon2"]//input[@type="text" and @name="USERID"]',
          '//input[@type="text" and @name="USERID"]',
          '//form[@name="logon2"]//input[@type="text"]',
        ],

        continueButton: [
          '//form[@name="logon2"]//input[@type="image" or @type="submit"]',
          '//input[@type="image" or @type="submit"][contains(@alt, "Login")]',
        ],
      },

      pass: {
        field: [
          '//form[@name="password"]//input[@type="password"][@name="PSWD"]',
          '//input[@type="password"][@name="PSWD"]',
          '//form[@name="password"]//input[@type="password"]',
        ],

        continueButton: [
          '//form[@name="password"]//input[@type="image" or @type="submit"]',
          '//input[@type="image" or @type="submit"][contains(@alt, "Login")]',
        ],
      },

      errors: {
        invalid: [
          '//text()[contains(., "Error Code = A90000")]',
        ],
      },
    },
  },
});
