wesabe.download.Player.register({
  fid: 'com.ingdirect',
  org: 'ING Direct',

  dispatchFrames: false,
  afterDownload: 'nextGoal',
  afterLastGoal: 'logoff',

  includes: [
    'fi-scripts.com.ingdirect.login',
    'fi-scripts.com.ingdirect.accounts',
    'fi-scripts.com.ingdirect.transfers',
    'fi-scripts.com.ingdirect.links',
  ],
});
