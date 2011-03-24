// This part only exists because mobile browsers, by and large,
// do not have flash and therefore cannot participate in BofA's
// SafePass feature, forcing them to ask the user a security
// question instead.
//
// Fortunately for us, the cookie given to us when we choose
// the "Yes, I use this device frequently" radio button allows
// us to access the main Bank of America site sans-SafePass.
// Yay for lax security specifications?
wesabe.provide('fi-scripts.us-000238.mobile', {
  dispatch: function() {
    // only dispatch when we're on the mobile site
    if (!page.present(e.mobile.indicator)) return;

    if (page.visible(e.mobile.login.error)) {
      job.fail(401, 'auth.pass.invalid');
    } else if (page.present(e.mobile.login.link)) {
      action.mobileBeginLogin();
    } else if (page.present(e.mobile.login.user.field)) {
      action.mobileOnlineID();
    } else if (page.present(e.security.answers)) {
      action.answerSecurityQuestions();
    } else if (page.present(e.mobile.login.pass.field)) {
      action.mobilePasscode();
    } else if (page.present(e.mobile.landing.indicator)) {
      action.mobileContinueToMobileBanking();
    } else if (page.present(e.mobile.main.indicator)) {
      action.mobileGoMainLoginPage();
    }
  },

  actions: {
    mobileMain: function() {
      wesabe.dom.browser.go(browser, "https://www.bankofamerica.com/mobile");
    },

    mobileBeginLogin: function() {
      page.click(e.mobile.login.link);
    },

    mobileOnlineID: function() {
      page.fill(e.mobile.login.user.field, answers.userId || answers.username);
      page.click(e.mobile.login.user.continueButton);
    },

    mobilePasscode: function() {
      page.fill(e.mobile.login.pass.field, answers.passcode || answers.password);
      page.click(e.mobile.login.pass.continueButton);
    },

    mobileContinueToMobileBanking: function() {
      page.click(e.mobile.landing.continueButton);
    },

    mobileGoMainLoginPage: function() {
      wesabe.dom.browser.go(browser, 'https://www.bankofamerica.com/');
    },
  },

  elements: {
    mobile: {
      indicator: [
        '//h3[contains(string(.), "Mobile Banking")]',
        '//form[contains(@action, "signonMobile")]',
        '//form[contains(@action, "verifyImageMobile")]',
        '//text()[contains(., "Welcome to Mobile Banking")]',
        '//h3[contains(string(.), "Bank Menu") and following::a[contains(string(.), "Accounts") and @accesskey]]',
      ],

      login: {
        link: [
          '//a[contains(@href, "signonScreen")]',
          '//a[contains(string(.), "Sign in")]',
        ],

        error: [
          '//text()[contains(., "Incorrect passcode")]',
        ],

        user: {
          field: [
            '//form[contains(@action, "signonMobile")]//input[@type="text" and @name="onlineID"]',
            '//input[@type="text" and @name="onlineID"]',
          ],

          continueButton: [
            '//form[contains(@action, "signonMobile")]//input[@type="submit" or @type="image"]',
            '//input[(@type="submit" or @type="image") and contains(@value, "Sign In")]',
          ],
        },

        pass: {
          field: [
            '//form[contains(@action, "verifyImageMobile")]//input[@type="password" and @name="passcode"]',
            '//input[@type="password" and @name="passcode"]',
          ],

          continueButton: [
            '//form[contains(@action, "verifyImageMobile")]//input[@type="submit" or @type="image"]',
            '//input[(@type="submit" or @type="image") and contains(@value, "Sign In")]',
          ],
        },
      },

      landing: {
        indicator: '//text()[contains(., "Welcome to Mobile Banking")]',

        continueButton: [
          '//form[contains(@action, "LoginEntryPoint")]//input[@type="submit" or @type="image"]',
          '//input[(@type="submit" or @type="image") and contains(@value, "Enter")]',
        ],
      },

      main: {
        indicator: '//h3[contains(string(.), "Bank Menu")]',
      },
    },
  },
});
