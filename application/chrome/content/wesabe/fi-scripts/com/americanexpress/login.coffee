wesabe.provide 'fi-scripts.com.americanexpress.login',
  dispatch: ->
    tmp.authenticated = page.visible e.logout.link

    unless tmp.authenticated
      if page.present e.login.error.general
        job.fail 401, 'auth.creds.invalid'
      else if page.present e.login.error.blank
        job.fail 401, 'auth.creds.invalid.blank'
      else if page.present e.login.error.locked
        job.fail 403, 'auth.creds.locked'
      else if page.present e.login.user.field
        action.login()

  alertReceived: ->
    if message.match /Please fill in both the "User ID" and "Password" fields/
      job.fail 401, 'auth.creds.invalid.blank'

  actions:
    login: ->
      job.update 'auth.creds'
      page.fill e.login.user.field, answers.username
      page.fill e.login.pass.field, answers.password
      page.click e.login.continueButton

    logout: ->
      job.succeed()
      page.click e.logout.link

  elements:
    login:
      user:
        field: [
          # home page
          '//form[@name="ssoform"]//input[@name="Userid"][@type="text"]'
          '//form[@name="ssoform"]//input[@name="UserID"][@type="text"]'
          '//input[@name="Userid"][@type="text"]'
          '//form[@name="ssoform"]//input[@type="text"]'
          # login page
          '//form[@name="frmLogin"]//input[@name="UserID"][@type="text"]'
          '//input[@name="UserID"][@type="text"]'
          '//form[@name="frmLogin"]//input[@type="text"]'
        ]

      pass:
        field: [
          # home page
          '//form[@name="ssoform"]//input[@name="Pword"][@type="password"]'
          '//form[@name="ssoform"]//input[@name="Password"][@type="password"]'
          '//input[@name="Pword"][@type="password"]'
          '//form[@name="ssoform"]//input[@type="password"]'
          # login page
          '//form[@name="frmLogin"]//input[@name="Password"][@type="password"]'
          '//input[@name="Password"][@type="password"]'
          '//form[@name="frmLogin"]//input[@type="password"]'
        ]

      error:
        general: [
          '//text()[contains(., "User ID or Password is incorrect")]'
          '//text()[contains(., "you will be locked out if your next login attempt is unsuccessful")]'
        ]

        blank: [
          '//text()[contains(., "You\'ve left a field blank")]'
        ]

        locked: [
          '//text()[contains(., "Your User ID is locked")]'
        ]

      continueButton: [
        # home page
        '//form[@name="ssoform"]//*[contains(@onclick, "validate")]'
        '//form[@name="ssoform"]//*[@name="btn"][@onclick]'
        '//form[@name="ssoform"]//input[@type="submit" or @type="image"]'
        # login page
        '//input[contains(@onclick, "loginNow")]'
        '//form[@name="frmLogin"]//input[@type="submit" or @type="image"]'
      ]

    logout:
      link: [
        '//a[contains(@href, "Logoff")]'
        '//a[contains(@href, "Logout")]'
        '//a[contains(string(.), "Log Off")]'
        '//a[contains(string(.), "Log Out")]'
        '//a[contains(string(.), "Logout")]'
        '//a[contains(string(.), "Logoff")]'
      ]
