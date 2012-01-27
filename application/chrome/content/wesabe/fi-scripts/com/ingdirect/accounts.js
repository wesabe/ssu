wesabe.provide('fi-scripts.com.ingdirect.accounts', {
  dispatch: function() {
    if (job.goal !== 'statements')
      return;

    tmp.authenticated = page.visible(e.signOffLink);
    if (!tmp.authenticated)
      return;

    if (page.visible(e.errors.noTransactionsForPeriod)) {
      logger.warn('No transactions available, skipping account');
      job.succeed();
      action.logoff();
    } else if (page.visible(e.downloadPeriod)) {
      action.downloadActivity();
    } else if (page.present(e.downloadLink)) {
      action.goDownloadPage();
    } else {
      action.goMyAccountsPage();
    }
  },

  actions: {
    goDownloadPage: function() {
      job.update('account.download');
      page.click(e.downloadLink);
    },

    goMyAccountsPage: function() {
      job.update('account');
      page.click(e.myAccountsNavLink);
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
        logger.warn("MainForm already has an id (", formid, ") -- doing nothing");
      } else {
        formid = form.getAttribute('name');
        logger.warn("Setting MainForm's id to ", formid);
        form.setAttribute('id', wesabe.untaint(formid));
      }
      // </hack>

      page.click(e.downloadButton);
    },
  },

  elements: {
    myAccountsNavLink: [
      '//a[@href="/myaccount/INGDirect.html?command=displayAccountSummary"]',
      '//div[@id="tabs"]//a[contains(string(.), "My Accounts")]',
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

    externalLinksLink: [
      '//a[@href="/myaccount/INGDirect/display_external_links.vm"]',
      '//a[contains(@href, "links")][contains(string(.), "My Links")]',
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

    errors: {
      general: [
        '//*[has-class("errormsg") or has-class("actionmsg")]',
      ],

      sessionExpired: [
        '//*[has-class("actionmsg")][contains(string(text()), "session")][contains(string(text()), "expired")]'
      ],

      // the user entered their pin directly into the field
      pinLettersNotNumbers: [
        '//*[has-class("errormsg")][contains(string(text()), "LETTERS")][contains(string(text()), "NUMBERS")]'
      ],

      noTransactionsForPeriod: [
        '//*[has-class("errormsg") and contains(string(.), "no transactions for the selected timeframe")]'
      ],
    },
  },
});
