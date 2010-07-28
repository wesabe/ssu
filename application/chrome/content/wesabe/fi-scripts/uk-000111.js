wesabe.download.OFXPlayer.register({
  fid: 'uk-000111', 
  org: 'Nationwide (UK)', 
  
  get creds() {
    return this.__creds__;
  }, 
  
  set creds(creds) {
    // pad the username with leading zeros so that it's 10 digits
    if (creds.username) {
      while (creds.username.length < 10)
        creds.username = '0' + creds.username;
    }
    
    // the actual password is Memorable Data + Passnumber
    if (creds.memorable) {
      creds.password = creds.memorable + creds.password;
    }
    
    return this.__creds__ = creds
  }
});
