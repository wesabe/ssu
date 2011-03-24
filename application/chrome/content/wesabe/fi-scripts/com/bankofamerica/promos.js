wesabe.provide('fi-scripts.com.bankofamerica.promos', {
  dispatch: function() {
    // if we're logged in, we're not in promo-land
    if (page.present(e.logoutButton)) return;

    if (page.present(e.promos.continueButton)) {
      page.click(e.promos.continueButton);
    }
  },

  elements: {
    promos: {
      continueButton: [
        '//a[@id="continue" and preceding::h1[contains(string(.), "Welcome to Online Banking")]]',
        '//a[@id="continue" and contains(string(.), "Continue")]',
      ],
    },
  },
});
