gameElement = document.getElementById('game')
@game = new Game
	parentElement: gameElement
	eventsElement: gameElement
@game.init ->
	@game.start()
