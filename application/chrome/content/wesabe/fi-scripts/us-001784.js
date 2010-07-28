wesabe.download.OFXPlayer.register({
  fid: 'us-001784',
  org: 'Mission FCU',

  set creds(creds) {
    creds.username = creds.username.replace(/^0+/, '')
    this.__creds__ = creds;
  },

  get creds() {
    return this.__creds__;
  },
});
