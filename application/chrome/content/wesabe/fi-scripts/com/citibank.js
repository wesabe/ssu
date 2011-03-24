wesabe.download.Player.register({
  fid: 'com.citibank',
  org: 'Citibank',

  dispatchFrames: false,
  afterDownload: 'logout',

  includes: [
    'fi-scripts.com.citibank.terms',
    'fi-scripts.com.citibank.mfa',
    'fi-scripts.com.citibank.login',
    'fi-scripts.com.citibank.accounts',
  ],
});
