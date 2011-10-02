# run with:
# $ rake spec
# OR
# $ npm install -g jasmine-node
# $ jasmine-node --coffee spec

path = require 'path'
fs = require 'fs'

require.paths.unshift path.join(path.dirname(fs.realpathSync(__filename)), '../lib')
require.paths.unshift path.join(path.dirname(fs.realpathSync(__filename)), '../application/chrome/content/wesabe')

GLOBAL.dump = (str) ->
  str = str[0..str.length-2] if str.substring(str.length-1) is '\n'
  console.log str

{wesabe} = require 'wesabe'
GLOBAL.wesabe = wesabe

Logger = require 'Logger'
GLOBAL.logger = Logger.rootLogger
logger.appender = ->

exports.wesabe = wesabe
