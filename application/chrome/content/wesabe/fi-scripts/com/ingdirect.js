wesabe.download.Player.register({
  fid: 'com.ingdirect',
  org: 'ING Direct',

  dispatchFrames: false,
  afterDownload: 'logoff',

  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, 'https://secure.ingdirect.com/myaccount/');
    },

    customerNumber: function() {
      job.update('auth.user');
      page.fill(e.login.user.input, answers.customerNumber || answers.username);
      page.click(e.login.user.continueButton);
    },

    pin: function() {
      // prevent filling in the PIN more than once per job, since that is almost
      // always an error and could result in the user getting locked out
      if (tmp.haveGivenPinBefore) return job.fail(401, 'auth.pass.invalid');
      else tmp.haveGivenPinBefore = true;

      var pin = answers.pin || answers.password;
      var pinmap = {
        a: 2, b: 2, c: 2,
        d: 3, e: 3, f: 3,
        g: 4, h: 4, i: 4,
        j: 5, k: 5, l: 5,
        m: 6, n: 6, o: 6,
        p: 7, q: 7, r: 7, s: 7,
        t: 8, u: 8, v: 8,
        w: 9, x: 9, y: 9, z: 9
      };

      job.update('auth.pass');
      for (var i = 0; i < pin.length; i++) {
        // map letters to numbers using the above (telephone) mapping
        var n = pinmap[pin[i].toLowerCase()] || pin[i];
        page.click(wesabe.xpath.bind(e.pinNumericButton, {n: n}));
      }
      page.click(e.pinSubmitButton);
    },

    goDownloadPage: function() {
      job.update('account.download');
      page.click(e.downloadLink);
    },

    downloadActivity: function() {
      page.fill(e.downloadPeriod, '60');    // last 60 days
      page.fill(e.downloadAccount, 'ALL');  // there are cases where this is "null"
      page.fill(e.downloadType, 'OFX');     // Microsoft Money (OFX)

      // FIXME <brian@wesabe.com> 2009-01-22: Rip out this workaround for MainForm not having an id.
      // ING Direct released a new feature on 2009-01-22 around 8am PST where you can now specify
      // a specific date range to download rather than just the Last N Days approach (YAY!), but
      // their code relies on an IE bug [1] where document.getElementById finds things by name (BOO!).
      //
      // [1] http://blogs.msdn.com/ie/archive/2008/04/10/html-and-dom-standards-compliance-in-ie8-beta-1.aspx (item #3)
      //
      // <hack>
      var form = page.findStrict(e.downloadForm),
          formid = form.getAttribute('id');
      if (formid) {
        wesabe.warn("MainForm already has an id (", formid, ") -- doing nothing");
      } else {
        formid = form.getAttribute('name');
        wesabe.warn("Setting MainForm's id to ", formid);
        form.setAttribute('id', wesabe.untaint(formid));
      }
      // </hack>

      page.click(e.downloadButton);
    },

    logoff: function() {
      job.succeed();
      page.click(e.signOffLink);
    }
  },

  dispatch: function() {
    tmp.authenticated = page.visible(e.signOffLink);

    var uri = wesabe.dom.browser.getURI(browser);
    if (uri && (uri.indexOf('pin_change_newpin') != -1)) {
      // user is being asked to change their PIN
      job.fail(403, 'auth.pass.expired');
      return;
    }

    if (tmp.authenticated) {
      if (page.visible(e.errors.noTransactionsForPeriod)) {
        wesabe.warn('No transactions available, skipping account');
        job.succeed();
        action.logoff();
      } else if (page.visible(e.downloadPeriod)) {
        action.downloadActivity();
      } else {
        action.goDownloadPage();
      }
    } else {
      var pinIsPresent = page.present(wesabe.xpath.bind(e.pinNumericButton, {n: 1}));

      if (page.present(e.login.errors.badCreds)) {
        job.fail(401, 'auth.creds.invalid');
      } else if (page.present(e.login.errors.lockedOut)) {
        job.fail(403, 'auth.noaccess');
      } else if (pinIsPresent && page.visible(e.errors.general)) {
        job.fail(401, 'auth.creds.invalid');
      } else if (pinIsPresent) {
        action.pin();
      } else if (page.present(e.security.answers)) {
        action.answerSecurityQuestions();
      } else if (page.present(e.login.user.input)) {
        action.customerNumber();
      }
    }
  },

  elements: {
    /////////////////////////////////////////////////////////////////////////////
    // Step 1: Customer Number
    /////////////////////////////////////////////////////////////////////////////

    login: {
      user: {
        // the text field for the user to type in their Customer Number
        input: [
          '//input[@name="ACN"]',
          '//form[@name="Signin"]//input[@type="text"]',
        ],

        // a dropdown field containing the Customer Number the site remembers -- we shouldn't hit this
        select: [
          '//select[@name="ACN"]',
          '//form[@name="Signin"]//select',
        ],

        // the image button that says "Next" and advances to the next page
        continueButton: [
          '//a[@id="btn_continue"]',
          '//form[@name="Signin"]//a[@href="#" or @title="Continue"]',
          '//a[@title="Continue"]',
        ],
      },

      errors: {
        lockedOut: '//text()[contains(., "you have reached the maximum number of login failures")]',

        badCreds: '//*[@class="errormsg"][contains(string(.), "check") or contains(string(.), "verify") or contains(string(.), "don\'t recognize")][contains(string(.), "Customer Number")]',
      },
    },

    /////////////////////////////////////////////////////////////////////////////
    // Step 2: Security Questions
    /////////////////////////////////////////////////////////////////////////////

    security: {
      questions: [
        '//label[@class="question"]//text()',
      ],

      answers: [
        '//input[contains(@name, "AnswerQ")]',
        '//input[contains(@name, "customerAuthenticationResponse.questionAnswer")]',
      ],

      setCookieCheckbox: [
        '//form[@name="CustomerAuthenticate"]//input[@type="checkbox" and @name="RegisterDevice"]',
        '//input[@type="checkbox" and @name="RegisterDevice"]',
        '//input[@name="RegisterDevice"]',
        // ING Direct appears to be testing something where the input names have changed,
        // so these may be the only ones that work in the future.
        '//form[@name="CustomerAuthenticate"]//input[@type="checkbox" and contains(@name, "customerAuthenticationResponse.device")]',
        '//input[@type="checkbox" and contains(@name, "customerAuthenticationResponse.device")]',
        '//input[contains(@name, "customerAuthenticationResponse.device")]',
      ],

      continueButton: [
        '//a[@id="btn_continue"]',
        '//form[@name="CustomerAuthenticate"]//a[@href="#" or @title="Continue"]',
        '//a[@title="Continue"]',
      ],
    },

    /////////////////////////////////////////////////////////////////////////////
    // Step 3: Confirm Your Image and Phrase
    /////////////////////////////////////////////////////////////////////////////

    // nothing yet

    /////////////////////////////////////////////////////////////////////////////
    // Step 4: PIN
    /////////////////////////////////////////////////////////////////////////////

    // the PIN field
    // pinPasswordField: [
    //   '//input[@id="PINID"][@type="password"]',
    //   '//input[@type="password"]'
    // ],
    // a pattern to match the numeric buttons on the pin pad
    pinNumericButton: [
      '//img[contains(@src, "images/pinpad/:n.gif")]',
      '//img[contains(@src, "/:n.gif")]'
    ],
    // the GO button on the pin pad
    pinSubmitButton: [
      '//a[@id="btn_continue"]',
      '//form[@name="CustomerAuthenticate"]//a[@href="#" or @title="Continue"]',
      '//a[@title="Continue"]',
    ],

    /////////////////////////////////////////////////////////////////////////////
    // Account List
    /////////////////////////////////////////////////////////////////////////////

    // account links
    accountLink: [
      '//a[@href="/myaccount/INGDirect.html?command=goToAccount&account=:n"]'
    ],

    downloadLink: [
      '//a[contains(@href, "download")][contains(string(.), "Download")]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // Download Activity
    /////////////////////////////////////////////////////////////////////////////

    downloadForm: [
      '//form[@name="MainForm" or @id="MainForm"]',
    ],

    downloadType: [
      '//form[@name="MainForm"]//select[@name="type"]',
      '//select[@name="type"]',
    ],

    // period
    downloadPeriod: [
      '//form[@name="MainForm"]//select[@name="FREQ"]',
      '//select[@name="FREQ"]',
    ],

    downloadButton: [
      '//a[@name="download"][contains(string(.), "Download")]',
    ],

    // which account (hidden field), should default to ALL, but doesn't always happen
    downloadAccount: [
      '//form[@name="MainForm"]//input[@name="account"]',
      '//input[@name="account"]',
    ],

    /////////////////////////////////////////////////////////////////////////////
    // global stuff
    /////////////////////////////////////////////////////////////////////////////

    // sign off link
    signOffLink: [
      '//a[contains(@href, "logout")]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // error messages
    /////////////////////////////////////////////////////////////////////////////

    errors: {
      general: [
        '//*[@class="errormsg" or @class="actionmsg"]',
      ],

      sessionExpired: [
        '//*[@class="actionmsg"][contains(string(text()), "session")][contains(string(text()), "expired")]'
      ],

      // the user entered their pin directly into the field
      pinLettersNotNumbers: [
        '//*[@class="errormsg"][contains(string(text()), "LETTERS")][contains(string(text()), "NUMBERS")]'
      ],

      noTransactionsForPeriod: [
        '//*[@class="errormsg" and contains(string(.), "no transactions for the selected timeframe")]'
      ],
    },
  },
});

wesabe.util.privacy.sanitize.registerSanitizer('ING PIN Digit', /pinpad\/\d.gif|[A-Z]\.gif/g);
wesabe.util.privacy.sanitize.registerSanitizer('ING Security Question', /AnswerQ[\d\.]+/g);
wesabe.util.privacy.sanitize.registerSanitizer('ING PIN Alt Text', /\b(one|two|three|four|five|six|seven|eight|nine|zero)\b/g);
