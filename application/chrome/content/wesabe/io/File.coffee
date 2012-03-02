module.exports = if Cc?
  require 'io/xulrunner/File'
else if phantom?
  require 'io/phantom/File'
else
  require 'io/node/File'
