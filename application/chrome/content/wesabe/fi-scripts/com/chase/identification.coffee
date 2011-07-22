wesabe.provide 'fi-scripts.com.chase.identification',
  dispatch: ->
    if page.present e.identification.error.noIdentificationCode
      delete answers.identificationCode
      log.error "Given an identification code when there is none for the account, falling back to getting a new one"

    if page.present e.identification.page.info.indicator
      # Step 1: Identification Code
      if answers.identificationCode
        # already have an identification code, so skip the delivery method form
        action.jumpToIdentificationCodeEntry()
      else
        # no identification code yet, just click Next
        action.acknowledgeIdentificationRequirement();
    else if page.present e.identification.page.contact.indicator
      # Step 2: Select Method
      action.chooseIdentificationDeliveryMethod()
    else if page.present e.identification.page.confirmation.indicator
      # Step 3: Confirmation
      action.confirmIdentificationCode()
    else if page.present e.identification.page.codeEntry.indicator
      # Step 4: Enter Code
      action.enterIdentificationCode();
    else if page.present e.identification.page.legalAgreements.indicator
      job.fail 403, 'auth.incomplete.terms'

  actions:
    acknowledgeIdentificationRequirement: ->
      page.click e.identification.continueButton

    jumpToIdentificationCodeEntry: ->
      page.click e.identification.alreadyHaveIdentificationCodeLink

    collectIdentificationCodeDeliveryMethods: ->
      tmp.identificationCodeDeliveryMethods = []

      log.debug "Collecting phone delivery method options"
      phoneContainer = page.find e.identification.contacts.phone.container
      if not phoneContainer
        log.warn "No phone number container -- maybe failed to find it?"
      else
        options = page.select e.identification.contacts.option, phoneContainer
        log.debug "Found phone delivery options: ", options
        options.forEach (option) ->
          option = wesabe.untaint(option)

          mask = wesabe.untaint(page.findStrict(e.identification.contacts.phone.mask, option))
          method = {value: option.value, key: option.id, label: mask.nodeValue}

          if option.value.match(/SMS/)
            method.label = "Text "+method.label
          else
            method.label = "Voice "+method.label
          tmp.identificationCodeDeliveryMethods.push(method)

      log.debug "Collecting email delivery method options"
      emailContainer = page.find(e.identification.contacts.email.container)
      if not emailContainer
        log.warn "No email container -- maybe failed to find it?"
      else
        options = page.select(e.identification.contacts.option, emailContainer)
        log.debug "Found email delivery options: ", options
        options.forEach (option) ->
          option = wesabe.untaint(option)

          mask = wesabe.untaint(page.findStrict(e.identification.contacts.email.mask, option))
          method = {value: option.value, key: option.id, label: "Email "+mask.nodeValue}

          tmp.identificationCodeDeliveryMethods.push(method)

      log.debug "Finished collecting delivery method options: ", tmp.identificationCodeDeliveryMethods

    chooseIdentificationDeliveryMethod: ->
      if answers.identificationCodeDeliveryMethod
        option = page.find(wesabe.xpath.bind(e.identification.contacts.optionTemplate, {value: answers.identificationCodeDeliveryMethod}))
        if not option
          log.warn "Unrecognized identification code delivery method choice: ", answers.identificationCodeDeliveryMethod
        else
          log.info "Delivering code via: ", option
          page.click option
          page.click e.identification.continueButton

          return true

      log.warn "Could not answer delivery method question, suspending job"
      action.collectIdentificationCodeDeliveryMethods()

      job.suspend "suspended.missing-answer.auth.identification.delivery-method",
        title: "Confirm Your Identity"
        header: "Chase needs a one-time Identification Code to confirm that you own the accounts before Wesabe can access them. Once you have the code we'll ask you to enter it on the next screen."
        questions: [
          type: "choice"
          label: "How should Chase send you the Identification Code?"
          key: "identificationCodeDeliveryMethod"
          persistent: false
          choices: tmp.identificationCodeDeliveryMethods
        ]

    confirmIdentificationCode: ->
      page.click e.identification.continueButton

    enterIdentificationCode: ->
      if answers.identificationCode
        page.fill e.identification.codeEntry.code.field, answers.identificationCode
        page.fill e.identification.codeEntry.password.field, answers.password
        page.click e.identification.continueButton
      else
        log.warn "Could not answer identification code question, suspending job"
        job.suspend "suspended.missing-answer.auth.identification.code",
          title: "Identification Code"
          header: "Please enter the identification code you received from Chase. If you didn't receive an identification code please cancel and try again."
          questions: [
            type: "number",
            label: "Identification Code",
            key: "identificationCode",
            persistent: false
          ]

  elements:
    identification:
      page:
        info:
          indicator: [
            '//td[@class="steptexton"][contains(string(.), "Identification")][not(contains(string(.), "Code"))]'
            '//form[@name="frmSSOSecAuthInformation"]'
          ]

        contact:
          indicator: [
            '//*[@class="instrtexthead"][contains(string(.), "Get your Identification Code")]'
          ]

        confirmation:
          indicator: [
            '//form[@name="frmOTPDeliveryModeConfirmation"]'
          ]

        codeEntry:
          indicator: [
            '//*[@class="instrtexthead"][contains(string(.), "Enter your Identification Code")]'
          ]

        legalAgreements:
          indicator: [
            '//td[@class="steptexton"][contains(string(.), "Legal Agreements")]'
            '//form[@name="frmSecureLA"]'
          ]

      contacts:
        option: [
          './/input[@type="radio"][@name="rdoDelMethod"]'
        ]

        optionTemplate: [
          '//input[@type="radio"][@name="rdoDelMethod"][@value=":value"]'
        ]

        phone:
          container: [
            '//table[@id="contactTable"]'
          ]

          mask: [
            '../preceding-sibling::*[@title]//text()[contains(., "xxx")]'
          ]

        email:
          container: [
            '//table[@id="emailContactTable"]'
          ]

          mask: [
            '../following-sibling::td/text()[contains(., "@")]'
          ]

      alreadyHaveIdentificationCodeLink: [
        '//a[@id="ancHavIdentificationCode"]'
      ]

      codeEntry:
        code:
          field: [
            '//input[@type="text"][@name="txtActivationCode"]'
            '//form[@name="frmValidateOTP"]//input[@type="text"]'
          ]

        password:
          field: [
            '//input[@type="password"][@name="txtPassword"]'
            '//form[@name="frmValidateOTP"]//input[@type="password"]'
          ]

      error:
        noIdentificationCode: [
          '//*[@class="errorText"][contains(string(.), "Select an Identification Code Delivery Method")]'
          '//text()[contains(., "Our records show that you do not currently have a valid Identification Code for this account")]'
        ]

      continueButton: [
        '//input[@name="NextButton"][@type="submit" or @type="image"]'
      ]

    customerCenter:
      tab:
        link: [
          '//a[contains(@href, "CustomerCenter")][@name="Customer Center"]'
          '//td[@title="Go to Customer Center"]//a'
          '//td[contains(@class, "tabcustomercenter")]//a'
        ]

      pfmLink: [
        '//a[contains(@href, "SelectDownloadMethod")]'
        '//a[contains(string(.), "Financial Management Software")]'
      ]
