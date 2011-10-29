wesabe.provide('fi-scripts.com.bankofamerica.loans', {
  dispatch: function() {
    if (page.present(e.loans.account.indicator)) {
      log.info("We're on a loan page");
      if (tmp.account) {
        action.loanAccountSkip();
      } else {
        action.goAccountOverview();
      }
    }
  },

  actions: {
    loanAccountSkip: function() {
      skipAccount("Skipping loan account (account=", tmp.account, ")");
      reload();
    },
  },

  elements: {
    loans: {
      account: {
        indicator: [
          '//tr[contains(string(.), "Original loan amount")]',
        ],
      },
    },
  },
});

