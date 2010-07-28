wesabe.download.OFXPlayer.register({
  fid: 'us-003274', 
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
