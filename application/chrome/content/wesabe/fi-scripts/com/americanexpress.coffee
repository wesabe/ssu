(require "download/CompoundPlayer").register
  fid: "com.americanexpress"
  org: "American Express Cards"

  players: [
    (require "download/Player").create(
      fid: "com.americanexpress.web"
      org: "American Express Cards"
      dispatchFrames: false
      afterDownload: "logout"
      includes: [
        "fi-scripts.com.americanexpress.login"
        "fi-scripts.com.americanexpress.accounts"
      ]
      dispatch: ->
        if page.present e.errors.systemNotResponding
          tmp.systemNotRespondingTTL ||= 4
          tmp.systemNotRespondingTTL--
          unless tmp.systemNotRespondingTTL
            job.fail 503, "fi.unavailable"
          else
            log.warn "Amex system is not responding (retrying, TTL=", tmp.systemNotRespondingTTL, ")"
            setTimeout (-> action.main()), 15000
          false

      actions:
        main: ->
          browser.go "https://www.americanexpress.com/"

      elements:
        errors:
          systemNotResponding: [
            '//text()[contains(., "Our System is Not Responding")]'
          ]
    )

    (require "download/OFXPlayer").create(
      fid: "com.americanexpress"
      org: "American Express Cards"
      fi:
        ofxUrl: "https://online.americanexpress.com/myca/ofxdl/desktop/desktopDownload.do?request_type=nl_ofxdownload"
        ofxOrg: "AMEX"
        ofxFid: "3101"

      appId: "QWIN"
      appVersion: "1500"
    )
  ]
