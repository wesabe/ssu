wesabe.provide('fi-scripts.uk-000100.login', {
  dispatch: function() {
    if (page.present(e.login.error.unknown)) {
      return job.fail(401, 'auth.unknown');
    }

    if (page.present(e.login.error.creds)) {
      return job.fail(401, 'auth.creds.invalid');
    }

    if (page.visible(e.login.user.field)) {
      return action.username();
    }

    if (page.visible(e.login.pass.answer)) {
      return action.password();
    }
  },

  alertReceived: function(message) {
    if (/ensure you have entered your date of birth, using numbers only/.test(message)) {
      job.fail(401, 'auth.creds.invalid.format');
    }
  },

  actions: {
    username: function() {
      job.update('auth.user');

      page.fill(e.login.user.field, answers.username);
      page.click(e.login.user.continueButton);
    },

    password: function() {
      job.update('auth.pass');

      var number = '';
      var indicies = page.select(e.login.pass.indicies, page.find(e.login.pass.number));

      indicies.forEach(function(ielement) {
        var istring = wesabe.lang.string.trim(wesabe.untaint(ielement.nodeValue));
        var inumber = wesabe.lang.number.parseOrdinalPhrase(istring);

        if (wesabe.isUndefined(inumber)) {
          log.warn('could not understand ', ielement, ', continuing anyway');
        } else {
          log.debug('interpreting ', ielement, ' as ', inumber);
          number += wesabe.lang.string.substring(answers.password, inumber - 1, inumber);
        }
      });

      // enter memorable data
      page.fill(e.login.pass.answer, answers.memorable);
      // enter security number
      page.fill(e.login.pass.number, number);
      // click Continue
      page.click(e.login.pass.continueButton);
    },

    logoff: function() {
      page.click(e.logoff.button);
      job.succeed();
    },
  },

  elements: {
    login: {
      user: {
        field: [
          '//form[@id="IBloginForm"]//input[@name="userid"]',
          '//input[@name="userid" and @type="text"]',
          '//form[@id="IBloginForm"]//input[@type="text"]',
        ],

        continueButton: [
          '//form[@id="IBloginForm"]//a[@title="Log on"]',
          '//form[@id="IBloginForm"]//a',
          '//a[@title="Log on"]',
        ],
      },

      pass: {
        answer: [
          '//form[@name="PC_7_1_5PF_cam10To30Form"]//input[@name="memorableAnswer" and @type="password"]',
          '//form//input[@name="memorableAnswer" and @type="password"]',
          '//input[@name="memorableAnswer" and @type="password"]',
          '//form[@name="PC_7_1_5PF_cam10To30Form"]//input[@type="password"]',
        ],

        number: [
          '//form[@name="PC_7_1_5PF_cam10To30Form"]//input[@name="password" and @type="password"]',
          '//form//input[@name="password" and @type="password"]',
          '//input[@name="password" and @type="password"]',
          '//input[@type="password"]',
        ],

        indicies: [
          'ancestor::div[position()=1]//text()[contains(., "FIRST")]',
          'ancestor::div[position()=1]//text()[contains(., "SECOND")]',
          'ancestor::div[position()=1]//text()[contains(., "THIRD")]',
          'ancestor::div[position()=1]//text()[contains(., "FOURTH")]',
          'ancestor::div[position()=1]//text()[contains(., "FIFTH")]',
          'ancestor::div[position()=1]//text()[contains(., "SIXTH")]',
          'ancestor::div[position()=1]//text()[contains(., "SEVENTH")]',
          'ancestor::div[position()=1]//text()[contains(., "EIGHTH")]',
          'ancestor::div[position()=1]//text()[contains(., "NINTH")]',
          'ancestor::div[position()=1]//text()[contains(., "TENTH")]',
          'ancestor::div[position()=1]//text()[contains(., "LAST")]',
          'ancestor::div[position()=1]//span[@class="hsbcTextHighlight"]//text()',
        ],

        continueButton: [
          '//form[@name="PC_7_1_5PF_cam10To30Form"]//a[@title="Continue"]',
          '//form//a[@title="Continue"]',
          '//form[@name="PC_7_1_5PF_cam10To30Form"]//a[contains(string(.), "Continue")]',
          '//form//a[contains(string(.), "Continue")]',
        ],
      },

      error: {
        unknown: [
          '//text()[contains(., "error reference HK1")]',
        ],

        creds: [
          '//text()[contains(., "try once again ensuring that you enter the required details correctly")]',
        ],
      },
    },

    logoff: {
      button: [
        '//a[@name="login" and @title="Log off"]',
        '//a[@name="login" and contains(@href, "idv_cmd=idv.Logoff")]',
        '//a[@title="Log off"]',
        '//a[contains(@href, "idv_cmd=idv.Logoff")]',
      ],
    },
  },
});
