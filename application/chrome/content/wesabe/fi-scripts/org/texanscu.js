wesabe.download.Player.register({
  fid: 'org.texanscu',
  org: 'Texans Credit Union',

  dispatchFrames: false,
  afterDownload: 'nextAccount',

  includes: [
    'fi-scripts.org.texanscu.login',
    'fi-scripts.org.texanscu.accounts',
  ],
});
