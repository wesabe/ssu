wesabe.provide('fi-scripts.com.bankofamerica.global', {
  dispatch: function() {
    if (page.present(e.global.error.system.text)) {
      page.back();
      return false;
    }
  },

  actions: {
    clickThroughSystemError: function() {
      page.click(e.global.error.system.backButton);
    },
  },

  elements: {
    global: {
      error: {
        system: {
          text: [
          '//*[contains(string(.), "be patient while your request is being processed")][contains(string(.), "Click on the link below to navigate back to your Online Banking Session")]',
          ],

          backButton: [
            '//a[contains(string(.), "Back")]',
          ],
        },
      },
    },
  },
});
