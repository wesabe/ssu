privacy = require 'util/privacy'

wesabe.provide 'fi-scripts.com.chase.transfers',
  dispatch: ->
    return if job.goal isnt 'transfer'

    transfer = job.options.transfer

    if not transfer or not transfer.source or not transfer.destination or not transfer.amount
      logger.error "Some transfer data was missing (requires 'source', 'destination', and 'amount'), given:", privacy.taint(transfer)
      return

    if not page.present e.transfers.indicator
      if page.present e.logoff.link
        action.goTransfersPage()
      else
        return

    if page.present e.transfers.confirmation.indicator
      job.succeed()
      action.logoff()
    else if page.present e.transfers.errors.general
      job.fail 'transfer.error'
    else if page.present e.transfers.accountSelection.fromAccount
      action.selectAccounts()
    else if page.present e.transfers.form.amount
      action.fillTransferForm()
    else if page.present e.transfers.verification.continueButton
      action.confirmTransfer()

  actions:
    goTransfersPage: ->
      if page.present e.sidebarScheduleTransferNavLink
        # take the shortcut if we see it
        page.click e.sidebarScheduleTransferNavLink
      else if page.present e.scheduleATransferQuickLink
        # click "Schedule a Transfer" from the "Account Transfers" page
        page.click e.scheduleATransferQuickLink
      else if page.present e.accountTransfersSubtabLink
        # click "Account Transfers" from the "Payments & Transfers" page
        page.click e.accountTransfersSubtabLink
      else if page.present e.paymentsAndTransfersTabLink
        # click "Payments & Transfers" from anywhere
        page.click e.paymentsAndTransfersTabLink

    selectAccounts: ->
      transfer = job.options.transfer

      job.update 'transfer.accounts'
      page.fill e.transfers.accountSelection.fromAccount, transfer.source
      page.fill e.transfers.accountSelection.toAccount, transfer.destination

      page.click e.transfers.accountSelection.continueButton

    fillTransferForm: ->
      transfer = job.options.transfer

      job.update 'transfer.schedule'
      page.fill e.transfers.form.amount, transfer.amount

      if transfer.memo
        page.fill e.transfers.form.memo, transfer.memo

      page.click e.transfers.form.continueButton

    confirmTransfer: ->
      page.click e.transfers.verification.continueButton

  elements:
    paymentsAndTransfersTabLink: [
      '//a[contains(@href, "payments")][@name="Payments & Transfers"]'
      '//td[contains(@class, "tabpayments")]//a'
    ]

    accountTransfersSubtabLink: [
      '//a[contains(@href, "page=xfr")][.//img[contains(@title, "Account Transfers")]]',
    ]

    sidebarScheduleTransferNavLink: [
      '//a[@id="Make_a_transfer"]'
      '//a[contains(@href, "Transfer")][contains(string(.), "Make a transfer")]'
    ]

    scheduleATransferQuickLink: [
      '//a[@name="Scheduleatransfer"][contains(@href, "Transfer")]'
    ]

    transfers:
      indicator: [
        '//*[contains(@class, "pagetitle")][contains(string(.), "Transfer Money")]'
      ]

      accountSelection:
        fromAccount: [
          '//select[@name="FromAccount"]'
        ]

        toAccount: [
          '//select[@name="ToAccount"]'
        ]

        transferType:
          oneTime: [
            '//input[@type="radio"][@name="TransactionType"][@value="One-Time"]'
          ]

          repeating: [
            '//input[@type="radio"][@name="TransactionType"][@value="Repeating"]'
          ]

        continueButton: [
          '//input[@type="submit" or @type="image"][@id="NextButton"][@value="Next"]'
        ]

      form:
        date: [
          '//input[@type="text"][@name="TransferForm1$DeliverByDate_Value"]'
          '//input[@type="text"][contains(@title, "Enter date")]'
        ]

        amount: [
          '//input[@type="text"][@name="TransferForm1$TransferAmount"]'
          '//input[@type="text"][contains(@title, "Enter amount")]'
        ]

        memo: [
          '//input[@type="text"][@name="TransferForm1$Memo"]'
          '//input[@type="text"][contains(@title, "Enter memo")]'
        ]

        continueButton: [
          '//input[@type="submit" or @type="image"][@id="NextButton"][@value="Next"]'
        ]

      verification:
        continueButton: [
          '//input[@type="submit" or @type="image"][@id="NextButton"][@value="Submit"]'
        ]

      confirmation:
        indicator: [
          '//*[contains(@class, "confrow")][contains(string(.), "Transfer Scheduled")]'
          '//*[contains(@summary, "confirmation")][contains(string(.), "Transfer Scheduled")]'
        ]

      errors:
        general: [
          '//*[contains(@class, "errorrow")][not(contains(string(.), "Attention"))]'
        ]
