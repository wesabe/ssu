if phantom?
  module.exports = require 'io/http/phantom/server'
else if Cc?
  module.exports = require 'io/http/xulrunner/server'
else
  module.exports = require 'io/http/node/server'