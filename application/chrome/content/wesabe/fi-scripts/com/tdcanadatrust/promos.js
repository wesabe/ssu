wesabe.provide('fi-scripts.com.tdcanadatrust.promos', {
  dispatch: function() {
    if (page.url.match(/DirectMarketingServlet/)) {
      if (page.present(e.promos.mortgage.indicator)) {
        action.bypassMortgage();
      } else {
        wesabe.error("Unrecognized promo, dumping out page info");
        page.dumpPrivately();
        job.fail(500, 'ssu.script.incomplete');
      }
    }
  },

  actions: {
    bypassMortgage: function() {
      page.click(e.promos.mortgage.showMeLaterButton);
    },
  },

  elements: {
    promos: {
      // see fi-info/com.tdcanadatrust/promos/mortgage.png
      mortgage: {
        indicator: [
          '//img[contains(@alt, "family and house")]',
          '//text()[contains(., "mortgage")]',
        ],

        // FIXME <brian@wesabe.com> 2009-01-27: Figure out what is really here.
        // I have no idea what the HTML here actually looks like, so I'm just
        // shooting in the dark based on an image capture of the page.
        showMeLaterButton: [
          '//img[contains(@title, "later") or contains(@title, "Later")][ancestor::a or @onclick]',
          '//input[@type="image"][contains(@title, "later")]',
          '//img[contains(@src, "later")][ancestor::a or @onclick]',
          '//input[@type="image"][contains(@src, "later")]',
        ],
      },
    },
  },
});
