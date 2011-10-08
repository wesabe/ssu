module.exports = if Cc?
  require 'io/xulrunner/File'
else
  require 'io/node/File'
