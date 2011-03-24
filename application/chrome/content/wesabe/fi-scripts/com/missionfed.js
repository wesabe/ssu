wesabe.download.OFXPlayer.register({
  fid: 'com.missionfed',
  org: 'Mission FCU',

  set creds(creds) {
    creds.username = creds.username.replace(/^0+/, '')
    this.__creds__ = creds;
  },

  get creds() {
    return this.__creds__;
  },
});
