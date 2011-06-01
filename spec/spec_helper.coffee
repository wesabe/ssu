# run with:
# $ rake spec
# OR
# $ npm install jasmine-node
# $ jasmine-node --coffee spec

path = require 'path'
fs = require 'fs'

require.paths.push path.join(path.dirname(fs.realpathSync(__filename)), '../lib')

{wesabe} = require 'wesabe'
wesabe.setLoggerSilent true

exports.wesabe = wesabe
