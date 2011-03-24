wesabe.download.OFXPlayer.register({
  fid: 'com.psecu',
  org: 'PSECU',

  get creds() {
    return this.__creds__;
  },

  set creds(creds) {
    // the actual password is PIN + Password
    if (creds.pin) {
      creds.password = creds.pin + creds.password;
    }

    return this.__creds__ = creds
  }
});
