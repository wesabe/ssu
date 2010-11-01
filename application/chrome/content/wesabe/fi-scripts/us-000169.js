wesabe.download.Player.register({
  fid: 'us-000169',
  org: 'Texans Credit Union',

  dispatchFrames: false,
  afterDownload: 'nextAccount',

  includes: [
    'fi-scripts.us-000169.login',
    'fi-scripts.us-000169.accounts',
  ],
});
