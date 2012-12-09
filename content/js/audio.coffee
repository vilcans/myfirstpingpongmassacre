# Map soundclip name to <audio> element
elements = {}

load = (name) ->
  console.log 'loading', name
  element = document.createElement 'audio'
  element.preload = 'auto'

  oggSource = document.createElement 'source'
  oggSource.src = "assets/audio/#{name}.ogg"
  oggSource.type = 'audio/ogg'
  element.appendChild oggSource

  mp3Source = document.createElement 'source'
  mp3Source.src = "assets/audio/#{name}.mp3"
  mp3Source.type = 'audio/mpeg'
  element.appendChild mp3Source

  elements[name] = element
  return element

window.Audio =
  preload: (name) ->
    element = elements[name]
    if element
      console.log "#{name} is already loaded"
    else
      element = load(name)
    return element

  play: (name) ->
    try
      element = elements[name]
      if not element
        element = load(name)
      else if element.ended or element.played.length == 0
        #console.log 'reusing ended/unplayed sound'
      else
        #console.log 'cloning'
        # In Firefox, the audio data won't have to be downloaded again.
        # Chrome downloads it.
        element = element.cloneNode(true)

      element.play()
      return element
    catch e
      console.log 'play failed:', e
