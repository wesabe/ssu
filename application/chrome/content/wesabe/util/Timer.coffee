type = require 'lang/type'

#
# Measure the time taken to perform actions given by a label. Example:
#
#   var timer = new Timer();
#   timer.start('Compute');
#   // do some computing
#   timer.end('Compute');
#
# You can also pass along a callback which will call `end' for you:
#
#   timer.start('Compute', function() {
#     // do some computing
#   });
#
# Calling start/end multiple times with the same label is allowed.
# When you call `summarize' they will simply be added together:
#
#   while (something) {
#     // `start' called with 'Compute' several times
#     timer.start('Compute', function() {
#       // do some computing
#     });
#   }
#
#   // adds up all the 'Compute' durations
#   timer.summarize();  // => {Compute: 12984}
#
class Timer
  constructor: ->
    @data = {}
    @pending = []

  this::__defineGetter__ 'now', ->
    new Date().getTime()

  start: (label, fn) ->
    @data[label] ||= []
    @data[label].push
      start: @now

    index = @data[label].length - 1

    while @pending.length
      datum = @pending.shift()
      @end datum.label, datum.index

    if type.isFunction fn
      retval = fn()
      @end label, index
      return retval
    else if fn and type.isFalse(fn.overlap)
      @pending.push
        label: label
        index: index

    return index

  end: (label, index) ->
    if not @data[label]
      logger.warn "No timer entry found for ", label
      return

    if type.isNumber(index)
      if @data[label][index]
        @data[label][index].end = @now
      else
        logger.warn "No timer entry found for ", label, " at index ", index
    else
      for item in @data[label]
        # assume that the earliest one without an end is the one they want
        if not item.end
          item.end = @now
          return

      logger.warn "No unfinished timer entry found for ", label

  summarize: ->
    summary = {}
    now = @now

    for label, ranges of @data
      total = 0
      for {start, end} in ranges
        total += (end or now) - start
      summary[label] = total

    return summary
