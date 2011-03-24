wesabe.download.Player.register({
  fid: "com.mechdirect",
  org: "Mechanics Bank",

  dispatchFrames: false,
  afterDownload: 'nextAccount',

  dispatch: function() {
    if (!page.present(e.logoff.link)) {
      log.debug('Session is not authenticated');
      if (page.present(e.login.error.invalidCreds)) {
        job.fail(401, 'auth.creds.invalid');
      } else if (page.present(e.login.user.field)) {
        action.login();
      } else if (page.present(e.security.enrollment.indicator)) {
        action.securityEnrollment();
      } else if (page.present(e.security.questions)) {
        action.answerSecurityQuestions();
      }
    } else {
      log.debug('Session is authenticated');
      if (!tmp.accounts) {
        if (!page.present(e.accounts.list.indicator)) {
          return page.click(e.nav.accountsTab.link);
        }

        // get the list of accounts -- does not cause page load
        action.collectAccounts();
      }

      if (!tmp.account) {
        tmp.account = tmp.accounts.shift();
      }

      if (tmp.account) {
        if (page.present(e.accounts.list.indicator)) {
          // we're on the account list, so go to the account page
          action.goToAccountPage();
        } else if (page.present(e.download.form.indicator)) {
          if (page.present(e.download.error.noTransactions)) {
            skipAccount("No transactions available, skipping (account=", tmp.account, ")");
            reload();
          } else {
            action.download();
          }
        } else if (page.present(e.nav.transactionMenu.link)) {
          // we're not on the transaction menu page, but we have a link to there
          action.goToDownloadPage();
        }

        return;
      }

      if (!tmp.accounts.length) {
        return action.logoff();
      }
    }
  },

  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, "https://www.mechdirect.com/cas_login/");
    },

    login: function() {
      page.fill(e.login.user.field, answers.username);
      page.fill(e.login.pass.field, answers.password);
      page.click(e.login.continueButton);
    },

    securityEnrollment: function() {
      if (page.present(e.security.enrollment.skipButton)) {
        page.click(e.security.enrollment.skipButton);
      } else {
        job.fail(403, 'auth.security.uninitialized');
      }
    },

    collectAccounts: function() {
      var accounts = page.select(e.accounts.list.item.container);

      tmp.accounts = accounts.map(function(node) {
        return {accountNumber: page.findStrict(e.accounts.list.item.accountNumber, node).nodeValue};
      });
      log.info("Found accounts: ", tmp.accounts);
    },

    goToAccountPage: function() {
      page.click(wesabe.xpath.bind(e.accounts.list.linkByAccountNumber, tmp.account));
    },

    goToDownloadPage: function() {
      page.click(e.nav.transactionMenu.link);
    },

    download: function() {
      page.fill(e.download.form.format.select, e.download.form.format.ofx);
      page.click(e.download.form.exportButton);
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
          '//input[@type="text" or not(@type)][@name="AccessId"]',
          '//form[@id="loginfrm"]//input[@type="text" or not(@type)]',
        ],
      },

      pass: {
        field: [
          '//input[@type="password"][@name="Password"]',
          '//form[@id="loginfrm"]//input[@type="password"]',
        ],
      },

      continueButton: [
        '//input[@type="submit" or @type="image"][@name="Log In" or @value="Log In"]',
      ],

      error: {
        invalidCreds: [
          '//text()[contains(., "Invalid access ID/password")]',
        ],
      },
    },

    security: {
      enrollment: {
        indicator: [
          '//div[@id="cas_wizard_steps"][contains(string(.), "Enrollment steps")]',
        ],

        skipButton: [
          '//input[@type="button"][@value="Provision later"]',
        ],
      },

      questions: [
        '//*[contains(@id, "Ques_")]//text()[contains(., "?")]',
        '//text()[contains(., "?")][ancestor::td/preceding-sibling::*[contains(string(.), "Question")]]',
      ],

      answers: [
        '//input[contains(@name, "Answer")]',
        '//input[ancestor::td/preceding-sibling::*[contains(string(.), "Answer")]]',
      ],

      continueButton: [
        '//input[@type="submit" or @type="image"][@name="bNext"]',
        '//input[@type="submit" or @type="image"][contains(@value, "Next")]',
      ],
    },

    accounts: {
      list: {
        indicator: [
          '//text()[contains(., "List of Accounts for")]',
        ],

        item: {
          container: [
            '//tr[@class="EVEN" or @class="ODD"][.//a[contains(@href, "DdaDetail")]]',
          ],

          accountNumber: [
            './/a[contains(@href, "DdaDetail")]//text()',
          ],
        },

        linkByAccountNumber: [
          '//a[contains(@href, "DdaDetail")][contains(string(.), ":accountNumber")]',
        ],
      },
    },

    download: {
      form: {
        indicator: [
          '//input[@type="submit"][@value="Export"]',
        ],

        format: {
          select: [
            '//select[@name="lstFormat"]',
          ],

          ofx: [
            './/option[@value="OFX"]',
            './/option[contains(string(.), "Microsoft Money")]',
          ],
        },

        exportButton: [
          '//input[@type="submit"][@value="Export"]',
        ],
      },

      error: {
        noTransactions: [
          '//text()[contains(., "No Transactions Available")]',
        ],
      },
    },

    nav: {
      accountsTab: {
        link: [
          '//*[img[@alt="Summary of Accounts"]]',
        ],
      },

      transactionMenu: {
        link: [
          '//a[img[@alt="Transaction Menu"]]',
          '//a[contains(@href, "TransMenu")]',
          '//*[img[@alt="Transaction Summary"]]',
        ],
      },
    },

    logoff: {
      link: [
        '//*[img[contains(@alt, "Log Off")]]',
      ],
    },
  },
});
