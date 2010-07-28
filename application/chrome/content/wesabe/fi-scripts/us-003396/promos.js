wesabe.provide('fi-scripts.us-003396.promos', {
  dispatch: function() {
    if (page.present(e.promos.indicator)) {
      action.promosSkip();
    }
  },

  actions: {
    promosSkip: function() {
      page.click(e.promos.skipLink);
    },
  },

  elements: {
    promos: {
      indicator: [
        '//form[contains(@action, "Interstitial")]',
      ],

      skipLink: [
        '//a[contains(@href, "ViewAd")][contains(@href, "MyAccounts")]',
        '//input[@type="button" or @type="submit" or @type="image"][contains(@value, "My Accounts")]',
      ],
    },
  },
});
