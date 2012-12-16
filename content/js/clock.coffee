# Get system time in seconds since some starting time
if window.performance and window.performance.now
  now = ->
    window.performance.now() / 1000
else if window.performance and window.performance.webkitNow
  now = ->
    window.performance.webkitNow() / 1000
else if Date.now
  now = ->
    Date.now() / 1000 - 1355591199
else
  now = ->
    +(new Date) / 1000 - 1355591199

class @Clock
  constructor: (@maxTickLength=.1) ->
    @numberOfTicks = 0
    @startTime = now()
    @lastTick = @startTime

  reset: ->
    @lastTick = now()

  tick: ->
    newTime = now()
    length = newTime - @lastTick
    if length >= @maxTickLength
      length = @maxTickLength
    @lastTickLength = length
    @lastTick = newTime
    @numberOfTicks++
    return length

  getElapsedTime: ->
    return @lastTick - @startTime

Clock.now = now


class @ConstantRateClock
  constructor: (tickLength=1/60, maxTicks=6) ->
    @tickLength = tickLength
    @maxTicks = maxTicks

    @startTime = now()
    @lastTick = @startTime

  reset: ->
    @lastTick = now()

  # Returns the number of ticks that have passed
  tick: ->
    newTime = now()
    length = newTime - @lastTick
    ticks =  Math.floor(length / @tickLength)
    if ticks > @maxTicks
      @lastTick = newTime
      #console.log 'too many ticks in one frame:', ticks
      return @maxTicks
    else
      @lastTick += ticks * @tickLength
      return ticks
