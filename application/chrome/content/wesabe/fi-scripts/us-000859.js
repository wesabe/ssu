wesabe.download.Player.register({
  fid: 'us-000859',
  org: 'US Bank',

  afterDownload: 'nextAccount',

  actions: {
    main: function() {
      // https://www4.usbank.com/internetBanking/RequestRouter?requestCmdId=DisplayLoginPage
      wesabe.dom.browser.go(browser, "http://www.usbank.com/");
    },
  },

  includes: [
    'fi-scripts.us-000859.security',
    'fi-scripts.us-000859.login',
    'fi-scripts.us-000859.accounts',
  ],
});
