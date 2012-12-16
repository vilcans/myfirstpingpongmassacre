vertexShader = """
#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
attribute vec3 position;
attribute vec2 textureCoordinates;
varying vec2 v_textureCoordinates;

void main() {
  gl_Position = vec4(2.0 * (position.xy / resolution - vec2(.5)), .5, 1.0);
  v_textureCoordinates = textureCoordinates;
}
"""

fragmentShader = """
#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
uniform sampler2D diffuseMap;
varying vec2 v_textureCoordinates;

void main() {
  //vec2 normPoint = gl_FragCoord.xy / resolution;
  //vec4 texel = texture2D(diffuseMap, normPoint);
  vec4 texel = texture2D(diffuseMap, v_textureCoordinates);
  //vec4 texel = vec4(v_textureCoordinates, .2, 1.0);
  gl_FragColor = texel;
}
"""

particleVertexShader = """
#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
attribute vec3 position;
attribute vec3 color;
varying vec3 v_color;

void main() {
  gl_Position = vec4(2.0 * (position.xy / resolution - vec2(.5)), .5, 1.0);
  float dummy = position.x + resolution.x;
  //gl_Position = vec4(dummy * 1e-12, .0, .0, 1.0);
  //gl_Position = vec4(.5, .5, .5, 1.0);
  v_color = color;
}
"""

particleFragmentShader = """
#ifdef GL_ES
precision highp float;
#endif

varying vec3 v_color;

void main() {
  //gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
  gl_FragColor = vec4(v_color, 1.0);
}
"""

sizeOfFloat = 4

particleRadius = Math.sqrt(2) * 2
numberOfParticleSegments = 4
floatsPerParticle = 5 * 6   # xyrgb * 6 vertices

particleCoordsX = []
particleCoordsY = []
for i in [0...numberOfParticleSegments]
  angle = Math.PI * 2 / numberOfParticleSegments * (i + .5)
  particleCoordsX[i] = Math.sin(angle) * particleRadius
  particleCoordsY[i] = Math.cos(angle) * particleRadius

MAX_PARTICLES = 1000

glDecorator = (functionName, args) ->
  for ii in [0...args.length]
    if args[ii] == undefined
      throw new Error("undefined passed to gl." + functionName)

class @Graphics

  constructor: (@parentElement) ->

    @canvas = document.createElement 'canvas'
    @gl = null
    @buffer = null
    @tempVec2 = vec2.create()
    @mat2Identity = mat2.identity()
    @cannonAngle = 0

    r = tweaks.calibre
    h = tweaks.cannonLength
    @cannonPoints = [
      vec2.createFrom(-r, 0),
      vec2.createFrom( r, 0),
      vec2.createFrom(-r, h),
      vec2.createFrom( r, 0),
      vec2.createFrom( r, h),
      vec2.createFrom(-r, h),
    ]

  init: (onFinished) ->
    callbacks = new Callbacks(onFinished)

    @parentElement.appendChild @canvas
    @width = @canvas.width = @parentElement.clientWidth
    @height = @canvas.height = @parentElement.clientHeight

    contextAttributes = {}
      #premultipliedAlpha: false
    gl = @canvas.getContext('experimental-webgl', contextAttributes)

    if not gl
      gl = @canvas.getContext('webgl', contextAttributes)
    if not gl
      throw type: 'NoWebGL', message: 'WebGL not supported'

    if window.location.search == '?debug'
      WebGLDebugUtils.init gl
      gl = WebGLDebugUtils.makeDebugContext(gl, undefined, glDecorator)

    @gl = gl

    gl.enable gl.BLEND
    gl.blendFunc gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA

    # gl.enable(gl.BLEND);
    # gl.disable(gl.DEPTH_TEST);
    # gl.disable(gl.CULL_FACE);
    # gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);


    @updateSize @canvas.width, @canvas.height

    # BACKGROUND

    @backgroundQuadBuffer = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @backgroundQuadBuffer
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array([
      # x, y, u, v
      0, 0,   0, 0,
      1, 0,   1, 0,
      0, 1,   0, 1,
      1, 0,   1, 0,
      1, 1,   1, 1,
      0, 1,   0, 1,
    ]), gl.STATIC_DRAW

    @backgroundProgram = @createProgram(vertexShader, fragmentShader,
      uniforms: [
        'resolution',
        'diffuseMap',
      ],
      attributes: [
        'position',
        'textureCoordinates',
      ]
    )

    # PARTICLES
    @particlesBuffer = gl.createBuffer()
    @particlesArray = new Float32Array(MAX_PARTICLES * floatsPerParticle)

    @particlesProgram = @createProgram(particleVertexShader, particleFragmentShader,
      uniforms: ['resolution'],
      attributes: [
        'position',
        'color'
      ]
    )

    # TEXTURES

    @texture = gl.createTexture()
    gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, true
    @worldImage = new Image()
    @worldImage.src = 'assets/level.png'
    @worldImage.onload = callbacks.add =>
      gl.bindTexture gl.TEXTURE_2D, @texture
      gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, @worldImage
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST
      #gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
      #gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
      #gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST
      #gl.generateMipmap gl.TEXTURE_2D

    @collisionImage = new Image()
    @collisionImage.src = 'assets/collision.png'
    @collisionImage.onload = callbacks.add =>
      console.log 'collision map loaded'

    @atlasTexture = gl.createTexture()
    @atlasImage = new Image()
    @atlasImage.src = 'assets/atlas.png'
    @atlasImage.onload = callbacks.add =>
      console.log 'cannon loaded'
      gl.bindTexture gl.TEXTURE_2D, @atlasTexture
      gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, @atlasImage
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR

    # CANNON
    @cannonBuffer = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @cannonBuffer
    radius = tweaks.cannonSize[0] / 2  # radius of the cannon dome
    left = tweaks.cannonPosition[0] - radius
    right = left + tweaks.cannonSize[0]
    top = tweaks.cannonPosition[1] + radius
    bottom = top - tweaks.cannonSize[1]
    @cannonArray = new Float32Array([
      # cannon
      # x, y, u, v  (x and y are filled in by updateCannonVertices)
      0, 0 , 0, .5,
      0, 0 , 1, .5,
      0, 0 , 0, 1,
      0, 0 , 1, .5,
      0, 0 , 1, 1
      0, 0 , 0, 1,

      # base
      left, bottom,   0, 0,
      right, bottom,  1, 0,
      left, top,      0, .5,
      right, bottom,  1, 0,
      right, top,     1, .5,
      left, top,      0, .5,
    ])
    @updateCannonVertices()

  updateCannonVertices: ->
    rotated = @tempVec2
    rotation = mat2.create()
    mat2.rotate @mat2Identity, @cannonAngle - Math.PI / 2, rotation

    for p, i in @cannonPoints
      mat2.multiplyVec2 rotation, p, rotated
      @cannonArray[i * 4 +  0] = rotated[0] + tweaks.cannonPosition[0]
      @cannonArray[i * 4 +  1] = rotated[1] + tweaks.cannonPosition[1]

    gl = @gl
    gl.bindBuffer gl.ARRAY_BUFFER, @cannonBuffer
    gl.bufferData gl.ARRAY_BUFFER, @cannonArray, gl.STATIC_DRAW

  setCannonAngle: (angle) ->
    @cannonAngle = angle
    @updateCannonVertices()

  createProgram: (vertexShader, fragmentShader, {uniforms, attributes}) ->
    gl = @gl
    handle = gl.createProgram()
    vs = @createShader(vertexShader, gl.VERTEX_SHADER)
    fs = @createShader(fragmentShader, gl.FRAGMENT_SHADER)
    gl.attachShader handle, vs
    gl.attachShader handle, fs
    #gl.deleteShader vs
    #gl.deleteShader fs
    gl.linkProgram handle
    if not gl.getProgramParameter(handle, gl.LINK_STATUS)
      error = gl.getProgramInfoLog handle
      throw new Error('Linking failed: ' + error)

    program =
      handle: handle
      uniforms: {}
      attributes: {}

    for name in uniforms or []
      program.uniforms[name] = gl.getUniformLocation(handle, name)
      if program.uniforms[name] == -1
        throw new Error("Could not get uniform #{name}")

    for name in attributes or []
      program.attributes[name] = gl.getAttribLocation(handle, name)
      if program.attributes[name] == -1
        throw new Error("Could not get attribute #{name}")

    return program

  updateSize: (width, height) ->
    @canvas.width = width;
    @canvas.height = height;
    @gl.viewport 0, 0, @canvas.width, @canvas.height

  updateBackground: (imageData) ->
    gl = @gl
    gl.bindTexture gl.TEXTURE_2D, @texture
    gl.texSubImage2D(
      gl.TEXTURE_2D,  # target
      0,  # level
      0, 0,  # xoffset, yoffset
      gl.RGBA,  # format
      gl.UNSIGNED_BYTE  # type
      imageData
    )

  createShader: (source, type) ->
    gl = @gl
    shader = gl.createShader(type)
    gl.shaderSource shader, source
    gl.compileShader shader
    if not gl.getShaderParameter(shader, gl.COMPILE_STATUS)
      error = gl.getShaderInfoLog(shader)
      throw new Error("compile failed: #{error}")
    return shader

  animate: ->

  render: (particles) ->
    gl = @gl
    gl.clearColor .0, .0, .0, .0
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT
    gl.disable gl.CULL_FACE

    @renderCannon()
    @renderWorld()

    if particles.length
      @renderParticles particles

  renderWorld: ->
    gl = @gl
    gl.useProgram @backgroundProgram.handle

    gl.activeTexture gl.TEXTURE0
    gl.bindTexture gl.TEXTURE_2D, @texture
    gl.uniform1i @backgroundProgram.uniforms.diffuseMap, 0

    gl.enableVertexAttribArray @backgroundProgram.attributes.position
    gl.enableVertexAttribArray @backgroundProgram.attributes.textureCoordinates

    gl.uniform2f @backgroundProgram.uniforms.resolution, 1, 1

    gl.bindBuffer gl.ARRAY_BUFFER, @backgroundQuadBuffer
    gl.vertexAttribPointer @backgroundProgram.attributes.position, 2, gl.FLOAT, false, 4 * sizeOfFloat, 0
    gl.vertexAttribPointer @backgroundProgram.attributes.textureCoordinates, 2, gl.FLOAT, false, 4 * sizeOfFloat, 2 * sizeOfFloat
    gl.drawArrays gl.TRIANGLES, 0, 6

  renderCannon: ->
    gl = @gl
    gl.useProgram @backgroundProgram.handle

    gl.activeTexture gl.TEXTURE0
    gl.bindTexture gl.TEXTURE_2D, @atlasTexture
    gl.uniform1i @backgroundProgram.uniforms.diffuseMap, 0

    gl.enableVertexAttribArray @backgroundProgram.attributes.position
    gl.enableVertexAttribArray @backgroundProgram.attributes.textureCoordinates

    gl.uniform2f @backgroundProgram.uniforms.resolution, @canvas.width, @canvas.height

    gl.bindBuffer gl.ARRAY_BUFFER, @cannonBuffer
    gl.vertexAttribPointer @backgroundProgram.attributes.position, 2, gl.FLOAT, false, 4 * sizeOfFloat, 0
    gl.vertexAttribPointer @backgroundProgram.attributes.textureCoordinates, 2, gl.FLOAT, false, 4 * sizeOfFloat, 2 * sizeOfFloat
    gl.drawArrays gl.TRIANGLES, 0, @cannonArray.length / 4

  renderParticles: (particles) ->
    gl = @gl
    i = 0
    arr = @particlesArray
    vertexCount = 0
    for particleIndex in [Math.max(0, particles.length - MAX_PARTICLES)...particles.length]
      particle = particles[particleIndex]
      arr[i++] = particle.x + particleCoordsX[0]
      arr[i++] = particle.y + particleCoordsY[0]
      arr[i++] = particle.r
      arr[i++] = particle.g
      arr[i++] = particle.b
      arr[i++] = particle.x + particleCoordsX[1]
      arr[i++] = particle.y + particleCoordsY[1]
      arr[i++] = particle.r
      arr[i++] = particle.g
      arr[i++] = particle.b
      arr[i++] = particle.x + particleCoordsX[2]
      arr[i++] = particle.y + particleCoordsY[2]
      arr[i++] = particle.r
      arr[i++] = particle.g
      arr[i++] = particle.b
      arr[i++] = particle.x + particleCoordsX[0]
      arr[i++] = particle.y + particleCoordsY[0]
      arr[i++] = particle.r
      arr[i++] = particle.g
      arr[i++] = particle.b
      arr[i++] = particle.x + particleCoordsX[2]
      arr[i++] = particle.y + particleCoordsY[2]
      arr[i++] = particle.r
      arr[i++] = particle.g
      arr[i++] = particle.b
      arr[i++] = particle.x + particleCoordsX[3]
      arr[i++] = particle.y + particleCoordsY[3]
      arr[i++] = particle.r
      arr[i++] = particle.g
      arr[i++] = particle.b
      vertexCount += 6
    floatCount = i

    gl.useProgram @particlesProgram.handle

    gl.enableVertexAttribArray @particlesProgram.attributes.position
    gl.enableVertexAttribArray @particlesProgram.attributes.color

    gl.uniform2f @particlesProgram.uniforms.resolution, @canvas.width, @canvas.height

    gl.bindBuffer gl.ARRAY_BUFFER, @particlesBuffer
    gl.bufferData gl.ARRAY_BUFFER, @particlesArray, gl.STATIC_DRAW
    #gl.bufferData gl.ARRAY_BUFFER, @particlesArray.subarray(0, floatCount), gl.STATIC_DRAW
    #gl.bufferSubData gl.ARRAY_BUFFER, 0, @particlesArray.subarray(0, vertexCount * 2)
    gl.vertexAttribPointer @particlesProgram.attributes.position, 2, gl.FLOAT, false, 5 * sizeOfFloat, 0
    gl.vertexAttribPointer @particlesProgram.attributes.color, 3, gl.FLOAT, false, 5 * sizeOfFloat, 2 * sizeOfFloat
    gl.drawArrays gl.TRIANGLES, 0, vertexCount

    gl.disableVertexAttribArray @particlesProgram.attributes.position
    gl.disableVertexAttribArray @particlesProgram.attributes.color
