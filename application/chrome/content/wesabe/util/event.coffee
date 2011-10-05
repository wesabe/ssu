{isString} = require 'lang/type'
array = require 'lang/array'
data  = require 'util/data'

guid = 0

canHandleEvents = (object) ->
  return false unless object

  object?.nodeType not in [3, 4, 8] # text, cdata, comment

# shamelessly adapted from jQuery
add = (elem, type, handler) ->
  if isString elem
    handler = type
    type = elem
    elem = wesabe

  return unless canHandleEvents(elem)

  handler.guid ||= ++guid

  events = data(elem, 'events') || data(elem, 'events', {})
  handlers = events[type]

  handlers ||= events[type] = {}

  handlers[handler.guid] = handler

  elem.addEventListener?(type, handler, false)

remove = (elem, type, handler) ->
  if isString elem
    handler = type
    type = elem
    elem = wesabe

  return unless canHandleEvents(elem)

  events = data(elem, 'events') or data(elem, 'events', {})

  if not type
    # remove all events for elem
    for type of events
      remove elem, type

  else
    # remove events of a specific type
    if events[type]
      if handler
        # remove a specific handler
        delete events[type][handler.guid]
        elem.removeEventListener?(elem, type, handler)
      else
        # remove all handlers for type
        for handler of events[type]
          remove elem, type, events[type][handler]

trigger = (elem, types, args) ->
  if isString elem
    args = types
    types = elem
    elem = wesabe

  events = data(elem, 'events') or data(elem, 'events', {})
  forwards = data(elem, 'event-forwards')

  for type in types.split(/\s+/)
    if events[type]
      args = array.from args or []

      unless args[0]?.preventDefault
        args.unshift
          type: type
          target: elem

      for handler of events[type]
        events[type][handler].apply(elem, args)

  if forwards
    for felem in forwards
      trigger felem, types, args

forward = (from, to) ->
  forwards = data(from, 'event-forwards') or data(from, 'event-forwards', [])
  forwards.push to

one = (elem, type, fn) ->
  if isString elem
    fn = type
    type = elem
    elem = wesabe

  add elem, type, (args...) ->
    remove this, type, arguments.callee
    return fn.call(this, args...)

# shortcuts
wesabe ?= require '../../../wesabe'
wesabe.bind = add
wesabe.unbind = remove
wesabe.trigger = trigger
wesabe.one = one

module.exports = {add, remove, trigger, forward, one}
