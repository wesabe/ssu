wesabe.require("io.*");

wesabe.provide("util.words", {
  list: null, 

  exist: function(word) {
    wesabe.util.words.ensureLoaded();
    return wesabe.util.words.list.hasOwnProperty(word.toLowerCase());
  },

  ensureLoaded: function() {
    wesabe.require("util.words.list");
  }, 

  loaded: function() {
    return !!wesabe.util.words.list;
  }, 
});
