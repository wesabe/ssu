// This is the login part of the Vancity
// script, included by com.vancity.js one level up.
//
// This part handles logging in, and contains all the
// logic and page element references related to it.
//
wesabe.provide("fi-scripts.com.vancity.login", {
  dispatch: function() {
    if (page.present(e.logoff.link)) return;

    if (page.present(e.login.error.creds)) {
      job.fail(401, 'auth.creds.invalid');
    } else if (page.present(e.login.error.security)) {
      job.fail(401, 'auth.security.invalid');
    } else if (page.present(e.login.user.field)) {
      action.user();
    } else if (page.present(e.login.pass.field)) {
      action.pass();
    } else if (page.present(e.security.questions)) {
      action.answerSecurityQuestions();
    }
  },

  alertReceived: function(message) {
    if (message.match(/Branch cannot be blank/i))
      job.fail(401, 'auth.branch.invalid.blank');
    else if (message.match(/Account Number cannot be blank/i))
      job.fail(401, 'auth.user.invalid.blank');
    else if (message.match(/Account Number must consist of numeric values only/i))
      job.fail(401, 'auth.user.invalid.chars');
    else if (message.match(/Please enter a Member Number consisting of numbers, or the letter D followed by seven numbers/i))
      job.fail(401, 'auth.user.invalid.format');
    else if (message.match(/Account Number is too short/i))
      job.fail(401, 'auth.user.invalid.length');
    else if (message.match(/Personal Access Code \(PAC\) cannot be blank/i))
      job.fail(401, 'auth.pass.invalid.blank');
    else if (message.match(/Personal Access Code \(PAC\) must consist of numeric values only/i))
      job.fail(401, 'auth.pass.invalid.chars');
    else if (message.match(/Personal Access Code \(PAC\) is too short/i))
      job.fail(401, 'auth.pass.invalid.length');
    else if (message.match(/You must enter an answer to the challenge question/i))
      job.fail(401, 'auth.security.invalid.blank');
  },

  actions: {
    user: function() {
      job.update('auth.user');
      page.fill(e.login.branch.field, answers.branch);
      page.fill(e.login.user.field, answers.username);
      page.click(e.login.continueButton);
    },

    pass: function() {
      job.update('auth.pass');
      page.fill(e.login.pass.field, answers.password);
      page.click(e.login.continueButton);
    },

    logoff: function() {
      page.click(e.logoff.link);
      job.succeed();
    },
  },

  elements: {
    login: {
      branch: {
        field: [
          '//form[@name="mdlogon"]//input[@type="text"][@name="branch"]',
        ],
      },

      user: {
        field: [
          '//form[@name="mdlogon"]//input[@type="text"][@name="acctnum"]',
        ],
      },

      pass: {
        field: [
          '//input[@type="password"][@name="pac"]',
          '//form[@name="mdlogon"]//input[@type="password"]',
        ],
      },

      continueButton: [
        '//form[@name="mdlogon"]//input[@type="submit" or @type="image"]',
      ],

      error: {
        creds: [
          '//text()[contains(., "Sorry, the information you provided is incorrect, please try again")]',
        ],

        security: [
          '//text()[contains(., "Sorry, but that was not the correct answer")]',
        ],
      },
    },

    logoff: {
      link: [
        '//a[contains(@href, "/Logout/")][contains(string(.), "log out")]',
      ],
    },

    security: {
      // the Text node of the questions
      questions: [
        '//form[@name="mdlogon"]//label[@for=..//input/@id]//text()',
      ],

      // the <input/> element for the answers
      answers: [
        '//form[@name="mdlogon"]//input[@type="text"][contains(@name, "answer")]',
      ],

      setCookieSelect: [
        '//form[@name="mdlogon"]//select[@name="BIND_DEVICE"]',
      ],

      setCookieOption: [
        './/option[@value="on"]',
      ],

      // the "Next" or "Continue" button to submit the form
      continueButton: [
        '//form[@name="mdlogon"]//input[@type="submit" or @type="image"]',
      ],
    },
  },
});
