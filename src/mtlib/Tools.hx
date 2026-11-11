// Converti automatiquement depuis lib/Tools.mt (Motion Twin)
package mtlib;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class Tools {

	public static function delay( f : Void -> Void, time : Dynamic )  untyped {
		js.Browser.window.setTimeout(f, time);
	}

	public static function replace(str : String,search : String,replace : String)  untyped {
		if( str == null )
			return null;

		var slen:Dynamic = search?.length;
		if( slen == 1 )
			return str?.split(search)?.join(replace);

		var npos:Dynamic, pos:Dynamic = 0;
		var s:Dynamic = "";
		while(true) {
			npos = str?.indexOf(search,pos);
			if( npos == -1 )
				break;
			s += str?.slice(pos,npos)+replace;
			pos = npos + slen;
		}
		return s + str?.substring(pos);
	}

	public static function lines( str : String ) : Array<String>  untyped {
		var i:Dynamic;
		var a:Dynamic = new Array();
		var p:Dynamic = 0;
		var l:Dynamic = str?.length;
		{ i=0; while (i<l) {
			var c:Dynamic = str?.charCodeAt(i);
			if( c == 10 || c == 13 ) {
				a?.push(str?.slice(p,i));
				if( c == 13 && str?.charCodeAt(i+1) == 10 )
					i++;
				p = i + 1;
			}
		
i++; } }
		a?.push(str?.slice(p,i));
		return a;
	}

	public static function shuffle( _a:Dynamic )  untyped {
		var i:Dynamic;
		var a:Dynamic = _a?.duplicate();
		var l:Dynamic = a?.length;
		{ i=0; while (i<l) {
			var p1:Dynamic = MtStd.random(l);
			var p2:Dynamic = MtStd.random(l);
			var s:Dynamic = a[p1];
			a[p1] = a[p2];
			a[p2] = s;
		
i++; } }
		return a;
	}

	public static function rootDelta( mc : MovieClip ) : { dx : Float, dy : Float }  untyped {
		var dx:Dynamic = 0;
		var dy:Dynamic = 0;
		while( mc?._parent != null ) {
			dx += mc?._x;
			dy += mc?._y;
			mc = mc?._parent;
		}
		return { dx : dx, dy : dy };
	}

	public static function padZeros( x : Dynamic, ndigits : Dynamic ) : String  untyped {
		var s:Dynamic = Std.string(x);
		while( s?.length < ndigits )
			s = "0"+s;
		return s;
	}

	public static function randomProbas( a : Array<Int> ) : Int  untyped {
        var n:Dynamic = 0;
        var i:Dynamic;
        { i=a?.length-1; while (i>=0) {n += a[i];
i--; } }
        n = MtStd.random(n);
        i = 0;
        while( n >= a[i] ) {
            n -= a[i];
            i++;
        }
        return i;
	}

	public static function distMC( mc1 : MovieClip, mc2 : MovieClip ) : Float  untyped {
		var b1:Dynamic = mc1?.getBounds(mc1);
		var b2:Dynamic = mc2?.getBounds(mc1);
		var dx:Dynamic = (b1?.xMin + b1?.xMax) / 2 - (b2?.xMin + b2?.xMax) / 2;
		var dy:Dynamic = (b1?.yMin + b1?.yMax) / 2 - (b2?.yMin + b2?.yMax) / 2;
		return Math.sqrt(dx*dx+dy*dy);
	}

	public static function subs( mc : MovieClip ) : Array<MovieClip>  untyped {
		var a:Dynamic = new Array();
		((MtStd):Dynamic)?.forin(mc,function(k) {
			var mc2:Dynamic = (cast (mc))[k];
			if( ((MtStd):Dynamic)?._typeof(mc2) == "movieclip" && mc2?._parent == mc )
				a?.push(mc2);
		});
		return a;
	}

	public static var __x = "$x".substring(1);
	public static var __y = "$y".substring(1);

	public static function localToGlobal( mc : MovieClip, x : Dynamic, y : Dynamic ) : { x : Float, y : Float }  untyped {
		var o:Dynamic = new Hash();
		o?.set(__x,x);
		o?.set(__y,y);
		((mc):Dynamic)?.localToGlobal(o);
		return {
			x : o.get(__x),
			y : o.get(__y)
		};
	}

	public static function globalToLocal( mc : MovieClip, x : Dynamic, y : Dynamic ) : { x : Float, y : Float }  untyped {
		var o:Dynamic = new Hash();
		o?.set(__x,x);
		o?.set(__y,y);
		((mc):Dynamic)?.globalToLocal(o);
		return {
			x : o.get(__x),
			y : o.get(__y)
		};
	}

	public static var strings = null;

	public static function initStrings()  untyped {
		var a:Dynamic = ["$linear","$radial","$matrixType","$box","$x","$y","$w","$h","$r"];
		var i:Dynamic;
		strings = new Array();
		{ i=0; while (i<a?.length) {
			var s:Dynamic = a[i];
			strings[i] = s?.substring(1);
		
i++; } }
	}

	public static function beginGradientFill(
		mc : MovieClip,
		linear : Bool,
		colors : Array<Int>,
		alphas : Array<Int>,
		coefs : Array<Int>,
		matrix : {
			x : Float,
			y : Float,
			w : Float,
			h : Float,
			r : Float
		}
	)  untyped {
		if( strings == null )
			initStrings();
		var m:Dynamic = new Hash();
		m?.set(strings[2],(cast (strings[3])));
		m?.set(strings[4],matrix?.x);
		m?.set(strings[5],matrix?.y);
		m?.set(strings[6],matrix?.w);
		m?.set(strings[7],matrix?.h);
		m?.set(strings[8],matrix?.r);
		((mc):Dynamic)?.beginGradientFill(
			linear?strings[0]:strings[1],
			colors,
			alphas,
			coefs,
			m
		);
	}

}