class @Game
  constructor: ({
    # Element which will get the game canvas as a child
    @parentElement,
    # Element to attach events to
    @eventsElement
  }) ->
    @dragging = false
    @mouseX = @mouseY = 0

    @graphics = new Graphics(@parentElement)
    @keyboard = new Keyboard
    @clock = new Clock

    @particles = []

  init: (onFinished) ->
    @graphics.init =>
      @map = new Map(@graphics.collisionImage)
      onFinished()

  start: ->
    $(@eventsElement)
      .mousedown(@onMouseDown)
      .click(@onMouseClick)
    $(document.body).mouseup(@onMouseUp)

    $(document).keydown(@keyboard.onKeyDown).keyup(@keyboard.onKeyUp)

    document.addEventListener 'mozvisibilitychange', @handleVisibilityChange, false
    if document.mozVisibilityState and document.mozVisibilityState != 'visible'
      console.log 'Not starting animation because game not visible'
    else
      @startAnimation()

  startAnimation: ->
    if @animating
      console.log 'animation already started!'
    else
      console.log 'starting animation'
      @animating = true
      @clock.reset()
      requestAnimationFrame @animationFrame

  stopAnimation: ->
    if not @animating
      console.log 'animation not running'
    else
      @animating = false

  handleVisibilityChange: (e) =>
    if document.mozVisibilityState != 'visible'
      @stopAnimation()
    else
      @startAnimation()

  animationFrame: =>
    @animate()
    if @animating
      requestAnimationFrame @animationFrame

  animate: =>
    deltaTime = @clock.tick()
    @graphics.animate deltaTime

    si = 0
    di = 0
    while si < @particles.length
      sp = @particles[si]
      dp = @particles[di]
      dp.x = sp.x + sp.vx
      dp.y = sp.y + sp.vy
      dp.vy = sp.vy - .1
      if dp.x > @graphics.canvas.width or dp.x < 0 or dp.y < 0
        #console.log 'particle died:', dp
      else if @map.isOccupied(Math.floor(dp.x), Math.floor(dp.y))
        #console.log 'hit!'
      else
        dp.vx = sp.vx
        dp.vy = sp.vy
        di++
      si++
    @particles.length = di
    @graphics.render @particles

  onMouseDown: (event) =>
    @dragging = true
    @mouseX = event.clientX
    @mouseY = event.clientY

    $(@eventsElement).mousemove @onMouseDrag
    event.preventDefault()

  onMouseUp: (event) =>
    x = event.clientX
    y = @graphics.canvas.height - event.clientY
    @addParticle x, y
    @dragging = false

    $(@eventsElement).off 'mousemove', @onMouseDrag

  onMouseDrag: (event) =>
    x = event.clientX
    y = event.clientY

    if @dragging
      dx = x - @mouseX
      dy = y - @mouseY
      #@graphics.camera.translateZ dy
      @addParticle x, @graphics.canvas.height - y, dx, -dy

    @mouseX = x
    @mouseY = y

    event.preventDefault()

  addParticle: (x, y, vx=0, vy=0) ->
    @particles.push
      x: x
      y: y
      vx: vx
      vy: vy
