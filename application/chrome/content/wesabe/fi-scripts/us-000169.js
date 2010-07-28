wesabe.download.Player.register({
  fid: 'us-000169',
  org: 'Texans Credit Union',

  dispatchFrames: false,
  afterUpload: 'nextAccount',

  includes: [
    'fi-scripts.us-000169.login',
    'fi-scripts.us-000169.accounts',
  ],
});
