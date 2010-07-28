// This file is the main file for the Paypal - Money Market Funds script.
// Scripts for downloading data from financial institutions
// are called "players".
wesabe.download.Player.register({
  fid: 'us-001659',
  org: 'Paypal - Money Market Funds',

  // change to true if frames have meaningful content,
  // and that "dispatch" should be run for the document
  dispatchFrames: false,
  afterUpload: 'logoff',
  // tells the player to remove the current account (tmp.account)
  // when an upload completes. this is useful when only one account
  // may be downloaded as a time
  //
  // tells Player to run the "nextAccount" action after an upload
  //afterUpload: 'nextAccount',

  actions: {
    // The "main" action is the entry point into the script,
    // and is the first thing that is run. It should trigger
    // a page load, which calls "dispatch" (see login.js).
    main: function() {
      wesabe.dom.browser.go(browser, "https://www.paypal.com/us/");
    },
  },

  // the "includes" array allows you to build this Player from
  // multiple files, splitting it up by functionally discrete parts
  //
  // the two that nearly all Players will have is how to log in,
  // and how to navigate and download accounts. samples of each
  // are provided in login.js and accounts.js alongside this file
  includes: [
    'fi-scripts.us-001659.login',
    'fi-scripts.us-001659.accounts',
  ],
});
