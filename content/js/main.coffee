$(document).ready ->
  gameElement = document.getElementById('game')
  try
    @game = new Game
      parentElement: gameElement
      eventsElement: gameElement
    @game.init =>
      @game.start()
  catch e
    if e.type == 'NoWebGL'
      $('#no-webgl').show()
      Tracking.trackEvent 'init', 'no-webgl', nonInteraction: true
    else
      Tracking.trackEvent 'init', 'exception', label: "#{e}", nonInteraction: true
      console.error e
