wesabe.provide("fi-scripts.com.citibank.terms", {
  dispatch: function() {
    if (page.present(e.terms.page.indicator)) {
      job.fail(403, 'auth.incomplete.terms');
    }
  },

  actions: {
  },

  elements: {
    terms: {
      page: {
        indicator: [
          '//text()[contains(., "agree electronically to the terms and conditions of the User Agreement")]',
          '//a[@id="cmlink_AgreeBtnTermsAndConditions"]',
        ],
      },

      text: [
        '//div[@id="jrstandc"]',
      ],

      choices: {
        yes: [
          '//a[@id="cmlink_AgreeBtnTermsAndConditions"]',
          '//a[contains(string(.), "I agree")]',
        ],

        no: [
          '//a[@id="cmlink_DisagreeBtnTermsAndConditions"]',
          '//a[contains(string(.), "I disagree")]',
        ],
      },
    },
  },
});
