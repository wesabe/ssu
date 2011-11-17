# this is just a shim to allow `{EventEmitter} = require 'events'`

# xulrunner
{EventEmitter2} = window if window?

# node.js
{EventEmitter2} = require '../eventemitter2' unless EventEmitter2

module.exports = {EventEmitter: EventEmitter2, sharedEventEmitter: new EventEmitter2}
