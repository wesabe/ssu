wesabe.download.Player.register({
  fid: 'us-004273',
  org: 'Washington Mutual - Credit Card',

  actions: {
    main: function() {
      log.warn("Washington Mutual is now Chase (us-003396)");
      job.fail(400, 'fi.unsupported');
    },
  },
});
