wesabe.download.CompoundPlayer.register
  fid: 'com.ingdirect'
  org: 'ING Direct'

  players: [
    wesabe.download.OFXPlayer.create
      fid: 'com.ingdirect'
      org: 'ING Direct'

      fi:
        ofxFid: '031176110'
        ofxOrg: 'ING DIRECT'
        ofxUrl: 'https://ofx.ingdirect.com/OFX/ofx.html'

    wesabe.download.Player.create
      fid: 'com.ingdirect'
      org: 'ING Direct'

      dispatchFrames: false
      afterDownload: 'nextGoal'
      afterLastGoal: 'logoff'

      includes: [
        'fi-scripts.com.ingdirect.login'
        'fi-scripts.com.ingdirect.accounts'
        'fi-scripts.com.ingdirect.transfers'
        'fi-scripts.com.ingdirect.links'
      ]
  ]
