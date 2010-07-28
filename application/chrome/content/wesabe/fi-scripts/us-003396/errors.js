wesabe.provide('fi-scripts.us-003396.errors', {
  dispatch: function() {
    if (page.present(e.errors.unableToCompleteAction))
      job.fail(503, 'fi.error');
  },

  elements: {
    errors: {
      unableToCompleteAction: [
        '//text()[contains(string(.), "We were unable to process your request")]',
      ],
    },
  },
});
