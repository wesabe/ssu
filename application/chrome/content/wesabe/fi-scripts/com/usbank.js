wesabe.download.Player.register({
  fid: 'com.usbank',
  org: 'US Bank',

  afterDownload: 'nextAccount',

  actions: {
    main: function() {
      // https://www4.usbank.com/internetBanking/RequestRouter?requestCmdId=DisplayLoginPage
      browser.go("http://www.usbank.com/");
    },
  },

  includes: [
    'fi-scripts.com.usbank.security',
    'fi-scripts.com.usbank.login',
    'fi-scripts.com.usbank.accounts',
  ],
});
