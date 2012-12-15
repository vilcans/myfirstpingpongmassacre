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

  init: (onFinished) ->
    callbacks = new Callbacks(onFinished)

    @parentElement.appendChild @canvas
    @canvas.width = @parentElement.clientWidth
    @canvas.height = @parentElement.clientHeight

    gl = @gl = @canvas.getContext('experimental-webgl') || @canvas.getContext('webgl')
    if not gl
      throw type: 'NoWebGL', message: 'WebGL not supported'

    # Create vertex buffer (2 triangles)
    @backgroundQuadBuffer = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @backgroundQuadBuffer
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array(
      [ -1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0 ]
    ), gl.STATIC_DRAW


    @updateSize @canvas.width, @canvas.height

    @program = program = @createProgram(vertexShader, fragmentShader,
      uniforms: [
        'resolution',
        'diffuseMap',
      ],
      attributes: [
        'position',
      ]
    )
    gl.enableVertexAttribArray @program.attributes.position

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

  render: ->
    gl = @gl
    gl.clearColor .1, 0.5, .5, 1.0
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT

    gl.useProgram @program.handle
    gl.uniform2f @program.uniforms.resolution, @canvas.width, @canvas.height

    gl.bindBuffer gl.ARRAY_BUFFER, @backgroundQuadBuffer
    gl.vertexAttribPointer @program.attributes.position, 2, gl.FLOAT, false, 0, 0
    @gl.drawArrays gl.TRIANGLES, 0, 6
