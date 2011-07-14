wesabe.provide 'fi-scripts.com.chase.promos',
  dispatch: ->
    if page.present e.promos.indicator
      action.promosSkip()

  actions:
    promosSkip: ->
      page.click e.promos.skipLink

  elements:
    promos:
      indicator: [
        '//form[contains(@action, "Interstitial")]'
      ]

      skipLink: [
        '//a[contains(@href, "ViewAd")][contains(@href, "MyAccounts")]'
        '//input[@type="button" or @type="submit" or @type="image"][contains(@value, "My Accounts")]'
      ]
