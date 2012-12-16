
tempVec2 = vec2.create()

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
      @map = new Map(@graphics.collisionImage, @graphics.worldImage)
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

    backgroundModified = false
    si = 0
    di = 0
    while si < @particles.length
      sp = @particles[si]
      dp = @particles[di]
      dp.x = sp.x + sp.vx
      dp.y = sp.y + sp.vy
      dp.vy = sp.vy + tweaks.gravity

      if dp.x > @graphics.canvas.width or dp.x < 0 or dp.y < 0
        #console.log 'particle died:', dp
      else
        intx = Math.floor(dp.x)
        inty = Math.floor(dp.y)
        if @map.isOccupied(intx, inty)
          if sp.explosive
            @map.explode intx, inty, 5, (p) =>
              #console.log 'add particle', x, y
              @addParticle p
            backgroundModified = true
        else
          dp.vx = sp.vx
          dp.vy = sp.vy
          dp.explosive = sp.explosive
          dp.r = sp.r
          dp.g = sp.g
          dp.b = sp.b
          di++
      si++
    @particles.length = di

    if backgroundModified
      @graphics.updateBackground @map.colorData
    @graphics.render @particles

  onMouseDown: (event) =>
    @dragging = true
    @mouseX = event.clientX
    @mouseY = event.clientY

    dir = tempVec2
    dir[0] = event.clientX
    dir[1] = @graphics.canvas.height - event.clientY
    vec2.subtract dir, tweaks.missileOrigin, dir
    vec2.scale dir, tweaks.projectileVelocity / vec2.length(dir)
    @addParticle
      x: tweaks.missileOrigin[0]
      y: tweaks.missileOrigin[1]
      vx: dir[0]
      vy: dir[1]
      explosive: true
      r: 1.0, g: .5, b: 0

    $(@eventsElement).mousemove @onMouseDrag
    event.preventDefault()

  onMouseUp: (event) =>
    @dragging = false

    $(@eventsElement).off 'mousemove', @onMouseDrag

  onMouseDrag: (event) =>
    x = event.clientX
    y = event.clientY

    if @dragging
      dx = x - @mouseX
      dy = y - @mouseY

    @mouseX = x
    @mouseY = y

    event.preventDefault()

  addParticle: (particle) ->
    @particles.push particle
