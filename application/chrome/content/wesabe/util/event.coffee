wesabe.provide('util.event')
wesabe.require('util.data')

data = wesabe.util.data

guid = 0

# shamelessly adapted from jQuery
wesabe.util.event =
  add: (elem, type, handler) ->
    if wesabe.isString(elem)
      handler = type
      type = elem
      elem = wesabe

    # ignore text and comment nodes
    return if elem.nodeType == 3 || elem.nodeType == 8

    handler.guid ||= ++guid

    events = data(elem, 'events') || data(elem, 'events', {})
    handlers = events[type]

    handlers ||= events[type] = {}

    handlers[handler.guid] = handler

    elem.addEventListener?(type, handler, false);

  remove: (elem, type, handler) ->
    if wesabe.isString(elem)
      handler = type
      type = elem
      elem = wesabe

    # ignore text and comment nodes
    return if elem.nodeType == 3 || elem.nodeType == 8

    events = data(elem, 'events') || data(elem, 'events', {})

    if not type
      # remove all events for elem
      for type of events
        wesabe.util.event.remove(elem, type)

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
            @remove(elem, type, events[type][handler])

  trigger: (elem, types, args) ->
    if wesabe.isString(elem)
      args = types
      types = elem
      elem = wesabe

    events = data(elem, 'events') || data(elem, 'events', {})
    forwards = data(elem, 'event-forwards')

    for type in types.split(/\s+/)
      if events[type]
        args = wesabe.lang.array.from(args || [])

        unless args[0]?.preventDefault
          args.unshift
            type: type
            target: elem

        for handler of events[type]
          events[type][handler].apply(elem, args)

    if forwards
      for felem in forwards
        @trigger(felem, types, args)

  forward: (from, to) ->
    forwards = data(from, 'event-forwards') || data(from, 'event-forwards', [])
    forwards.push(to)

wesabe.bind = wesabe.util.event.add
wesabe.unbind = wesabe.util.event.remove
wesabe.trigger = wesabe.util.event.trigger
wesabe.one = (elem, type, fn) ->
  if wesabe.isString(elem)
    fn = type
    type = elem
    elem = wesabe

  wesabe.bind elem, type, ->
    wesabe.unbind(this, type, arguments.callee)
    return fn.apply(this, arguments)
