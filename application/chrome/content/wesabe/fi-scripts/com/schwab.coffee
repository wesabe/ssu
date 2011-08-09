wesabe.download.Player.register
  fid: 'com.schwab'
  org: 'Charles Schwab'

  dispatchFrames: false
  afterDownload: 'getNextPDFStatement'
  afterLastGoal: 'logoff'

  includes: [
    'fi-scripts.com.schwab.login'
    'fi-scripts.com.schwab.accounts'
    'fi-scripts.com.schwab.pdfstatements'
  ]

  actions:
    main: ->
      wesabe.dom.browser.go browser, 'https://client.schwab.com/login/signon/customercenterlogin.aspx'


  # wesabe.util.privacy.registerSanitizer('Wells Fargo Session ID', /sessargs=[^=&\?]*/g);
