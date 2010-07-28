// This file is the main file for the TD Canada Trust script.
// Scripts for downloading data from financial institutions
// are called "players".
wesabe.download.Player.register({
  fid: 'us-003429',
  org: 'TD Canada Trust',

  // TD Canada Trust uses frames
  dispatchFrames: true,
  afterUpload: 'logoff',

  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, "https://easyweb.tdcanadatrust.com/");
    },
  },

  // the "includes" array allows you to build this Player from
  // multiple files, splitting it up by functionally discrete parts
  includes: [
    'fi-scripts.us-003429.promos',
    'fi-scripts.us-003429.login',
    'fi-scripts.us-003429.accounts',
  ],
});
