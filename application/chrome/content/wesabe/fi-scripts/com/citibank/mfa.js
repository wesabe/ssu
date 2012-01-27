wesabe.provide("fi-scripts.com.citibank.mfa", {
  dispatch: function() {
    if (page.present(e.mfa.indicator)) {
      action.answerSecurityQuestions();
      return false;
    }
  },

  actions: {
  },

  elements: {
    mfa: {
      indicator: [
        '//*[has-class("jrspageHeader")][contains(string(.), "Authorization Required")]',
        '//form[@action="/US/JRS/mfa/cq/ValidateCQ.do"]',
      ],

      cin: [ // ATM/Debit Card # (CIN)
        '//input[@type="text"][@name="cin"]',
      ],

      pin: [ // PIN
        '//input[@type="password"][@name="pin"]',
      ],

      continueButton: [
        '//input[@type="image"][contains(@src, "cont_btn")]',
        '//input[@type="submit" or @type="image"]',
      ],
    },

    security: {
      questions: [
        '//form[contains(@action, "mfa")]//*[has-class("jrsnoteText")]/b/text()',
      ],

      answers: [
        '//form[contains(@action, "mfa")]//input[@type="text" or @type="password"]',
      ],

      continueButton: [
        '//input[@type="image"][contains(@src, "cont_btn")]',
        '//input[@type="submit" or @type="image"]',
      ],
    },
  },
});
