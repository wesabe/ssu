wesabe.provide 'fi-scripts.com.chase.errors',
  dispatch: ->
    if page.present e.errors.unableToCompleteAction
      job.fail 503, 'fi.error'

    if page.present e.errors.systemUnavailable
      job.fail 503, 'fi.unavailable'

  elements:
    errors:
      unableToCompleteAction: [
        '//text()[contains(string(.), "We were unable to process your request")]'
      ]

      systemUnavailable: [
        '//div[@id="statusPanel"][contains(string(.), "System Unavailable")]'
      ]
