// This is the login part of the Paypal - Money Market Funds
// script, included by com.paypal.js one level up.
//
// This part handles logging in, and contains all the
// logic and page element references related to it.
//
wesabe.provide("fi-scripts.com.paypal.login", {
  // The "dispatch" function is called every time a page
  // load occurs (using the ondomready callback, not onload).
  //
  // It gives you an opportunity to look at the page, figure
  // out where you are, and take one or more actions.
  //
  // The function is called with several implicit arguments,
  // which means that they are not in the argument list, but
  // are nonetheless available. Here they are:
  //
  // @param [wesabe.dom.page(DOMDocument)] page
  //   A DOMDocument wrapped with methods from wesabe.dom.page.
  //   This is the primary way you'll be interacting with the page.
  //
  // @param [XULBrowser] browser
  //   A <browser /> element that handles the loading of pages.
  //   You shouldn't need to interact with this much.
  //
  // @param [wesabe.download.Job] job
  //   Represents one sync job (SsuJob in PFC, Job in SSU Service),
  //   and has a status (numeric HTTP-like code) and a result (string
  //   value that elaborates on the status).
  //
  //   It is used to convey changes in state (e.g.
  //   job.update('auth.creds') to mean "I'm filling in the user's
  //   credentials), as well as success and failure (i.e.
  //   job.succeed() and job.fail(...), examples below).
  //
  // @param [wesabe.util.Proxy] action
  //   Calling "action.foo()" will run the "foo" action with all the
  //   right implicit arguments. Any arguments you pass will be ignored,
  //   so if you want to pass state around at all, use +tmp+.
  //
  // @param [Object] tmp
  //   An object that is the same throughout the job, and may be used
  //   to store and share state in +dispatch+ and any of the actions.
  //
  //  Often, this is used to store the list of accounts (tmp.accounts)
  //  and the current account (tmp.account).
  //
  // @param [Object] answers
  //   Contains the user's credentials, such as username and password.
  //   Also contains the answers to security questions.
  //
  // @param [Object] e
  //   The result of merging all the "elements" from the main Player
  //   and all sub-players together (e.g. e.login.user.field).
  //
  dispatch: function() {
    // replace with your own custom logic for determining login status
    if (page.present(e.logoff.link)) return;

    // replace with your own custom logic for how to log in
    //   NOTE: the order of the below is important
    //
    //   If you were to look for the username text field first
    //   then you would miss a possible error message on most
    //   websites, which show both an error message and the same
    //   form for the user to fill out again.
    //
    //   Because of this fact your dispatch will often start to look
    //   like it's doing things backwards, looking for the cases that
    //   come later, like errors logging in, before the cases that
    //   chronologically precede them, like doing the actual login.
    //
    if (page.present(e.login.error.user)) {
      job.fail(401, 'auth.user.invalid');
    } else if (page.present(e.login.error.creds)) {
      job.fail(401, 'auth.creds.invalid');
    } else if (page.present(e.login.error.general)) {
      job.fail(401, 'auth.unknown');
    } else if (page.present(e.login.error.noAccess)) {
      job.fail(403, 'auth.noaccess');
    } else if (page.present(e.login.user.field)) {
      action.login();
    }
  },

  // Actions are discrete steps that can be taken,
  // and often leave the current page, triggering
  // another call to dispatch.
  //
  // An example might be "login", as shown below,
  // which fills out the login form and submits it.
  //
  actions: {
    // sample -- replace this with your own custom logic
    login: function() {
      page.fill(e.login.user.field, answers.username);
      page.fill(e.login.pass.field, answers.password);
      // causes the form to be submitted, triggering another page
      // load, which then calls dispatch again -- hopefully as a
      // logged-in user this time
      page.click(e.login.continueButton);
    },

    // sample -- replace this with your own custom logic
    logoff: function() {
      page.click(e.logoff.link);
      // tells PFC that the job succeeded, and stops XulRunner (after a timeout)
      job.succeed();
    }
  },

  // elements are xpaths or sets of xpaths that
  // illustrate how to access a particular element
  // on a page
  //
  // used by the page.* methods, available as "e"
  // in dispatch and actions
  elements: {
    login: {
      user: {
        field: [
          '//form[@name="login_form"]//input[@type="text"][@name="login_email"]'
        ]
      },

      pass: {
        field: [
          '//form[@name="login_form"]//input[@type="password"][@name="login_password"]'
        ]
      },

      continueButton: [
        '//form[@name="login_form"]//input[@type="submit"][@name="submit.x"]'
      ],

      // possible error messages that you'll encounter logging in
      // it's likely that the bank will either show "invalid user"
      // and "invalid password" OR "invalid username and/or password",
      // but not both, so you'll probably need to trim some of this
      error: {
        user: [
          '//div[has-class("error")]/text()[contains(.,"enter a valid email address")]'
        ],

        creds: [
          // for example
          '//div[has-class("error")]/text()[contains(.,"Please make sure")]',
          '//text()[contains(., "your last action could not be completed")]'
        ],

        general: [
          // for example
          '//text()[contains(., "Could not log you in")]'
        ],

        noAccess: [
          // for example
          '//text()[contains(., "Your account has been locked")]'
        ]
      }
    },

    logoff: {
      link: [
        '//a[contains(string(.), "Log Out")]'
      ]
    }
  }
});
