wesabe.download.Player.register({
  fid: 'us-000238',
  org: 'Bank of America',

  dispatchFrames: false,
  afterUpload: 'nextAccount',

  includes: [
    'fi-scripts.us-000238.global',
    'fi-scripts.us-000238.mobile',
    'fi-scripts.us-000238.promos',
    'fi-scripts.us-000238.loans',
    'fi-scripts.us-000238.investing',
    'fi-scripts.us-000238.login',
    'fi-scripts.us-000238.accounts',
    'fi-scripts.us-000238.northwest',
    'fi-scripts.us-000238.passwordStrengthNotice',
  ],
});
