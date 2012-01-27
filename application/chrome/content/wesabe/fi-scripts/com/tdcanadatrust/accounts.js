// This is the login part of the TD Canada Trust
// script, included by com.tdcanadatrust.js one level up.
//
// This part handles logging in, and contains all the
// logic and page element references related to it.
//
wesabe.provide("fi-scripts.com.tdcanadatrust.accounts", {
  // The "dispatch" function is called every time a page
  // load occurs (using the ondomready callback, not onload).
  // For more information, see login.js in the same folder.
  dispatch: function() {
    // only dispatch when the logoff link is shown
    if (!page.present(e.logoff.link)) return;

    if (page.present(e.accounts.download.indicator)) {
      action.download();
      return false;
    } else if (page.present(e.accounts.exportSetup.indicator)) {
      action.setupExportTypes();
      return false;
    }
  },

  actions: {
    download: function() {
      job.update('account.download');

      // make sure all the download checkboxes are checked
      page.select(e.accounts.download.checkbox).forEach(function(checkbox) {
        page.check(checkbox);
      });

      page.fill(e.accounts.download.format.select, e.accounts.download.format.ofx);
      page.click(e.accounts.download.continueButton);
    },

    setupExportTypes: function() {
      var selects = page.select(e.accounts.exportSetup.select);
      var questions = [];

      for (var i = 0; i < selects.length; i++) {
        var select = wesabe.untaint(selects[i]);
        if (select.value == "-1") {
          if (answers['AccountType'+i]) {
            page.select(select, answers['AccountType'+i]);
          } else {
            var account = wesabe.untaint(page.findStrict(e.accounts.exportSetup.accountName, select)).nodeValue;
            var options = select.options.map(function(option) {
              options.push({label: option.innerHTML, key: option.value, value: option.value});
            });
            questions.push({
              type: "choice",
             label: "What type of account is "+account+"?",
               key: 'AccountType'+i,
        persistent: true,
           choices: options,
            });
          }
        }
      }

      if (questions.length) {
        job.suspend("suspended.missing-answer.accounts.type-mapping", {
              title: "Setup Download to Wesabe",
             header: "Please let us know what types of account these are (e.g. Savings, Chequing, Credit Card, etc).",
          questions: questions,
        });
      } else {
        page.click(e.accounts.exportSetup.continueButton);
      }
    },
  },

  elements: {
    accounts: {
      download: {
        indicator: [ // use the "Download" button as the indicator
          '//a[contains(@onclick, "fnExport(\'D\')")]',
          '//a[@onclick][.//img[@alt="Download"]]',
        ],

        checkbox: [
          '//input[@type="checkbox"][@name="A0"]',
        ],

        format: {
          select: [
            '//select[@name="exportType"]',
          ],

          ofx: [
            './/option[@value="ofx"]',
          ],
        },

        continueButton: [
          '//a[contains(@onclick, "fnExport(\'D\')")]',
          '//a[@onclick][.//img[@alt="Download"]]',
        ],
      },

      exportSetup: {
        indicator: [
          '//text()[contains(., "Please select account type for each account")]',
          '//form[@name="frmdownload"]',
        ],

        select: [
          '//form[@name="frmdownload"]//select[@name="QuickenType"]',
        ],

        accountName: [ // relative to 'select'
          '../../td[has-class("table")][1]/text()',
        ],

        showCheckbox: [
          '//form[@name="frmdownload"]//input[@type="checkbox"][@name="ShowExportSetup"]',
        ],

        continueButton: [
          '//a[contains(@onclick, "frmdownload.submit")]',
          '//a[img[contains(@alt, "OK")]]',
        ],
      },
    },
  },
});
