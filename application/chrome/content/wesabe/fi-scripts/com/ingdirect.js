wesabe.download.Player.register({
  fid: 'com.ingdirect',
  org: 'ING Direct',

  dispatchFrames: false,
  afterDownload: 'logoff',

  includes: [
    'fi-scripts.com.ingdirect.login',
    'fi-scripts.com.ingdirect.accounts',
  ],
});
