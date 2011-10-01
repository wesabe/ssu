// This file is the main file for the Paypal - Money Market Funds script.
// Scripts for downloading data from financial institutions
// are called "players".
wesabe.download.Player.register({
  fid: 'com.paypal',
  org: 'Paypal - Money Market Funds',

  // change to true if frames have meaningful content,
  // and that "dispatch" should be run for the document
  dispatchFrames: false,
  afterDownload: 'logoff',

  actions: {
    // The "main" action is the entry point into the script,
    // and is the first thing that is run. It should trigger
    // a page load, which calls "dispatch" (see login.js).
    main: function() {
      browser.go("https://www.paypal.com/us/");
    },
  },

  // the "includes" array allows you to build this Player from
  // multiple files, splitting it up by functionally discrete parts
  //
  // the two that nearly all Players will have is how to log in,
  // and how to navigate and download accounts. samples of each
  // are provided in login.js and accounts.js alongside this file
  includes: [
    'fi-scripts.com.paypal.login',
    'fi-scripts.com.paypal.accounts',
  ],
});
