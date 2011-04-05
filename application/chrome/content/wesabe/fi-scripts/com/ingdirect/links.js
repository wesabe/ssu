wesabe.provide('fi-scripts.com.ingdirect.links', {
  dispatch: function() {
    if (job.goal != 'links')
      return;

    tmp.authenticated = page.visible(e.signOffLink);
    if (!tmp.authenticated)
      return;

    if (page.present(e.links.linkRows))
      action.parseLinks();
    else if (page.present(e.links.navLink))
      action.goToMyLinks();
  },

  actions: {
    goToMyLinks: function() {
      page.click(e.links.navLink);
    },

    parseLinks: function() {
      var linkRows = page.select(e.links.linkRows);

      job.data.links = linkRows.map(function(linkRow) {
        var cells = page.cells(linkRow);

        return {
          accountNumber: wesabe.untaint(wesabe.lang.string.trim(page.text(cells[0]))),
          financialInstitution: wesabe.untaint(wesabe.lang.string.trim(page.text(cells[1]))),
          routingNumber: wesabe.untaint(wesabe.lang.string.trim(page.text(cells[2]))),
          status: wesabe.untaint(wesabe.lang.string.trim(page.text(cells[3]))).toLowerCase()
        };
      });

      action.logoff();
    },
  },

  elements: {
    links: {
      navLink: [
        '//a[contains(@href, "external_links")][contains(string(.), "My Links")]',
      ],

      linkRows: [
        '//table[@id="myLinksTable"]//tr[position()>1]',
      ],
    },
  }
});
