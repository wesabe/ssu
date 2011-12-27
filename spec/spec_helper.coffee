# run with:
# $ rake spec
# OR
# $ npm install -g jasmine-node
# $ jasmine-node --coffee spec

path = require 'path'
fs   = require 'fs'
root = path.join(path.dirname(fs.realpathSync(__filename)), '..')

# bring in a few things to make node.js be semi-compatible with xulrunner
require path.join(root, 'lib/node-ext')

# bring in the main wesabe code
wesroot = path.join(root, 'application/chrome/content/wesabe')
require wesroot

# set up a logger for all of node.js
Logger = require 'Logger'
GLOBAL.logger = Logger.rootLogger
logger.appender = ->

exports.wesabe = wesabe
