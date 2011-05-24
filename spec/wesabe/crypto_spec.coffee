crypto = wesabe.require 'crypto'

describe 'wesabe.crypto', ->
  it 'can calculate an md5 hash', ->
    expect(crypto.md5('abcdefg')).toEqual('7ac66c0f148de9519b8bd264312c4d64')
