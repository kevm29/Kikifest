package net.rollback;

/**
	Test de déterminisme en local, sans réseau (équivalent du « SyncTest » de GGPO).

	À chaque frame, le jeu est avancé normalement puis l'état d'il y a
	`rollbackFrames` frames est rechargé et rejoué avec les mêmes touches.
	L'empreinte obtenue doit être identique à celle de la première fois ;
	sinon un champ manque dans `save`/`load`, ou la simulation lit quelque chose
	d'extérieur (horloge, `Math.random`, ordre d'itération d'une Map...).
**/
class SyncTest<S> {
	public var rollbackFrames(default, null):Int;
	public var currentFrame(default, null):Int = 0;

	/** Première frame en erreur, ou -1. **/
	public var firstError(default, null):Int = -1;

	public var errorMessage(default, null):String;

	var game:RollbackGame<S>;
	var states:Array<S> = [];
	var inputs:Array<Array<Int>> = [];
	var checksums:Array<Int> = [];

	public function new(game:RollbackGame<S>, rollbackFrames = 6) {
		this.game = game;
		this.rollbackFrames = rollbackFrames < 1 ? 1 : rollbackFrames;
	}

	/** Avance d'une frame avec les touches des deux joueurs ; renvoie faux en cas d'écart. **/
	public function tick(frameInputs:Array<Int>):Bool {
		var n = rollbackFrames + 1;
		var f = currentFrame;
		states[f % n] = game.save();
		inputs[f % n] = frameInputs.copy();
		game.advance(frameInputs.copy());
		currentFrame++;
		checksums[currentFrame % n] = game.checksum();

		if (currentFrame <= rollbackFrames || firstError >= 0)
			return firstError < 0;

		// Retour en arrière puis rejeu jusqu'au présent.
		var expected = game.checksum();
		var from = currentFrame - rollbackFrames;
		game.load(states[from % n]);
		for (g in from...currentFrame) {
			game.advance(inputs[g % n].copy());
			var c = game.checksum();
			if (c != checksums[(g + 1) % n]) {
				firstError = g;
				errorMessage = 'Désynchro en rejouant la frame $g (frame ${g + 1} : empreinte $c au lieu de ${checksums[(g + 1) % n]})';
				return false;
			}
		}
		if (game.checksum() != expected) {
			firstError = currentFrame - 1;
			errorMessage = 'Désynchro à la frame $currentFrame';
			return false;
		}
		return true;
	}
}
