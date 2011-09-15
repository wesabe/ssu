wesabe.provide("fi-scripts.com.first-direct.accounts", {
  dispatch: function() {
    if (page.present(e.accounts.page.index.indicator)) {
      if (!tmp.accounts) {
        action.collectAccounts();
      }

      if (!tmp.accounts.length) {
        return action.logoff();
      }

      if (!tmp.account) {
        tmp.account = tmp.accounts.shift();
      }

      return action.selectAccount();
    }

    if (page.present(e.accounts.page.txactions.indicator)) {
      return action.goToDownloadPage();
    }

    if (page.present(e.accounts.page.download.indicator)) {
      if (tmp.account) {
        return action.download();
      } else {
        return action.goToMyAccounts();
      }
    }
  },

  actions: {
    collectAccounts: function() {
      var accountLinks = page.select(e.accounts.page.index.accountLink),
          accounts = [];

      wesabe.untaint(accountLinks).forEach(function(link) {
        var m = link.href.match(/fdIBSelectedAccount=(\d+)/);
        if (m) {
          var id = m[1], name = link.innerHTML, account = {name: wesabe.taint(name), id: wesabe.taint(id)};
          if (!accounts[id]) {
            accounts[id] = account;
            accounts.push(account);
          }
        }
      });

      tmp.accounts = accounts;
      wesabe.info('accounts=', tmp.accounts);
    },

    goToMyAccounts: function() {
      page.click(e.accounts.nav.myAccountsLink);
    },

    selectAccount: function() {
      log.info('account=', tmp.account);
      page.click(bind(e.accounts.page.index.accountLinkById, {id: tmp.account.id}));
    },

    goToDownloadPage: function() {
      page.click(e.accounts.page.txactions.downloadLink);
    },

    download: function() {
      page.fill(e.accounts.page.download.format.select, e.accounts.page.download.format.money);
      page.click(e.accounts.page.download.continueButton);
    },
  },

  elements: {
    accounts: {
      page: {
        index: {
          indicator: [
            '//h1[contains(string(.), "my accounts")]',
          ],

          accountLink: [
            '//table[@summary="balances information for account held"]//a[contains(@href, "fdIBSelectedAccount")]',
            '//a[contains(@href, "fdIBSelectedAccount")][@title="view statement"]',
          ],

          accountLinkById: [
            '//a[contains(@href, "fdIBSelectedAccount=:id")]',
          ],
        },

        txactions: {
          indicator: [
            '//h1[contains(string(.), "statement")]',
          ],

          downloadLink: [
            '//a[contains(string(.), "download")]',
          ],
        },

        download: {
          indicator: [
            '//select[@name="DownloadFormat"]',
          ],

          format: {
            select: [
              '//select[@name="DownloadFormat"]',
            ],

            money: [
              './/option[@value="Microsoft Money"]',
              './/option[contains(string(.), "Microsoft Money")]',
            ],
          },

          date: {
            from: [
              '//input[@type="text"][@name="DownloadFromDate"]',
            ],

            to: [
              '//input[@type="text"][@name="DownloadToDate"]',
            ],
          },

          continueButton: [
            '//a[contains(string(.), "download")]',
            '//a[@name="download"]',
          ],
        },
      },

      nav: {
        myAccountsLink: [
          '//*[@id="fdLeftMenu"]//a[contains(string(.), "my accounts")]',
          '//a[contains(string(.), "my accounts")][@id="link0"]',
          '//a[contains(string(.), "my accounts")]',
        ],
      },
    },
  },
});
