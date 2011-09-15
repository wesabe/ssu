// This file is the main file for the Banque BNP Paribas (France) script.
// Scripts for downloading data from financial institutions
// are called "players".
wesabe.download.Player.register({
  fid: 'net.bnpparibas',
  org: 'Banque BNP Paribas (France)',

  // change to true if frames have meaningful content,
  // and that "dispatch" should be run for the document
  dispatchFrames: false,

  // tells the player to remove the current account (tmp.account)
  // when a download completes. this is useful when only one account
  // may be downloaded as a time
  //
  // tells Player to run the "nextAccount" action after a download
  afterDownload: 'nextAccount',

  actions: {
    main: function() {
      browser.go("https://www.secure.bnpparibas.net/banque/portail/particulier/HomeConnexion?type=homeconnex");
    },
  },

  // the "includes" array allows you to build this Player from
  // multiple files, splitting it up by functionally discrete parts
  //
  // the two that nearly all Players will have is how to log in,
  // and how to navigate and download accounts. samples of each
  // are provided in login.js and accounts.js alongside this file
  includes: [
    'fi-scripts.net.bnpparibas.login',
    'fi-scripts.net.bnpparibas.accounts',
  ],
});
