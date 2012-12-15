class @Map
  constructor: (collisionImage) ->
    @createCollisionMap(collisionImage)

  createCollisionMap: (image) ->
    canvas = document.createElement('canvas')
    canvas.width = image.width;
    canvas.height = image.height;
    context = canvas.getContext('2d')
    context.drawImage image, 0, 0
    @collisionData = context.getImageData(0, 0, image.width, image.height)

  isOccupied: (x, y) ->
    # Data is in order RGBA
    v = @collisionData.data[(x + (@collisionData.height - y - 1) * @collisionData.width) * 4]
    return v < 128


      # canvas = document.createElement('canvas')
      # canvas.width = image.width;
      # canvas.height = image.height;
      # context = canvas.getContext('2d')
      # context.drawImage image, 0, 0
      # @collisionData = context.getImageData(0, 0, image.width, image.height)
