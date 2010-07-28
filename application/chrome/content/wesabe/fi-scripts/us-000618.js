wesabe.download.Player.register({
  fid: 'us-000618',
  org: 'City National Bank of Taylor',

  dispatchFrames: true,
  // afterUpload: custom onUploadSuccessful below

  dispatch: function() {
    if (!page.defaultView.frameElement) {
      if (page.visible(e.loginButton)) {
        tmp.authenticated = false;
      }
      else {
        // if we're not a frame-element AND there was no login button to be
        // found then odds are good that this is the frameset defining page,
        // so simply return, some other dispatch call will do all the heavy
        // lifting
        return;
      }
    }
    else {
      if (page.defaultView.name.match(/fx_top/i)) {
        // if dispatch was called on the "top" frame, there's nothing for us
        // to do here, so simply return, some other dispatch call will do all
        // the heavy lifting.
        return;
      }
      else {
        var nav_page = wesabe.dom.page.wrap(page.defaultView.top.frames[0].document);
        tmp.authenticated = nav_page.visible(e.logoutButton);
      }
    }

    wesabe.debug('authenticated=', tmp.authenticated);

    if (page.present(e.security.page.reminder.indicator)) {
      // there is a page titled "FX : Services : Change Security Question and Answer Reminder" at
      // https://secure.fundsxpress.com/piles/fxweb.pile/services/sec_info/change_question_reminder
      // which, apparently, is supposed to remind people to set up security questions or something.
      // here we capture the HTML of that page to see how we might get past it.
      page.dumpPrivately();
      return job.fail(500, 'ssu.script.incomplete');
    }

    // if not-authenticated
    if (!tmp.authenticated) {
      // and if our username/password is wrong
      if (page.present(e.errorWrongUsernameOrPassword)) {
        // then fail
        job.fail(401, 'auth.creds.invalid');
      } else if (page.present(e.errorSiteInMaintanceMode)) {
        // site could be down for maintance
        job.fail(503, 'fi.unavailable');
      } else if (page.visible(e.loginPassword)) {
        // otherwise try to login
        action.login();
      }
    } else {

      // urgent messages will interrupt the page flow forcably directing the
      // user to the messages page. if that's happened we have to select the
      // accounts link our selves.
      if (page.visible(e.unreadMessages)) {
        action.goAccountsPage();
        return;
      }

      // detect if we're on the account selection page, if so and we haven't
      // already done so, collect all the account history links. then start
      // following the links. once we've gotten them all, log off.
      if (page.visible(e.accountHistoryLink)) {
        if (!tmp.accountIds) {
          action.collectAccountIds();
        }

        if (!tmp.accountIds.length) {
          action.logout();
        }
        else {
          tmp.accountId = tmp.accountIds.shift();
          action.goAccountHistoryPage();
        }
        return;
      }

      // detect if we're on the account history download page, if so fill
      // in the date-ranges and download away.
      if (page.visible(e.downloadButton)) {
        if (tmp.accountId) {
          action.download();
        }
        else {
          if (!tmp.accountIds.length) {
            action.logout();
          }
          else {
            action.goAccountsPage();
          }
        }
        return;
      }
    }
  },


  actions: {
    main: function() {
      wesabe.dom.browser.go(
        browser,
        "https://secure.fundsxpress.com/piles/fxweb.pile/fx?iid=CNB"
      );
    },


    login: function() {
      job.update('auth.creds');
      page.fill(e.loginUserId, answers.username);
      page.fill(e.loginPassword, answers.password);
      page.fill(e.loginOnToPage, e.loginOnToPageAccounts);
      page.click(e.loginButton);
    },


    goAccountsPage: function() {
      if (page.visible(e.logoutButton))
        page.click(e.accountsButton);
      else {
        var nav_page = wesabe.dom.page.wrap(page.defaultView.top.frames[0].document);
        nav_page.click(e.accountsButton);
      }
    },


    goAccountHistoryPage: function() {
      wesabe.debug('trying to go to account history page');
      page.click(wesabe.xpath.bind(
        e.specificAccountHistoryLink, { 'href' : wesabe.untaint(tmp.accountId) }
      ));
    },


    collectAccountIds: function() {
      // note that these ids are not account numbers but an integer that the
      // fi associates with an account number.
      tmp.accountIds = page.select(e.accountHistoryLink).map(function(el){
        return el.href.match(/id=\d+/).shift();
      });
      wesabe.info('account_ids=', tmp.accountIds);
    },


    download: function() {
      job.update('account.download');

      page.fill(e.downloadFormat, e.downloadFormatOFX);
      page.click(e.downloadButton);
    },


    logout: function() {
      this.job.succeed();

      if (page.visible(e.logoutButton)) {
        page.click(e.logoutButton);
      }
      else {
        var nav_page = wesabe.dom.page.wrap(page.defaultView.top.frames[0].document);
        nav_page.click(e.logoutButton);
      }
    }
  },


  extensions: {
    onUploadSuccessful: function(browser, page) {
      delete this.tmp.accountId;
      this.onDocumentLoaded(
        browser,
        wesabe.dom.page.wrap(page.defaultView.top.frames[1].document)
      );
    },
  },


  elements: {
    /////////////////////////////////////////////////////////////////////////////
    // login page
    /////////////////////////////////////////////////////////////////////////////

    loginUserId: [
      '//form[@name="login"]//input[@name="aid"]',
      '//input[@name="aid"]',
      '//form[@name="login"]//input[@type="text"]',
      '//input[@type="text"]'
    ],

    loginPassword: [
      '//form[@name="login"]//input[@name="password"]',
      '//input[@name="password"]',
      '//form[@name="login"]//input[@type="password"]',
      '//input[@type="password"]'
    ],

    // fxfn customers can login directly to a given page or it'll go to the
    // users default page or the sites default page if neither of the first
    // two are defined
    loginOnToPage: [
      '//form[@name="login"]//select[@name="page"]',
      '//select[@name="page"]'
    ],

    loginOnToPageAccounts: [
      './/option[contains(@value, "accounts")]'
    ],

    loginButton: [
      '//form[@name="login"]//input[@value="Log In"]',
      '//input[@value="Log In"]',
      '//form[@name="frmLogin"]//input[@type="submit" or @type="image"]',
      '//input[@type="submit" or @type="image"]'
    ],

    security: {
      page: {
        reminder: {
          indicator: [
            '//title[contains(string(.), "Change Security Question and Answer Reminder")]',
          ],
        },
      },
    },

    /////////////////////////////////////////////////////////////////////////////
    // accounts page
    /////////////////////////////////////////////////////////////////////////////

    accountsButton: [
      '//a[contains(@href,"accounts") and contains(string(.), "Accounts")]'
    ],

    accountHistoryLink: [
      '//a[@title="history" and contains(@href, "id=")]'
    ],

    specificAccountHistoryLink: [
      '//a[@title="history" and contains(@href, ":href")]'
    ],


    /////////////////////////////////////////////////////////////////////////////
    // download page
    /////////////////////////////////////////////////////////////////////////////

    downloadDateFrom: [
      '//input[@name="start_date"]'
    ],

    downloadDateTo: [
      '//input[@name="end_date"]'
    ],

    downloadFormat: [
      '//select[@name="download_format"]'
    ],

    downloadFormatOFX: [
      './/option[@value="MON"]'
    ],

    downloadButton: [
      '//input[@name="acc_hist_submit" and @type="submit" and @value="Download"]'
    ],


    /////////////////////////////////////////////////////////////////////////////
    // confirm download page
    /////////////////////////////////////////////////////////////////////////////

    confirmDownloadForm: [
      '//form[contains(@action, "generate_history")]'
    ],

    confirmDownloadButton: [
      '//input[@name="acct_hist_submit"][@type="submit"]',
    ],

    // TODO: Handle Download Errors?
    confirmDownloadError: [
      '//div[contains(string(.), "Errors Were Encountered")]'
    ],

    confirmDownloadErrorReason: [
      '//table//div//blockquote//text()',
      '//input[@type="submit" and name="Delete"]'
    ],


    /////////////////////////////////////////////////////////////////////////////
    // global stuff
    /////////////////////////////////////////////////////////////////////////////

    unreadMessages: [
      '//td[contains(string(.),"Unread Messages")]'
    ],

    logoutButton: [
      '//a[@target="_top" and (contains(@href, "exit?iid") or contains(string(.), "Log Off"))]',
      '//a[contains(string(.), "Log Off")]'
    ],

    errorWrongUsernameOrPassword: [
      '//*[contains(string(.), "LOG IN ERROR")]'
    ],

    errorSiteInMaintanceMode: [
      '//*[contains(string(.), "MAINTANCE")]'
    ]
  }
});
