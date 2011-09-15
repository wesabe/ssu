wesabe.provide("fi-scripts.com.first-direct.login", {
  dispatch: function() {
    if (page.present(e.login.error.user)) {
      job.fail(401, 'auth.user.invalid');
    } else if (page.present(e.login.error.pass)) {
      job.fail(401, 'auth.pass.invalid');
    } else if (page.present(e.login.error.creds)) {
      job.fail(401, 'auth.creds.invalid');
    } else if (page.present(e.login.error.general)) {
      job.fail(401, 'auth.unknown');
    } else if (page.present(e.login.error.noAccess)) {
      job.fail(403, 'auth.noaccess');
    } else if (page.present(e.login.user.field)) {
      action.username();
    } else if (page.present(e.login.pass.passwordFields)) {
      action.password();
    }
  },

  actions: {
    username: function() {
      page.fill(e.login.user.field, answers.username);
      page.click(e.login.user.continueButton);
    },

    password: function() {
      action.pin();
      action.memorableAnswer();
      page.click(e.login.pass.continueButton);
    },

    pin: function() {
      var getInputsForPin = function() {
        return page.select(e.login.pass.passwordFields);
      };

      var getSubstringFromEnglishRangeDescription = function(string, rangeDescription) {
        var position = wesabe.lang.number.parseOrdinalPhrase(rangeDescription);
        log.debug('interpreted ', rangeDescription, ' as ', position);
        return wesabe.lang.string.substring(string, position-1, position);
      };

      var getLabelForInput = function(input) {
        return page.findStrict(bind(e.login.pass.labelForId, {id: input.id}));
      };

      getInputsForPin().forEach(function(input) {
        var label = getLabelForInput(input);
        page.fill(input, getSubstringFromEnglishRangeDescription(answers.password, label.innerHTML));
      });
    },

    memorableAnswer: function() {
      page.fill(e.login.pass.memorableAnswer, answers.memorable);
    },

    logoff: function() {
      page.click(e.logoff.link);
      job.succeed();
    },
  },

  elements: {
    login: {
      user: {
        field: [
          '//form[contains(@action, "Authentication")]//input[@type="text"][@name="userid"]',
          '//*[./h2[contains(string(.), "log on")]]//input[@type="text"][@name="userid"]',
        ],

        continueButton: [
          '//form[contains(@action, "Authentication")]//a[contains(concat(@href, @onclick), "submitData")]',
          '//*[./h2[contains(string(.), "log on")]]//a[contains(concat(@href, @onclick), "submitData")]',
        ],
      },

      pass: {
        passwordFields: [
          '//input[@type="password"][contains(@name, "password")]',
        ],

        labelForId: [
          '//label[@for=":id"]',
        ],

        memorableAnswer: [
          '//form[contains(@action, "Authentication")]//input[@type="password"][@name="memorableAnswer"]',
          '//*[./h1[contains(string(.), "log on")]]//input[@type="password"][@name="memorableAnswer"]',
        ],

        continueButton: [
          '//form[contains(@action, "Authentication")]//a[contains(concat(@href, @onclick), "submitData")]',
          '//*[./h2[contains(string(.), "log on")]]//a[contains(concat(@href, @onclick), "submitData")]',
        ],
      },

      error: {
        user: [
          '//text()[contains(., "username has not been recognised")]',
        ],

        pass: [
          '//text()[contains(., "Invalid password")]',
        ],

        creds: [
          '//text()[contains(., "Invalid username or password")]',
        ],

        general: [
          '//text()[contains(., "Could not log you in")]',
        ],

        noAccess: [
          // for example
          '//text()[contains(., "Your account has been locked")]',
        ],
      },
    },

    logoff: {
      link: [
        '//a[contains(string(.), "log off")][contains(@title, "log off internet banking")]',
      ],
    },

    // For most security questions there are text nodes containing
    // the whole question and <input/> elements to put answers in.
    // If this fits First Direct (UK) then you can simply
    // fill out these xpaths below and call the
    // "answerSecurityQuestions" action.
    //
    // If not, you'll need to create your own action to handle
    // the custom logic for First Direct (UK).
    security: {
      // the Text node of the questions
      questions: [
        // for example:
        '//form[@name="sq"]//label[contains(string(.), "?")]//text()',
      ],

      // the <input/> element for the answers
      answers: [
        // for example:
        '//form[@name="sq"]//input[@type="text"][contains(@name, "sq_answer")]',
      ],

      // optional, usually labelled "Don't ask me again on this computer"
      setCookieCheckbox: [
      ],

      // the "Next" or "Continue" button to submit the form
      continueButton: [
      ],
    },
  },
});
