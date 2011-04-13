wesabe.download.Player.register({
  fid: 'com.wellsfargo',
  org: 'Wells Fargo',

  dispatchFrames: false,
  afterDownload: 'nextAccount',

  dispatch: function() {
    tmp.authenticated = page.visible(e.signoffLink);
    wesabe.debug('authenticated=', tmp.authenticated);

    if (!tmp.authenticated) {
      if (page.present(e.page.unavailable.indicator)) {
        job.fail(503, 'fi.unavailable');
      } else if (page.visible(e.errorWrongUsernameOrPassword)) {
        job.fail(401, 'auth.creds.invalid');
      } else if (page.visible(e.errorWrongUsername)) {
        job.fail(401, 'auth.user.invalid');
      } else if (page.present(e.security.page.indicator)) {
        if (page.present(e.security.page.info.indicator)) {
          job.fail(403, 'auth.security.uninitialized');
        } else if (page.present(e.security.page.setup.indicator)) {
          job.fail(403, 'auth.security.uninitialized');
        } else {
          // FIXME <brian@wesabe.com> 2008-09-23: temporary way to
          // figure out what the security questions page looks like
          page.dumpPrivately();
          job.fail(500, 'script.incomplete.security');
        }
      } else if (page.visible(e.errorCannotVerifyEntry)) {
        job.fail(403, 'auth.noaccess');
      } else if (page.present(e.login.pass.errors.invalidCharacters)) {
        job.fail(401, 'auth.pass.invalid.characters');
      } else if (page.visible(e.errorOfSomeKind)) {
        job.fail(401, 'auth.unknown');
      } else if (page.present(e.offers.bypass.link)) {
        // don't decline the offer, but say that we want to see it later
        page.click(e.offers.bypass.link);
      } else if (page.visible(e.login.user.field)) {
        action.login();
      }
    } else {
      // on the download page?
      if (page.present(e.downloadYourAccountActivityTitle)) {
        // get the account list
        if (!tmp.accounts) {
          action.beginDownloads();
        }

        if (tmp.account) {
          // account has been selected but not downloaded
          if (page.visible(e.downloadErrorNoAccountInformation)) {
            wesabe.error('Skipping account ',tmp.account,' for lack of transactions');
            delete tmp.account;
            reload();
          } else {
            action.downloadSelectedAccount();
          }
        } else {
          // account has not been selected yet -- do we have any more?
          if (tmp.accounts.length) {
            tmp.account = tmp.accounts.shift();
            action.selectAccount();
          } else {
            action.logout();
          }
        }
      } else {
        action.goDownloadPage();
      }
    }
  },

  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, 'https://wellsfargo.com/');
    },

    login: function() {
      job.update('auth.creds');
      page.fill(e.login.destination.selector, e.login.destination.choices.mainMenu);
      page.fill(e.login.user.field, answers.login || answers.username);
      page.fill(e.login.pass.field, answers.password);
      page.click(e.login.continueButton);
    },

    goDownloadPage: function() {
      job.update('account.download');
      page.click(e.downloadAccountActivityLink);
    },

    beginDownloads: function() {
      var options = page.select(e.downloadAccountOption);
      tmp.accounts = options.map(function(option) {
        return {name: option.innerHTML, value: option.value};
      });
      log.info('accounts=', tmp.accounts);
    },

    selectAccount: function() {
      log.info('account=', tmp.account);
      page.fill(e.downloadAccountSelect, tmp.account.value);
      page.click(e.downloadChooseAccountButton);
    },

    downloadSelectedAccount: function() {
      log.info('account=', tmp.account);
      page.click(e.ofxFileFormat);
      page.click(e.downloadButton);
    },

    logout: function() {
      job.succeed();
      page.click(e.signoffLink);
    }
  },

  elements: {
    login: {
      // the first page the user hits after logging in
      destination: {
        selector: [
          '//select[@name="destination"]',
          '//form[@name="signon"]//select'
        ],

        choices: {
          mainMenu: [
            './/option[@value="MainMenu"]',
            './/option[contains(string(.), "Account Services")]',
          ],
        },
      },

      user: {
        field: [
          '//input[@name="userid"]',
          '//form[@name="signon"]//input[@type="text"]'
        ],
      },

      pass: {
        field: [
          '//input[@name="password"]',
          '//form[@name="signon"]//input[@type="password"]',
          '//input[@type="password"]'
        ],

        errors: {
          invalidCharacters: [
            '//text()[contains(., "password entered contains invalid characters")]',
          ],
        },
      },

      continueButton: [
        '//input[@name="btnSignon" or @name="signon"]',
        '//form[@name="signon" or @name="Signon"]//input[@type="image" or @type="submit"]'
      ],
    },

    security: {
      page: {
        info: {
          indicator: [
            '//text()[contains(., "Select and answer three security questions")]',
          ],
        },

        setup: {
          indicator: [
            '//form[@name="RegistrationIntroForm"]//input[@value="Select Questions"]',
            '//text()[contains(., "select your security questions now")]',
          ],
        },

        indicator: [
          '//title[contains(string(.), "Wells Fargo Security Questions")]',
        ],
      },

      questions: [
        // TODO: figure out the HTML for this
      ],

      answers: [
        // TODO: figure out the HTML for this
      ],

      continueButton: [
        // TODO: figure out the HTML for this
      ],
    },

    /////////////////////////////////////////////////////////////////////////////
    // main menu
    /////////////////////////////////////////////////////////////////////////////

    // page title
    accountServicesPageTitle: [
      '//title[contains(string(text()), "Account Services")]'
    ],
    // Download Account Activity
    downloadAccountActivityLink: [
      '//a[contains(string(text()), "Download Account Activity")]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // account activity
    /////////////////////////////////////////////////////////////////////////////

    // OFX file format
    ofxFileFormat: [
      '//input[@value="microsoftOfx" and @name="fileFormat"]',
      '//input[@value="quickenOfx" and @name="fileFormat"]',
    ],
    // download button
    downloadButton: [
      '//input[@type="submit" and @name="downloadButton"]'
    ],
    // page title
    downloadYourAccountActivityTitle: [
      '//title[contains(string(text()), "Download Your Account Activity")]'
    ],
    // download account options
    downloadAccountOption: [
      '//form[@name="DownloadFormBean"]//select[@name="primaryKey"]/option',
      '//form[@name="DownloadFormBean"]//select/option',
      '//select[@name="primaryKey"]/option',
      '//select/option'
    ],
    // account list
    downloadAccountSelect: [
      '//form[@name="DownloadFormBean"]//select[@name="primaryKey"]',
      '//form[@name="DownloadFormBean"]//select',
      '//select[@name="primaryKey"]',
      '//select'
    ],
    // the Select button used to choose the account
    downloadChooseAccountButton: [
      '//form[@name="DownloadFormBean"]//input[@name="selectButton"]',
      '//input[@name="selectButton"]',
      '//form[@name="DownloadFormBean"]//input[contains(@value, "Select") and (@type="submit" or @type="image")]',
      '//input[contains(@value, "Select") and (@type="submit" or @type="image")]'
    ],

    downloadErrorNoAccountInformation: [
      '//div[@id="pageerrors" and contains(string(.), "no Account Activity information available")]',
      '//div[contains(string(.), "no Account Activity information available")]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // account list
    /////////////////////////////////////////////////////////////////////////////

    // the heading at the top of the page
    accountSummaryHeading: [
      '//h1[contains(string(text()), "Account Summary")]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // global
    /////////////////////////////////////////////////////////////////////////////

    // link to sign off
    signoffLink: [
      '//a[string(text())="Sign Off"]'
    ],

    errorWrongUsername: [
      '//*[(contains(@class, "error") or contains(@class, "alert")) and contains(string(.), "entered an invalid username")]'
    ],

    errorWrongUsernameOrPassword: [
      '//*[(contains(@class, "error") or contains(@class, "alert")) and contains(string(.), "do not recognize your username and/or password")]',
    ],

    errorCannotVerifyEntry: [
      '//*[(contains(@class, "error") or contains(@class, "alert")) and contains(string(.), "cannot verify your entry")]'
    ],

    errorOfSomeKind: [
      '//img[@alt="Error"]'
    ],

    page: {
      unavailable: {
        indicator: [
          '//title[contains(string(.), "WellsFargo.com is temporarily unavailable")]',
        ],
      },
    },

    offers: {
      decline: {
        link: [
          '//form[@name="SplashPageForm"]//input[@value="Not at this time"]',
          '//form[@name="SplashPageForm"]//span[@id="buttonPeripheral"]//input[@type="submit"]',
        ],
      },

      bypass: {
        link: [
          '//form[@name="SplashPageForm"]//input[@value="Show me later"]',
          '//form[@name="SplashPageForm"]//span[@id="buttonAssociated"]//input[@type="submit"]',
        ],
      },
    },
  },
});

wesabe.util.privacy.registerSanitizer('Wells Fargo Session ID', /sessargs=[^=&\?]*/g);
