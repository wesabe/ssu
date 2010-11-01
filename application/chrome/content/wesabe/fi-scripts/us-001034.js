wesabe.download.Player.register({
  fid: 'us-001034',
  org: 'Citibank',

  dispatchFrames: false,
  afterDownload: 'logout',

  includes: [
    'fi-scripts.us-001034.terms',
    'fi-scripts.us-001034.mfa',
    'fi-scripts.us-001034.login',
    'fi-scripts.us-001034.accounts',
  ],
});
