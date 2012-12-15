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

class @Graphics

  constructor: (@parentElement) ->

    @canvas = document.createElement 'canvas'
    @gl = null
    @buffer = null
    @uniforms = {}

  init: (onFinished) ->
    callbacks = new Callbacks(onFinished)

    @parentElement.appendChild @canvas
    @canvas.width = @parentElement.clientWidth
    @canvas.height = @parentElement.clientHeight

    gl = @gl = @canvas.getContext('experimental-webgl') || @canvas.getContext('webgl')
    if not gl
      throw type: 'NoWebGL', message: 'WebGL not supported'

    # Create vertex buffer (2 triangles)
    @vertexBuffer = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexBuffer
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array(
      [ -1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0 ]
    ), gl.STATIC_DRAW

    @updateSize @canvas.width, @canvas.height

    program = gl.createProgram()
    vs = @createShader(vertexShader, gl.VERTEX_SHADER)
    fs = @createShader(fragmentShader, gl.FRAGMENT_SHADER)
    gl.attachShader program, vs
    gl.attachShader program, fs
    #gl.deleteShader vs
    #gl.deleteShader fs
    gl.linkProgram program
    if not gl.getProgramParameter(program, gl.LINK_STATUS)
      error = gl.getProgramInfoLog program
      throw new Error('Linking failed: ' + error)

    @uniforms.resolution = gl.getUniformLocation(program, 'resolution')

    @program = program
    gl.useProgram @program

    @vertexPosition = gl.getAttribLocation(program, 'position')
    gl.enableVertexAttribArray @vertexPosition

    @uniforms.diffuseMap = gl.getUniformLocation(program, 'diffuseMap')

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

  render: ->
    gl = @gl
    gl.clearColor .1, 0.5, .5, 1.0
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT

    gl.useProgram @program
    gl.uniform2f @uniforms.resolution, @canvas.width, @canvas.height

    gl.bindBuffer gl.ARRAY_BUFFER, @vertexBuffer
    gl.vertexAttribPointer @vertexPosition, 2, gl.FLOAT, false, 0, 0

    @gl.drawArrays gl.TRIANGLES, 0, 6
