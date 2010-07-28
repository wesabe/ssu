wesabe.download.Player.register({
  fid: 'uk-000100',
  org: 'HSBC Bank (UK)',

  dispatchFrames: false,
  afterUpload: 'nextAccount',

  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, "http://www.hsbc.co.uk/1/2/HSBCINTEGRATION");
    },
  },

  includes: [
    'fi-scripts.uk-000100.login',
    'fi-scripts.uk-000100.accounts',
  ],
});
