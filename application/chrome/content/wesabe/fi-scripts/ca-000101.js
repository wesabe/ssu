wesabe.download.Player.register({
  fid: 'ca-000101',
  org: 'Vancity',

  // change to true if frames have meaningful content,
  // and that "dispatch" should be run for the document
  dispatchFrames: false,

  // tells the player to remove the current account (tmp.account)
  // when an upload completes. this is useful when only one account
  // may be downloaded as a time
  //
  // tells Player to run the "logoff" action after an upload
  afterUpload: 'logoff',

  actions: {
    // The "main" action is the entry point into the script,
    // and is the first thing that is run. It should trigger
    // a page load, which calls "dispatch" (see login.js).
    main: function() {
      wesabe.dom.browser.go(browser, "https://www.vancity.com/MyMoney/");
    },
  },

  includes: [
    'fi-scripts.ca-000101.login',
    'fi-scripts.ca-000101.accounts',
  ],
});
