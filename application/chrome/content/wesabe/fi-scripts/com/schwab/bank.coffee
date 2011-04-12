wesabe.provide 'fi-scripts.com.schwab.bank',
  class bank extends wesabe.download.OFXPlayer
    fid: 'com.schwab.bank'
    org: 'Charles Schwab Bank, N.A.'

    fi:
      ofxFid: '101'
      ofxOrg: 'ISC'
      ofxUrl: 'https://ofx.schwab.com/bankcgi_dev/ofx_server'

    this::__defineGetter__ 'creds', ->
      @_creds

    this::__defineSetter__ 'creds', (creds) ->
      # as reported by Charles Schwab customer support
      # search for "schwab password 8 characters quicken"
      wesabe.info("Truncating password to 8 characters")
      creds.password = creds.password.substring(0, 8)
      @_creds = creds
