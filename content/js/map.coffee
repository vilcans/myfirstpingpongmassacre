pixelTypes =
  AIR: 0,
  DIRT: 1,
  BUILDING: 2,

class @Map
  constructor: (collisionImage, worldImage) ->
    @canvas = document.createElement('canvas')
    @width = @canvas.width = collisionImage.width;
    @height = @canvas.height = collisionImage.height;
    @context = @canvas.getContext('2d')

    @createCollisionMap collisionImage

    @context.clearRect 0, 0, @width, @height
    @context.drawImage worldImage, 0, 0
    @colorData = @context.getImageData(0, 0, @width, @height)

  createCollisionMap: (collisionImage) ->
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
      if a < 128
        t = pixelTypes.AIR
      else if g > r
        t = pixelTypes.DIRT
      else
        t = pixelTypes.BUILDING
      @collisionData[i] = t

  isOccupied: (x, y) ->
    v = @collisionData[@getIndex(x, y)]
    return v != pixelTypes.AIR

  explode: (x, y, radius, shrapnelExplosiveness, addParticle) ->
    for dy in [-radius..radius]
      ay = y + dy
      for dx in [-radius..radius]
        if dx * dx + dy * dy > radius * radius
          continue
        ax = x + dx
        index = @getIndex(ax, ay)
        if @collisionData[index] != pixelTypes.AIR
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
