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

  init: (onFinished) ->
    @graphics.init onFinished

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

    @graphics.render()

  onMouseDown: (event) =>
    @dragging = true
    @mouseX = event.clientX
    @mouseY = event.clientY

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
      #@graphics.camera.translateZ dy

    @mouseX = x
    @mouseY = y

    event.preventDefault()
