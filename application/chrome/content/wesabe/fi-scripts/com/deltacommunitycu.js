// player for debugging purposes
wesabe.download.OFXPlayer.register({
  fid: 'com.deltacommunitycu',
  org: 'Delta Community Credit Union (Snap)',

  start: function() {
    wesabe.logger.level = 'radioactive';
    wesabe.download.OFXPlayer.prototype.start.apply(this, arguments); // super
  }
});
