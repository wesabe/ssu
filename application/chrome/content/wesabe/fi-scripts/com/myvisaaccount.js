// This file is the main file for the Vancity VISA script.
wesabe.download.Player.register({
  fid: 'com.myvisaaccount',
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
      browser.go("https://www.myvisaaccount.com/Vancity_Consumer/Login.do");
    },
  },

  includes: [
    'fi-scripts.com.myvisaaccount.login',
    'fi-scripts.com.myvisaaccount.accounts',
  ],
});
