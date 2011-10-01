wesabe.download.Player.register({
  fid: 'com.vancity',
  org: 'Vancity',

  // change to true if frames have meaningful content,
  // and that "dispatch" should be run for the document
  dispatchFrames: false,

  afterDownload: 'logoff',

  actions: {
    // The "main" action is the entry point into the script,
    // and is the first thing that is run. It should trigger
    // a page load, which calls "dispatch" (see login.js).
    main: function() {
      browser.go("https://www.vancity.com/MyMoney/");
    },
  },

  includes: [
    'fi-scripts.com.vancity.login',
    'fi-scripts.com.vancity.accounts',
  ],
});
