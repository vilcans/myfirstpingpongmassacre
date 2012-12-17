
tempVec2 = vec2.create()

IN_GAME = 1
GAME_OVER = 2


formatNumber = (n) ->
  if n >= 1000
    return "#{n}"
  if n >= 100
    return "#{n}"
  if n >= 10
    return "0#{n}"
  return "00#{n}"

class @Game
  constructor: ({
    # Element which will get the game canvas as a child
    @parentElement,
    # Element to attach events to
    @eventsElement
  }) ->
    @state = IN_GAME

    @graphics = new Graphics(@parentElement)
    @keyboard = new Keyboard
    @clock = new ConstantRateClock(tickLength=1/120)

    @particles = []
    @score =
      perType: Map.createEmptyScoresArray()

    @lastAmmo = -1  # for gui update
    @ammo = tweaks.ammo
    @ammoElement = document.getElementById('ammo')

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
    $(@eventsElement).mousemove @onMouseMove

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
    if @state == IN_GAME
      @animateInGame()
    @graphics.render @particles

  animateInGame: ->
    @backgroundModified = false
    ticks = @clock.tick()
    @scoresForFrame = Map.createEmptyScoresArray()
    while ticks--
      @advanceFrame()
    if @backgroundModified
      @graphics.updateBackground @map.colorData
    for score, type in @scoresForFrame
      if score
        #console.log type, score
        @score.perType[type] += score

    if @ammo != @lastAmmo
      @lastAmmo = @ammo
      @ammoElement.textContent = formatNumber(@ammo)

    if @ammo == 0 and @particles.length == 0
      @enterGameOverState()

  enterGameOverState: ->
    @state = GAME_OVER
    $('#gameover').show('slow')
    for typeName, type of Map.pixelTypes
      element = document.getElementById("kill#{type}")
      if element
        element.textContent = "#{@score.perType[type]}"
      element = document.getElementById("percent#{type}")
      total = @map.totalPerType[type]
      if element and total
        percent = Math.floor(@score.perType[type] / total * 100 + .5)
        element.textContent = "#{percent} %"

  advanceFrame: ->
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
          if sp.explosiveness
            @map.explode(
              intx, inty,
              tweaks.explosionRadius,
              tweaks.nextExplosiveness[sp.explosiveness],
              @scoresForFrame,
              (p) =>
                #console.log 'add particle', x, y
                @addParticle p
            )
            @backgroundModified = true
        else
          dp.vx = sp.vx
          dp.vy = sp.vy
          dp.explosiveness = sp.explosiveness
          dp.r = sp.r
          dp.g = sp.g
          dp.b = sp.b
          di++
      si++
    @particles.length = di

  aim: (point) =>
    dir = tempVec2
    vec2.subtract point, tweaks.cannonPosition, dir

    angle = Math.atan2(dir[1], dir[0])
    @cannonAngle = Math.min(Math.max(angle, tweaks.cannonMinAngle), tweaks.cannonMaxAngle)
    @graphics.setCannonAngle @cannonAngle

  onMouseDown: (event) =>
    point = @getCoordinates(event)
    if @ammo > 0
      if --@ammo == tweaks.superAmmoLimit
        tweaks.ammoR = 1
        tweaks.ammoG = .8
        tweaks.ammoB = .2
      @aim point

      dx = Math.cos(@cannonAngle)
      dy = Math.sin(@cannonAngle)
      @addParticle
        # Subtracting tweaks.projectileVelocity as the particle will be moved once before displayed
        x: tweaks.cannonPosition[0] + dx * (tweaks.cannonLength - tweaks.projectileVelocity)
        y: tweaks.cannonPosition[1] + dy * (tweaks.cannonLength - tweaks.projectileVelocity)
        vx: dx * tweaks.projectileVelocity
        vy: dy * tweaks.projectileVelocity
        explosiveness: if @ammo < tweaks.superAmmoLimit then tweaks.superAmmoExplosiveness else tweaks.projectileExplosiveness
        r: tweaks.ammoR, g: tweaks.ammoG, b: tweaks.ammoB

  onMouseMove: (event) =>
    point = @getCoordinates(event)
    @aim point

  addParticle: (particle) ->
    @particles.push particle

  getCoordinates: (event) ->
    [event.pageX - @parentElement.offsetLeft, @graphics.canvas.height - (event.pageY - @parentElement.offsetTop)]
