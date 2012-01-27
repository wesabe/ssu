wesabe.provide("fi-scripts.com.citibank.accounts", {
  dispatch: function() {
    tmp.authenticated = page.visible(e.logoutButton);

    // only dispatch authenticated pages
    if (!tmp.authenticated) return;

    if (page.visible(e.noThanksButton)) {
      page.click(e.noThanksButton);
    } else if (page.visible(e.noActivityError)) {
      log.warn("No activity found. Skipping and logging out.");
      action.logout();
    } else if (page.visible(e.download.button)) {
      action.download();
    } else if (page.present(e.download.preparing)) {
      log.info("Download is still being prepared, waiting for more dispatches");
    } else if (page.present(e.download.finishing)) {
      log.info("Download has been triggered, waiting for it to finish");
    } else if (page.present(e.download.ready)) {
      action.confirmDownload();
    } else if (page.visible(e.downloadActivityLink)) {
      page.click(e.downloadActivityLink);
    } else if (page.visible(e.declineSessionSummary)) {
      page.click(e.declineSessionSummary);
    } else if (page.present(e.nav.dashboard)) {
      action.goDashboard();
    } else {
      action.logout();
    }
  },

  actions: {
    main: function() {
      browser.go("https://web.da-us.citibank.com/cgi-bin/citifi/scripts/login2/login.jsp");
    },

    goDashboard: function() {
      page.click(e.nav.dashboard);
    },

    download: function() {
      job.update('account.download');

      action.fillDateRange();
      page.check(e.download.allAccountsRadio);
      page.check(e.download.dateRangeRadio);
      page.fill(e.download.format, e.download.moneyFormat);
      page.click(e.download.button);
    },

    confirmDownload: function() {
      page.click(e.download.continueButton);
    },
  },

  elements: {
    nav: {
      dashboard: [
        '//a[contains(string(.), "My Home")]',
      ],
    },

    downloadActivityLink: [
      '//a[@id="cmlink_JBA"][contains(text(), "Download")]',
    ],

    noActivityError: [
      '//td[has-class("apptxtlg")][contains(text(), "no activity")]'
    ],

    // download page

    download: {
      date: {
        format: 'MM-dd-yyyy',
        defaults: {
          to: function(){ return wesabe.lang.date.add(new Date(), -1 * wesabe.lang.date.DAYS) },
        },
        from: [
          '//input[@name="fromDate"]'
        ],
        to: [
          '//input[@name="toDate"]'
        ],
      },

      allAccountsRadio: [
        '//input[@value="All"][@name="forAccount"]'
      ],

      format: [
        '//select[@name="selectedDownloadFormat"]'
      ],

      moneyFormat: [
        '//select[@name="selectedDownloadFormat"]//option[contains(text(), "OFX")]',
        '//select[@name="selectedDownloadFormat"]//option[@value="4"]',
      ],

      button: [
        '//a[contains(text(), "Download File")][has-class("appNavNext")]'
      ],

      dateRangeRadio: [
        '//input[@name="saveActivityFor"][@value="DateDownload"]'
      ],

      preparing: [
        '//text()[contains(., "Just a moment") or contains(., "Not started")]'
      ],

      ready: [
        '//text()[contains(., "Your activity is ready to download")]'
      ],

      continueButton: [
        '//a[contains(string(.), "Continue download")]',
        '//a[contains(@href, "downloadAccountsInSingleFile")]',
      ],

      finishing: [
        '//text()[contains(., "download has been completed")]'
      ],
    },
  },
});
