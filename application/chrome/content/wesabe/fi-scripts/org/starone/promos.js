wesabe.provide('fi-scripts.org.starone.promos', {
  dispatch: function() {
    // if we're logged in, we're not in promo-land
    if (page.present(e.logoutButton)) return;

    if (page.present(e.promos.choices.no)) {
      page.check(e.promos.choices.no);
    }

    if (page.present(e.promos.continueButton)) {
      page.click(e.promos.continueButton);
    }
  },

  elements: {
    promos: {
      choices: {
        no: [
          '//form//input[@type="radio" and @name="sign_up" and @value="n"]',
        ],
      },

      continueButton: [
        '//form//input[@type="submit" and @value="Continue"]',
      ],
    },
  },
});
