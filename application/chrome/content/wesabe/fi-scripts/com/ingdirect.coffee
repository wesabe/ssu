CompoundPlayer = require 'download/CompoundPlayer'
OFXPlayer      = require 'download/OFXPlayer'
Player         = require 'download/Player'

CompoundPlayer.register
  fid: 'com.ingdirect'
  org: 'ING Direct'

  players: [
    OFXPlayer.create
      fid: 'com.ingdirect'
      org: 'ING Direct'

      fi:
        ofxFid: '031176110'
        ofxOrg: 'ING DIRECT'
        ofxUrl: 'https://ofx.ingdirect.com/OFX/ofx.html'

    Player.create
      fid: 'com.ingdirect'
      org: 'ING Direct'

      dispatchFrames: off
      afterDownload: 'nextGoal'
      afterLastGoal: 'logoff'

      includes: [
        'fi-scripts.com.ingdirect.login'
        'fi-scripts.com.ingdirect.accounts'
        'fi-scripts.com.ingdirect.transfers'
        'fi-scripts.com.ingdirect.links'
      ]
  ]
