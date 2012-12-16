class @Map
  constructor: (collisionImage, worldImage) ->
    @canvas = document.createElement('canvas')
    @width = @canvas.width = collisionImage.width;
    @height = @canvas.height = collisionImage.height;
    @context = @canvas.getContext('2d')

    @createCollisionMap collisionImage

    @context.drawImage worldImage, 0, 0
    @colorData = @context.getImageData(0, 0, @width, @height)

  createCollisionMap: (collisionImage) ->
    @context.drawImage collisionImage, 0, 0
    @collisionData = @context.getImageData(0, 0, @width, @height)

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
          addParticle
            x: ax,
            y: ay,
            vx: dx
            vy: dy
            explosive: false
            r: @colorData.data[index] / 255
            g: @colorData.data[index + 1] / 255
            b: @colorData.data[index + 2] / 255
          @collisionData.data[index] = 255
          @colorData.data[index] = 255
          @colorData.data[index + 1] = 255
          @colorData.data[index + 2] = 255
    return

  getIndex: (x, y) ->
    (x + (@height - y - 1) * @width) * 4
