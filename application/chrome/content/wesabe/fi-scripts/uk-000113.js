wesabe.download.Player.register({
  fid: 'uk-000113',
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
      wesabe.dom.browser.go(browser, "https://www1.banking.first-direct.com/1/2/!ut/p/kcxml/");
    },
  },

  includes: [
    'fi-scripts.uk-000113.login',
    'fi-scripts.uk-000113.accounts',
  ],

  elements: {
    error: {
      unavailable: [
        '//text()[contains(., "Sorry we cannot action your request at the moment")]',
      ],
    },
  },
});
