// player for debugging purposes
wesabe.download.OFXPlayer.register({
  fid: 'us-015635',
  org: 'Delta Community Credit Union (Snap)',

  start: function() {
    wesabe.logger.level = 'radioactive';
    wesabe.download.OFXPlayer.prototype.start.apply(this, arguments); // super
  }
});