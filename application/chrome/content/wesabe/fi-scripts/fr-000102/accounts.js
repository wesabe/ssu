// This is the login part of the Banque BNP Paribas (France)
// script, included by fr-000102.js one level up.
//
// This part handles logging in, and contains all the
// logic and page element references related to it.
//
wesabe.provide("fi-scripts.fr-000102.accounts", {
  // The "dispatch" function is called every time a page
  // load occurs (using the ondomready callback, not onload).
  // For more information, see login.js in the same folder.
  dispatch: function() {
    // replace with your own custom logic for determining login status
    if (!page.present(e.logoff.link)) return;

    // TODO: fill out logic for finding and downloading accounts
  },

  actions: {
    // TODO: fill this out (see login.js for more info)
  },

  elements: {
    // TODO: fill this out (see login.js for more info)
  },
});
