// This is the login part of the TD Canada Trust
// script, included by com.tdcanadatrust.js one level up.
//
// This part handles logging in, and contains all the
// logic and page element references related to it.
//
wesabe.provide("fi-scripts.com.tdcanadatrust.login", {
  // The "dispatch" function is called every time a page
  // load occurs (using the ondomready callback, not onload).
  dispatch: function() {
    // only dispatch when the logoff link is hidden
    if (page.present(e.logoff.link)) return;

    if (page.present(e.login.error.creds)) {
      return job.fail(401, 'auth.creds.invalid');
    } else if (page.present(e.login.user.field)) {
      return action.login();
    } else if (page.present(e.security.indicator)) {
      return action.answerSecurityQuestions();
    }
  },

  alertReceived: function() {
    if (message.match(/Please enter a valid access card number or connect id/)) {
      job.fail(401, 'auth.user.invalid');
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
    login: function() {
      var username = answers.username;
      username = username.replace(/\s/g, '');     // remove all spaces
      username = username.replace(/^589297/, ''); // remove start of TD Canada Trust card number (not part of Online Access Number)

      page.fill(e.login.user.field, username);
      page.fill(e.login.description.field, answers.description || 'Wesabe');
      page.fill(e.login.pass.field, answers.password);
      // causes the form to be submitted, triggering another page
      // load, which then calls dispatch again -- hopefully as a
      // logged-in user this time
      page.click(e.login.continueButton);
    },

    logoff: function() {
      job.succeed(); // tells PFC that the job succeeded, and stops XulRunner (after a timeout)
      page.click(e.logoff.link);
    },
  },

  // elements are xpaths or sets of xpaths that
  // illustrate how to access a particular element
  // on a page
  //
  // used by the page.* methods, available as "e"
  // in dispatch and actions
  elements: {
    login: {
      user: {
        field: [
          '//form[@name="LogonDisplay"]//input[@name="ConnectID"][@type="text" or not(@type)]',
          '//input[@name="ConnectID"][@type="text" or not(@type)]',
          '//form[@name="LogonDisplay"]//input[preceding-sibling::*[contains(string(.), "589297")]][@type="text" or not(@type)]', // this number is probably just a sample
        ],
      },

      description: {
        field: [
          '//form[@name="LogonDisplay"]//input[@name="Description"][@type="text" or not(@type)]',
          '//input[@name="Description"][@type="text" or not(@type)]',
          '//form[@name="LogonDisplay"]//input[preceding-sibling::*[contains(string(.), "Description")]][@type="text" or not(@type)]',
        ],
      },

      pass: {
        field: [
          '//form[@name="LogonDisplay"]//input[@type="password"][@name="Password"]',
          '//input[@type="password"][@name="Password"]',
          '//form[@name="LogonDisplay"]//input[@type="password"]',
        ],
      },

      continueButton: [
        '//form[@name="LogonDisplay"]//a[contains(@onclick, "login")]',
        '//a[contains(@onclick, "login")][img[contains(@alt, "Login")]]',
      ],

      error: {
        creds: [
          '//text()[contains(., "You have entered invalid login information")]',
        ],
      },
    },

    logoff: {
      link: [
        '//a[has-class("logout")][contains(@href, "LogoffServlet")]',
        '//a[img[contains(@src, "logout")]]',
      ],
    },

    security: {
      indicator: [
        '//form[@name="challengeCustomer"]',
        '//*[has-class("pageTitle")][contains(string(.), "Maintain Security Options")]',
      ],

      // the Text node of the questions
      questions: [
        // the full text of the error we need to make sure we exclude is this:
        //   The answer to your security question cannot contain special characters (e.g. #, &, ?). Please enter a valid answer.
        '//form[@name="challengeCustomer"]//text()[contains(., "?")][not(ancestor::a)][not(contains(., "Please enter a valid answer"))]',
      ],

      // the <input/> element for the answers
      answers: [
        '//form[@name="challengeCustomer"]//input[@name="challengeAnswer"]',
        '//form[@name="challengeCustomer"]//input[@type="password"]',
      ],

      // the "Next" or "Continue" button to submit the form
      continueButton: [
        '//form[@name="challengeCustomer"]//a[contains(@onclick, "challenge")]',
        '//form[@name="challengeCustomer"]//a[img[@alt="next" or @alt="Next"]]',
      ],
    },
  },
});
