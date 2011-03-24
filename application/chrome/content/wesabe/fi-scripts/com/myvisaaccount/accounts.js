wesabe.provide("fi-scripts.com.myvisaaccount.accounts", {
  dispatch: function() {
    if (!page.present(e.logoff.link)) return;

    if (!page.present(e.accounts.nav.transactions.selected)) {
      return action.goToTransactionsPage();
    }

    if (!page.present(e.download.format)) {
      return action.logoff();
    }

    action.downloadAccount();
  },

  actions: {
    goToTransactionsPage: function() {
      page.click(e.accounts.nav.transactions.tab);
    },

    downloadAccount: function() {
      page.fill(e.download.format, 'ofx');
      page.click(e.download.continueButton);
    },
  },

  elements: {
    accounts: {
      nav: {
        transactions: {
          tab: [
            '//a[contains(@href, "TransHistory.do")]',
          ],

          selected: [
            '//a[contains(@href, "TransHistory.do")][contains(@class, "selected")]',
          ],
        },
      },
    },

    download: {
      format: [
        '//form[@name="downLoadTransactionForm"]//select[@name="downloadType"]',
      ],

      continueButton: [
        '//form[@name="downLoadTransactionForm"]//input[@type="submit"]',
      ],
    },
  },
});
