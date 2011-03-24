wesabe.provide('fi-scripts.com.usbank.security', {
  dispatch: function() {
    if (page.present(e.security.indicator)) {
      action.answerSecurityQuestions();
    }
  },

  actions: {
    // answerSecurityQuestions is defined in Player.js
  },

  elements: {
    security: {
      indicator: [
        '//text()[contains(., "Answer your ID Shield Question")]',
      ],

      questions: [
        '//form[@name="challenge"]//text()[contains(., "?")][not(ancestor::a)]',
      ],

      answers: [
        '//form[@name="challenge"]//input[@type="text"][@name="ANSWER"]',
      ],

      continueButton: [
        '//form[@name="challenge"]//input[@type="image" or @type="submit"]',
      ],
    },
  },
});
