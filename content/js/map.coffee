pixelTypes =
  AIR: 0,  # used as boolean: must be zero
  SOLDIERS: 1,
  PROPERTY: 2,
  KITTENS: 3,
  DIRT: 4,
  GOATS: 5,
  CHILDREN: 6,
  MEN: 7,
  WOMEN: 8,

createEmptyScoresArray = -> [0, 0, 0, 0, 0, 0, 0, 0, 0]

class @Map
  constructor: (collisionImage, worldImage) ->
    @canvas = document.createElement('canvas')
    @width = @canvas.width = collisionImage.width;
    @height = @canvas.height = collisionImage.height;
    @context = @canvas.getContext('2d')

    @context.clearRect 0, 0, @width, @height
    @context.drawImage worldImage, 0, 0
    @colorData = @context.getImageData(0, 0, @width, @height)

    @createCollisionMap collisionImage

  createCollisionMap: (collisionImage) ->
    @totalPerType = createEmptyScoresArray()
    @context.clearRect 0, 0, @width, @height
    @context.drawImage collisionImage, 0, 0
    imageData = @context.getImageData(0, 0, @width, @height)
    buffer = new ArrayBuffer(@width * @height)
    @collisionData = new Uint8Array(buffer)
    for i in [0...@width * @height]
      r = imageData.data[i * 4]
      g = imageData.data[i * 4 + 1]
      b = imageData.data[i * 4 + 2]
      a = imageData.data[i * 4 + 3]

      v = 0
      if b > 200 then v += 1
      if r > 200 then v += 2
      if g > 200 then v += 4

      if a < 235 and @colorData.data[i * 4 + 3] == 0
        t = pixelTypes.AIR
      else if r > 20 and r < 200
        t = pixelTypes.PROPERTY
      else if g > 20 and g < 200
        t = pixelTypes.DIRT
      else if v == 2 and r == 255
        t = pixelTypes.MEN
      else if v == 2
        t = pixelTypes.WOMEN
      else
        t = v
      @totalPerType[t]++
      @collisionData[i] = t

  isOccupied: (x, y) ->
    @collisionData[@getIndex(x, y)]

  explode: (x, y, radius, shrapnelExplosiveness, scores, addParticle) ->
    for dy in [-radius..radius]
      ay = y + dy
      for dx in [-radius..radius]
        if dx * dx + dy * dy > radius * radius
          continue
        ax = x + dx
        index = @getIndex(ax, ay)
        type = @collisionData[index]
        if type != pixelTypes.AIR
          scores[type]++
          addParticle
            x: ax,
            y: ay,
            vx: dx + (Math.random() - .5) * 1
            vy: dy + (Math.random() - .5) * 1
            explosiveness: shrapnelExplosiveness
            r: @colorData.data[index * 4 + 0] / 255
            g: @colorData.data[index * 4 + 1] / 255
            b: @colorData.data[index * 4 + 2] / 255
          @collisionData[index] = pixelTypes.AIR
          @colorData.data[index * 4 + 0] = 0
          @colorData.data[index * 4 + 1] = 0
          @colorData.data[index * 4 + 2] = 0
          @colorData.data[index * 4 + 3] = 0
    return

  getIndex: (x, y) ->
    (x + (@height - y - 1) * @width)

Map.pixelTypes = pixelTypes
Map.createEmptyScoresArray = createEmptyScoresArray
