wesabe.provide 'fi-scripts.com.ingdirect.links',
  dispatch: ->
    return if job.goal isnt 'links'

    tmp.authenticated = page.visible(e.signOffLink)
    return unless tmp.authenticated

    if page.present e.links.linkRows
      action.parseLinks()
    else if externalAccountsLink = page.link 'External Accounts'
      page.click externalAccountsLink

  actions:
    parseLinks: ->
      {untaint} = require 'util/privacy'
      {trim}    = require 'lang/string'

      linkRows = page.select e.links.linkRows

      job.data.links = for linkRow in linkRows
        [an, fi, rn, st] = (untaint(trim(page.text(cell))) for cell in page.cells(linkRow))

        accountNumber: an
        financialInstitution: fi
        routingNumber: rn
        status: st.toLowerCase()

      job.nextGoal()

  elements:
    links:
      linkRows: [
        '//table[@id="myLinksTable"]//tr[position()>1]'
      ]
