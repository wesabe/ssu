wesabe.download.Player.register({
  fid: 'com.usbank',
  org: 'US Bank',

  afterDownload: 'nextAccount',

  actions: {
    main: function() {
      // https://www4.usbank.com/internetBanking/RequestRouter?requestCmdId=DisplayLoginPage
      wesabe.dom.browser.go(browser, "http://www.usbank.com/");
    },
  },

  includes: [
    'fi-scripts.com.usbank.security',
    'fi-scripts.com.usbank.login',
    'fi-scripts.com.usbank.accounts',
  ],
});
