// This file is the main file for the TD Canada Trust script.
// Scripts for downloading data from financial institutions
// are called "players".
wesabe.download.Player.register({
  fid: 'com.tdcanadatrust',
  org: 'TD Canada Trust',

  // TD Canada Trust uses frames
  dispatchFrames: true,
  afterDownload: 'logoff',

  actions: {
    main: function() {
      browser.go("https://easyweb.tdcanadatrust.com/");
    },
  },

  // the "includes" array allows you to build this Player from
  // multiple files, splitting it up by functionally discrete parts
  includes: [
    'fi-scripts.com.tdcanadatrust.promos',
    'fi-scripts.com.tdcanadatrust.login',
    'fi-scripts.com.tdcanadatrust.accounts',
  ],
});
