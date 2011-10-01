wesabe.download.Player.register({
  fid: 'com.first-direct',
  org: 'First Direct (UK)',

  dispatchFrames: false,
  afterDownload: 'nextAccount',

  dispatch: function() {
    if (page.present(e.error.unavailable)) {
      job.fail(503, 'fi.unavailable');
    }
  },

  actions: {
    main: function() {
      browser.go("https://www1.banking.first-direct.com/1/2/!ut/p/kcxml/");
    },
  },

  includes: [
    'fi-scripts.com.first-direct.login',
    'fi-scripts.com.first-direct.accounts',
  ],

  elements: {
    error: {
      unavailable: [
        '//text()[contains(., "Sorry we cannot action your request at the moment")]',
      ],
    },
  },
});
