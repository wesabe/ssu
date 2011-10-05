crypto = require 'crypto'

describe 'crypto', ->
  it 'can calculate an md5 hash', ->
    expect(crypto.createHash('md5').update('abcdefg').digest('hex')).toEqual('7ac66c0f148de9519b8bd264312c4d64')
