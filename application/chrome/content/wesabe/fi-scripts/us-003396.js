wesabe.download.CompoundPlayer.register({
  fid: 'us-003396',
  org: 'Chase',

  players: [
    wesabe.download.OFXPlayer.create({
      fid: 'us-003396',
      org: 'Chase',

      fi: {
        ofxUrl: "https://ofx.chase.com",
        ofxOrg: "B1",
        ofxFid: "10898",
      },
    }),


    wesabe.download.Player.create({
      fid: 'us-003396',
      org: 'Chase',

      dispatchFrames: false,
      afterDownload: 'nextAccount',

      includes: [
        'fi-scripts.us-003396.promos',
        'fi-scripts.us-003396.login',
        'fi-scripts.us-003396.identification',
        'fi-scripts.us-003396.accounts',
        'fi-scripts.us-003396.errors',
      ],
    }),
  ],
});
