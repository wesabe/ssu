wesabe.provide('fi-scripts.com.bankofamerica.passwordStrengthNotice', {
  dispatch: function() {
    if (page.present(e.passwordStrengthNotice.indicator)) {
      job.fail(403, 'auth.pass.weak');
    }
  },

  elements: {
    passwordStrengthNotice: {
      indicator: '//title[contains(., "Strengthen Online ID and Passcode")]',

      remindMeLaterButton: [
        '//a[contains(@href, "Continue")][img[@name="RemindMeLater" or contains(@src, "Remind") or contains(@alt, "Remind")]]',
      ],
    },
  },
});
