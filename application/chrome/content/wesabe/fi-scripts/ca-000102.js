// This file is the main file for the Vancity VISA script.
wesabe.download.Player.register({
  fid: 'ca-000102',
  org: 'Vancity VISA',

  // change to true if frames have meaningful content,
  // and that "dispatch" should be run for the document
  dispatchFrames: false,

  afterDownload: 'logoff',

  actions: {
    // The "main" action is the entry point into the script,
    // and is the first thing that is run. It should trigger
    // a page load, which calls "dispatch" (see login.js).
    main: function() {
      wesabe.dom.browser.go(browser, "https://www.myvisaaccount.com/Vancity_Consumer/Login.do");
    },
  },

  includes: [
    'fi-scripts.ca-000102.login',
    'fi-scripts.ca-000102.accounts',
  ],
});
