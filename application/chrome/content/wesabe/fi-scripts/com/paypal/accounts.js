wesabe.provide("fi-scripts.com.paypal.accounts", {
  // The "dispatch" function is called every time a page
  // load occurs (using the ondomready callback, not onload).
  // For more information, see login.js in the same folder.
  dispatch: function() {
    // replace with your own custom logic for determining login status
    if (!page.present(e.logoff.link)) return;

    if (page.visible(e.download.button)) {
      action.download();
    } else {
      action.logoff();
    }
  },

  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, "https://history.paypal.com/us/cgi-bin/webscr?cmd=_history-download");
    },

    download: function() {
      job.update('account.download');
      // BEGIN custom date filling code
      var fromMonthEl = wesabe.untaint(page.find(e.download.date.fromMonth));
      var toMonthEl   = wesabe.untaint(page.find(e.download.date.toMonth));
      var fromDayEl = wesabe.untaint(page.find(e.download.date.fromDay));
      var toDayEl   = wesabe.untaint(page.find(e.download.date.toDay));
      var fromYearEl = wesabe.untaint(page.find(e.download.date.fromYear));
      var toYearEl   = wesabe.untaint(page.find(e.download.date.toYear));

      var from;
      var to = wesabe.lang.date.add(new Date(), -1 * wesabe.lang.date.DAYS);
      page.fill(toMonthEl, to.getMonth()+1);
      page.fill(toDayEl, to.getDate());
      page.fill(toYearEl, to.getYear()+1900);

      // if there's a lower bound, choose a week before it to ensure some overlap
      var since = options.since && (options.since - 7 * wesabe.lang.date.DAYS);
      if (since) {
        // choose the lower bound
        from = new Date(since);
      } else {
        // pick an 89 day window from today
        from = wesabe.lang.date.add(new Date(), -89 * wesabe.lang.date.DAYS);
      }
      page.fill(fromMonthEl, from.getMonth()+1);
      page.fill(fromDayEl, from.getDate());
      page.fill(fromYearEl, from.getYear()+1900);
      // END custom date filling code

      log.info("Adjusting date upper bound: ", wesabe.lang.date.format(to, 'MM-dd-yyyy'));
      log.info("Adjusting date lower bound: ", wesabe.lang.date.format(from, 'MM-dd-yyyy'));

      page.check(e.download.customDateRangeRadio);
      page.fill(e.download.format, e.download.quickenFormat);
      page.click(e.download.button);
    },
  },

  elements: {
    download: {
      date: {
        fromMonth: [
          '//input[@name="from_a"]'
        ],
        toMonth: [
          '//input[@name="to_a"]'
        ],
        fromDay: [
          '//input[@name="from_b"]'
        ],
        toDay: [
          '//input[@name="to_b"]'
        ],
        fromYear: [
          '//input[@name="from_c"]'
        ],
        toYear: [
          '//input[@name="to_c"]'
        ],
      },

      customDateRangeRadio: [
        '//input[@value="custom_date_range"][@name="type"]'
      ],

      format: [
        '//select[@name="custom_file_type"]'
      ],

      quickenFormat: [
        '//select[@name="custom_file_type"]//option[@value="quicken"]',
      ],

      button: [
        '//form[@name="form1"]//input[@type="submit"][@name="submit.x"]'
      ],
    }
  },
});
