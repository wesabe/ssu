module.exports = if Cc?
  require 'io/xulrunner/Dir'
else if phantom?
  require 'io/phantom/Dir'
else
  require 'io/node/Dir'
