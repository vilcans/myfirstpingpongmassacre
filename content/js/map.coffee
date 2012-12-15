class @Map
  constructor: (collisionImage) ->
    @image = collisionImage
    @createCollisionMap collisionImage

  createCollisionMap: (image) ->
    @canvas = canvas = document.createElement('canvas')
    @width = canvas.width = image.width;
    @height = canvas.height = image.height;
    context = canvas.getContext('2d')
    context.drawImage image, 0, 0
    @collisionData = context.getImageData(0, 0, image.width, image.height)

  isOccupied: (x, y) ->
    # Data is in order RGBA
    v = @collisionData.data[@getIndex(x, y)]
    return v < 128

  explode: (x, y, radius, addParticle) ->
    for dy in [-radius..radius]
      ay = y + dy
      for dx in [-radius..radius]
        ax = x + dx
        index = @getIndex(ax, ay)
        if @collisionData.data[index] < 128
          console.log 'addParticle', ax, ay, dx, dy
          addParticle ax, ay, dx, dy
          @collisionData.data[index] = 255
    return

  getIndex: (x, y) ->
    (x + (@height - y - 1) * @width) * 4
