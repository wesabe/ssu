wesabe.provide("fi-scripts.com.citibank.login", {
  dispatch: function() {
    tmp.authenticated = page.visible(e.logoutButton);

    if (!tmp.authenticated) {
      if (page.visible(e.browserCheckButton)) {
        page.click(e.browserCheckButton);
      } else if (page.present(e.loginCredError)) {
        job.fail(401, 'auth.creds.invalid');
      } else if (page.visible(e.login.user.select)) {
        action.clearUsername();
      } else if (page.visible(e.login.user.text)) {
        action.login();
      }
    }
  },

  actions: {
    login: function() {
      job.update('auth.creds');
      if (page.present(e.login.user.text))
        page.fill(e.login.user.text, answers.username);
      page.fill(e.login.password.field, answers.password);
      page.click(e.login.button);
    },

    clearUsername: function() {
      // should trigger a page reload
      page.fill(e.login.user.select, e.login.user.options.change);
    },

    logout: function() {
      page.click(e.logoutButton);
      job.succeed();
    }
  },

  elements: {
    browserCheckButton: [
      '//form[@name="BrowseCheckForm"]//input[@type="image" or @type="submit"]',
    ],

    login: {
      user: {
        text: [
          '//form[@name="LoginPresentationForm"]//input[@type="text" and @name="username"]',
          '//input[@type="text" and @name="username"]',
          '//form[@name="LoginPresentationForm"]//input[@type="text"]',
        ],

        select: [
          '//form[@name="LoginPresentationForm"]//select[@name="username"]',
          '//select[@name="username"]',
          '//form[@name="LoginPresentationForm"]//select',
        ],

        options: {
          change: [
            './/option[@value="AddUser" or contains(string(.), "different user")]',
          ],
        },
      },

      password: {
        field: [
          '//form[@name="LoginPresentationForm"]//input[@type="password" and @name="password"]',
          '//input[@type="password" and @name="password"]',
          '//form[@name="LoginPresentationForm"]//input[@type="password"]',
          '//input[@type="password"]',
        ],
      },

      button: [
        '//form[@name="LoginPresentationForm"]//input[@type="image" or @type="submit"]',
        '//input[@type="image" or @type="submit"]'
      ],
    },

    loginCredError: [
      '//*[contains(string(.), "Information not recognized")]'
    ],

    logoutButton: [
      '//*[@id="myCitiSignInOut"]//a[contains(@href, "sof()")]',
      '//a[contains(@href, "sof()")]'
    ],

    noThanksButton: [
      '//a[@id="cmlink_NoThanks"]',
      '//a[contains(text(), "no thanks")]'
    ],

    logoutNoSnapshot: [
      '//a[contains(@href, "snapshot(false)")]',
    ],

    declineSessionSummary: [
      '//a[@id="link_lkSessionSummaryNo"]'
    ],

    signoffSuccess: [
      '//span[@class="jrspageHeader"]/text()[contains(., "Sign Off Complete")]',
      '//text()[contains(., "Sign Off Complete")]'
    ],
  },
});
