vertexShader = """
#ifdef GL_ES
precision highp float;
#endif

attribute vec3 position;

void main() {
  gl_Position = vec4(position, 1.0);
}
"""

fragmentShader = """
#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
uniform sampler2D diffuseMap;

void main() {
  vec2 normPoint = gl_FragCoord.xy / resolution;
  //gl_FragColor = vec4(normPoint, .0, 1.0);
  vec4 texel = texture2D(diffuseMap, normPoint);
  gl_FragColor = texel;
}
"""

particleVertexShader = """
#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
attribute vec3 position;

void main() {
  gl_Position = vec4(2.0 * (position.xy / resolution - vec2(.5)), .5, 1.0);
  float dummy = position.x + resolution.x;
  //gl_Position = vec4(dummy * 1e-12, .0, .0, 1.0);
  //gl_Position = vec4(.5, .5, .5, 1.0);
}
"""

particleFragmentShader = """
#ifdef GL_ES
precision highp float;
#endif

void main() {
  gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
}
"""

MAX_PARTICLES = 100

glDecorator = (functionName, args) ->
  for ii in [0...args.length]
    if args[ii] == undefined
      throw new Error("undefined passed to gl." + functionName)

class @Graphics

  constructor: (@parentElement) ->

    @canvas = document.createElement 'canvas'
    @gl = null
    @buffer = null

  init: (onFinished) ->
    callbacks = new Callbacks(onFinished)

    @parentElement.appendChild @canvas
    @canvas.width = @parentElement.clientWidth
    @canvas.height = @parentElement.clientHeight

    gl = @canvas.getContext('experimental-webgl') || @canvas.getContext('webgl')
    if not gl
      throw type: 'NoWebGL', message: 'WebGL not supported'

    WebGLDebugUtils.init gl
    gl = WebGLDebugUtils.makeDebugContext(gl, undefined, glDecorator)

    @gl = gl
    @updateSize @canvas.width, @canvas.height

    # BACKGROUND

    @backgroundQuadBuffer = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @backgroundQuadBuffer
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array(
      [ -1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0 ]
    ), gl.STATIC_DRAW

    @backgroundProgram = @createProgram(vertexShader, fragmentShader,
      uniforms: [
        'resolution',
        'diffuseMap',
      ],
      attributes: [
        'position',
      ]
    )
    gl.enableVertexAttribArray @backgroundProgram.attributes.position

    # PARTICLES
    @particlesBuffer = gl.createBuffer()
    @particlesArray = new Float32Array(MAX_PARTICLES * 6)

    @particlesProgram = @createProgram(particleVertexShader, particleFragmentShader,
      uniforms: ['resolution'],
      attributes: ['position']
    )
    #gl.useProgram @particlesProgram.handle
    gl.enableVertexAttribArray @particlesProgram.attributes.position

    # TEXTURES

    @texture = gl.createTexture()
    gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, true
    image = new Image()
    image.src = 'assets/level.png'
    image.onload = callbacks.add =>
      gl.bindTexture gl.TEXTURE_2D, @texture
      gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST
      #gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
      #gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
      #gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST
      #gl.generateMipmap gl.TEXTURE_2D

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
      if program.uniforms[name] == -1
        throw new Error("Could not get attribute #{name}")

    return program

  updateSize: (width, height) ->
    @canvas.width = width;
    @canvas.height = height;
    @gl.viewport 0, 0, @canvas.width, @canvas.height

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
    gl.clearColor .1, 0.5, .5, 1.0
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT

    gl.disable gl.CULL_FACE

    gl.useProgram @backgroundProgram.handle
    gl.uniform2f @backgroundProgram.uniforms.resolution, @canvas.width, @canvas.height

    gl.bindBuffer gl.ARRAY_BUFFER, @backgroundQuadBuffer
    gl.vertexAttribPointer @backgroundProgram.attributes.position, 2, gl.FLOAT, false, 0, 0
    gl.drawArrays gl.TRIANGLES, 0, 6

    #console.log 'drawing', particles.length

    angle0 = Math.PI * 2 / 3 * 0
    angle1 = Math.PI * 2 / 3 * 1
    angle2 = Math.PI * 2 / 3 * 2

    gl.bindBuffer gl.ARRAY_BUFFER, @particlesBuffer
    i = 0
    arr = @particlesArray
    r = 1
    for particle in particles
      arr[i++] = particle.x + r * Math.sin(angle0)
      arr[i++] = particle.y + r * Math.cos(angle0)
      arr[i++] = particle.x + r * Math.sin(angle1)
      arr[i++] = particle.y + r * Math.cos(angle1)
      arr[i++] = particle.x + r * Math.sin(angle2)
      arr[i++] = particle.y + r * Math.cos(angle2)

    gl.bufferData gl.ARRAY_BUFFER, @particlesArray, gl.STATIC_DRAW

    gl.useProgram @particlesProgram.handle
    gl.uniform2f @particlesProgram.uniforms.resolution, @canvas.width, @canvas.height

    gl.bindBuffer gl.ARRAY_BUFFER, @particlesBuffer
    gl.bufferData gl.ARRAY_BUFFER, @particlesArray, gl.STATIC_DRAW
    gl.vertexAttribPointer @particlesProgram.attributes.position, 2, gl.FLOAT, false, 0, 0
    gl.drawArrays gl.TRIANGLES, 0, particles.length * 3

    error = gl.getError()
    if error
      throw new Error("GL error: #{error}")
