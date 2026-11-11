// Converti automatiquement depuis hammer/gui/SimpleButton.mt (Motion Twin)
package gui;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class SimpleButton extends gui.Item
{
	public var event : Void -> Void;
	public var key : Int;
	public var toggle : Int;
	public var fl_keyLock : Bool;

	public var body : MovieClip;
	public var left : MovieClip;
	public var right : MovieClip;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	public function initButton(c:gui.Container, l:Dynamic, key:Dynamic, func:Dynamic)  untyped {
		init(c,l);

		event = func;
		this.key = key;

		var me:Dynamic = this;
		{ if (body != null) body.onRelease = function() { me?.release(); }; }
		{ if (body != null) body.onRollOut = function() { me?.rollOut(); }; }
		{ if (body != null) body.onRollOver = function() { me?.rollOver(); }; }

		{ if (left != null) left.onRelease = function() { me?.event(); }; }
		{ if (left != null) left.onRollOut = function() { me?.rollOut(); }; }
		{ if (left != null) left.onRollOver = function() { me?.rollOver(); }; }

		{ if (right != null) right.onRelease = function() { me?.event(); }; }
		{ if (right != null) right.onRollOut = function() { me?.rollOut(); }; }
		{ if (right != null) right.onRollOver = function() { me?.rollOver(); }; }


		rollOut();
	}

	/*------------------------------------------------------------------------
	DÉFINI UNE TOUCHE BASCULE EN COMPLÉMENT DE LA KEY
	------------------------------------------------------------------------*/
	public function setToggleKey(k:Dynamic)  untyped {
		toggle = k;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(c:gui.Container, l:String, k:Dynamic, func:Dynamic)  untyped {
		var b : gui.SimpleButton = (( c.depthMan.attach("hammer_editor_button", RootData.DP_INTERF) ):Dynamic);
		b?.initButton(c,l,k, func);
		return b;
	}


	/*------------------------------------------------------------------------
	EVENTS
	------------------------------------------------------------------------*/
	public function release()  untyped {
		if ( !container?.fl_lock ) {
			event();
		}
	}
	public function rollOut()  untyped {
		var f:Dynamic = "1";
		left?.gotoAndStop(f);
		body?.gotoAndStop(f);
		right?.gotoAndStop(f);
	}
	public function rollOver()  untyped {
		var f:Dynamic = "2";
		left?.gotoAndStop(f);
		body?.gotoAndStop(f);
		right?.gotoAndStop(f);
	}


	/*------------------------------------------------------------------------
	DÉFINI LE LABEL
	------------------------------------------------------------------------*/
	override public function setLabel(l:Dynamic)  untyped {
		{ if (field != null) field.text = l; }
		{ if (body != null) body._width = field?.textWidth+5; }
		{ if (right != null) right._x = body?._width; }
		width = left?._width + body?._width + right?._width;
	}

	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LA COMBINAISON DE TOUCHE EST ACTIVÉE
	------------------------------------------------------------------------*/
	public function shortcut():Bool  untyped {
		return
			Key.isDown(key) &&
			( (toggle==null && !Key.isDown(Key.CONTROL) && !Key.isDown(Key.SHIFT)) || Key.isDown(toggle));
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		if ( container?.fl_lock ) {
			return;
		}

		if ( !shortcut() ) {
			fl_keyLock = false;
		}
		if ( shortcut() && !fl_keyLock ) {
			event();
			fl_keyLock = true;
		}
	}


}
