wesabe.provide('util.benchmark')

wesabe.util.benchmark =
  bm: (callbacks, count) ->
    # wesabe.info('Benchmark')
    wesabe.info('================================================')
    for key, callback of callbacks
      wesabe.info(key,': ',@time(callback, count))
    wesabe.info('================================================')

  time: (callback, count) ->
    count = 1 if wesabe.isUndefined(count)
    times = []
    total = 0
    sqtotal = 0

    for i in [0...count]
      try
        now = new Date().getTime()
        callback.call(wesabe)
        diff = new Date().getTime() - now

        total += diff
        sqtotal += Math.pow(diff, 2)
        times.push(diff)
      catch e
        return {inspect: -> "error: #{e.toString()}"}

    average  = total / count
    variance = (sqtotal / count) - Math.pow(average, 2)
    stddev   = Math.pow(variance, 0.5)

    average: average
    variance: variance
    stddev: stddev
    total: total
    count: count
    round: (f) ->
      parseFloat(parseInt(parseFloat(f) * 100))/100
    inspect: ->
      "average: #{@round(@average,2)
   }ms stddev: #{@round(@stddev)
   }ms total: #{@round(@total)
   }ms (#{@count} times)"

wesabe.bm = wesabe.util.benchmark.bm
