wesabe.provide("fi-scripts.ca-000102.login", {
  dispatch: function() {
    if (page.present(e.logoff.link)) return;

    if (page.present(e.login.error.user)) {
      job.fail(401, 'auth.user.invalid');
    } else if (page.present(e.login.error.pass)) {
      job.fail(401, 'auth.pass.invalid');
    } else if (page.present(e.login.error.creds)) {
      job.fail(401, 'auth.creds.invalid');
    } else if (page.present(e.login.error.security)) {
      job.fail(401, 'auth.security.invalid');
    } else if (page.present(e.login.user.field)) {
      action.login();
    } else if (page.present(e.security.questions)) {
      action.answerSecurityQuestions();
    }
  },

  // Actions are discrete steps that can be taken,
  // and often leave the current page, triggering
  // another call to dispatch.
  //
  // An example might be "login", as shown below,
  // which fills out the login form and submits it.
  //
  actions: {
    // sample -- replace this with your own custom logic
    login: function() {
      page.fill(e.login.user.field, answers.username);
      page.fill(e.login.pass.field, answers.password);
      page.click(e.login.continueButton);
    },

    // sample -- replace this with your own custom logic
    logoff: function() {
      page.click(e.logoff.link);
      // tells PFC that the job succeeded, and stops XulRunner (after a timeout)
      job.succeed();
    },
  },

  elements: {
    login: {
      user: {
        field: [
          '//form[@name="logonForm"]//input[@type="text"][@name="username"]',
          '//input[@type="text"][@name="username"]',
        ],
      },

      pass: {
        field: [
          '//input[@type="password"][@name="password"]',
          '//form[@name="logonForm"]//input[@type="password"]',
        ],
      },

      continueButton: [
        '//input[@type="submit"][@name="button"]',
        '//form[@name="logonForm"]//input[@type="submit"]',
      ],

      error: {
        user: [
          '//*[contains(@class, "dispute")]//text()[contains(., "User Name cannot be less than 6 characters")]',
          '//*[contains(@class, "dispute")]//text()[contains(., "User Name is required")]',
        ],

        pass: [
          '//*[contains(@class, "dispute")]//text()[contains(., "Password is required")]',
        ],

        creds: [
          '//text()[contains(., "we are unable to validate the information you have provided")]',
        ],

        security: [
          '//text()[contains(., "Incorrect security answer entered")]',
        ],

        noAccess: [
          // TBD
        ],
      },
    },

    logoff: {
      link: [
        '//a[contains(string(.), "Logoff") or contains(string(.), "Logout")][contains(@href, "Logoff")]',
      ],
    },

    security: {
      // the Text node of the questions
      questions: [
        '//form[@name="secondaryUserAuthForm"]//text()[contains(., "?")][preceding::text()[contains(., "Security Question")]][following::text()[contains(., "Security Answer")]]',
      ],

      // the <input/> element for the answers
      answers: [
        '//form[@name="secondaryUserAuthForm"]//input[@type="password"][@name="hintanswer"]',
      ],

      setCookieCheckbox: [
        '//form[@name="secondaryUserAuthForm"]//input[@type="radio"][@name="registerTrustedComputer"][@value="Yes"]',
      ],

      continueButton: [
        '//form[@name="secondaryUserAuthForm"]//input[@type="submit"][@name="submitNext"]',
      ],
    },
  },
});
