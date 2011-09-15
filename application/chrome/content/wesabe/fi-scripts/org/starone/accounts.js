wesabe.provide('fi-scripts.org.starone.accounts', {
  actions: {
    main: function() {
      browser.go("https://www.starone.org/");
    },

    login: function() {
      job.update('auth.creds');
      page.fill(e.loginUserId, answers.username);
      page.fill(e.loginPassword, answers.password);
      page.click(e.loginButton);
    },

    goAccountsPage: function() {
      var nav_page = page.topPage.framePages[1];
      nav_page.click(e.accountsButton);
    },

    goAccountHistoryPage: function() {
      page.click(bind(
        e.specificAccountHistoryLink, { 'href' : wesabe.untaint(tmp.accountId) }
      ));
    },

    collectAccountIds: function() {
      var normalAccounts = page.select(e.accountLinks).map(function(link) {
        return link.href;
      });

      var creditCards = page.select(e.creditCardLinks).map(function(link) {
        return link.href;
      });

      tmp.accountIds = normalAccounts.concat(creditCards);
    },

    download: function() {
      job.update('account.download');
      page.fill(e.downloadFormat, e.downloadFormatOFX);
      page.click(e.downloadButton);
    },

    logout: function() {
      job.succeed();
      var nav_page = page.topPage.framePages[1];
      nav_page.click(e.logoutButton);
    }
  },

  dispatch: function() {
    if (!page.framed) {
      // not a frame
      if (page.visible(e.security.questions)) {
        action.answerSecurityQuestions();
      } else if(page.visible(e.loginButton)){
        tmp.authenticated = false;
      } else if(page.visible(e.errorWrongUsernameOrPassword)){
        job.fail(401, 'auth.creds.invalid');
      } else {
        // if we're not a frame-element AND there was no login button to be
        // found then odds are good that this is the frameset defining page,
        // so simply return, some other dispatch call will do all the heavy
        // lifting
        return;
      }
    }
    else {
      // is a frame
      var nav_page = page.topPage.framePages[1];
      tmp.authenticated = nav_page.visible(e.logoutButton);
    }

    wesabe.debug('authenticated=', tmp.authenticated);

    // if not-authenticated
    if (!tmp.authenticated) {
      // and if our username/password is wrong
      if (page.visible(e.loginPassword)) {
        // otherwise try to login
        action.login();
      }
    } else {
      // we are authenticated
      if(page.visible(e.accountTable)){
        if(!tmp.accountIds){
          action.collectAccountIds();
          job.update('account.download');
        }
        tmp.accountId = tmp.accountIds.shift();
        action.goAccountHistoryPage();
      } else if (page.visible(e.moreHistoryForm)) {
        // account detail page
        if(page.visible(e.downloadButton)){
          if (tmp.accountId) {
            action.download();
            return;
          }
        }
        else if(page.visible(e.warningMessage)){
          wesabe.warn("No data for this period, skipping to next account");
          delete tmp.accountId;
        }
        else{
          wesabe.error("Undefined state: no download button or warning message");
          return;
        }

        // done, move on
        if (!tmp.accountIds.length) {
          action.logout();
        }
        else {
          action.goAccountsPage();
        }
      } else if(page.name == "body") {
        wesabe.info("Found body page we don't care about. Going to accounts page");
        action.goAccountsPage();
      }
    }
  }, // end dispatch:

  extensions: {
    onUploadSuccessful: function(browser, page) {
      delete this.tmp.accountId;
      // this.onDocumentLoaded(browser, page);
      wesabe.debug('upload successful, re-dispatching');
      this.onDocumentLoaded(
        wesabe.dom.Browser.wrap(browser),
        page.topPage.framePages[3]
      );
    },
  },


  elements: {
    /////////////////////////////////////////////////////////////////////////////
    // login page
    /////////////////////////////////////////////////////////////////////////////

    loginUserId: [
      '//form[@name="Login"]//input[@name="userNumber"]',
      '//input[@name="userNumber"]',
      '//form[@name="Login"]//input[@type="text"]'
    ],

    loginPassword: [
      '//form[@name="Login"]//input[@name="password"]',
    ],

    loginButton: [
      '//form[@name="Login"]//input[@name="OK"]',
    ],

    errorWrongUsernameOrPassword: [
      '//span[@class="mainTitle"][text()="Member Verification Error"]',
      '//span[@class="error-text"]',
    ],

    /////////////////////////////////////////////////////////////////////////////
    // Step 2: Security Questions
    /////////////////////////////////////////////////////////////////////////////
    security: {
      questions: [
        '//td[@id="question1"]/text()'
      ],
      answers: [
        '//input[@name="Answer1"]'
      ],
      setCookieCheckbox: [
        '//input[@name="mfa_enroll"]'
      ],
      continueButton: [
        '//input[@value="Continue"]'
      ]
    },

    /////////////////////////////////////////////////////////////////////////////
    // accounts page
    /////////////////////////////////////////////////////////////////////////////

    warningMessage: [
      '//span[@class="warning"]',
    ],

    moreHistoryForm: [
      '//form[@name="summary"]'
    ],

    accountTable: [
      '//table[@ditabletype="DepositSummary"]'
    ],

    accountLinks: [
      '//table[@ditabletype="DepositSummary"]//a[contains(@href, "Summary")]',
    ],

    creditCardLinks: [
      '//tr[./td/span[contains(text(), "Credit Card")]]//a[contains(@href, "Summary")]',
    ],

    specificAccountHistoryLink: [
      '//a[contains(":href", @href)]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // account history page
    /////////////////////////////////////////////////////////////////////////////

    downloadFormat: [
      '//form[@name="export"]/select[@name="typeList"]',
    ],

    downloadFormatOFX: [
      './/option[@value="OFX"]'
    ],

    downloadButton: [
      '//form[@name="export"][./select[@name="typeList"]]/input[@type="submit"]',
      '//select[@name="typeList"]/../input[@type="submit"]'
    ],

    /////////////////////////////////////////////////////////////////////////////
    // global stuff
    /////////////////////////////////////////////////////////////////////////////

    accountsButton: [
      '//a[@href="Summary.cgi"]'
    ],

    logoutButton: [
      '//a[@href="Goodbye.cgi"]'
    ],
  },
});

