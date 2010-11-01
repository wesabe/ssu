wesabe.download.OFXPlayer.register({
  fid: 'us-000641',
  org: 'Charles Schwab Bank, N.A.',

  fi: {
    ofxFid: '101',
    ofxOrg: 'ISC',
    ofxUrl: 'https://ofx.schwab.com/bankcgi_dev/ofx_server',
  },

  get creds() {
    return this.__creds__;
  },

  set creds(creds) {
    // as reported by Charles Schwab customer support
    // search for "schwab password 8 characters quicken"
    wesabe.info("Truncating password to 8 characters");
    creds.password = creds.password.substring(0, 8);
    this.__creds__ = creds;
  }
});
