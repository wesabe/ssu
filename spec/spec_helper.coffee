# run with:
# $ rake spec
# OR
# $ npm install -g jasmine-node
# $ jasmine-node --coffee spec

path = require 'path'
fs = require 'fs'

require.paths.unshift path.join(path.dirname(fs.realpathSync(__filename)), '../lib')
require.paths.unshift path.join(path.dirname(fs.realpathSync(__filename)), '../application/chrome/content/wesabe')

{wesabe} = require 'wesabe'
wesabe.setLoggerSilent true

exports.wesabe = wesabe
