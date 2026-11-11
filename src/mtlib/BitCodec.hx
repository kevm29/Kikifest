// Converti automatiquement depuis lib/BitCodec.mt (Motion Twin)
package mtlib;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class BitCodec {
	public var error_flag : Bool;
	public var nbits : Int;
	public var bits : Int;
	public var data : String;
	public var in_pos : Int;
	public var crc : Int;

	public function new()  untyped {
		setData("");
	}

	public function crcStr()  untyped {
		return c64(crc&63) + c64((crc>>6)&63) + c64((crc>>12)&63) + c64((crc>>18)&63);
	}

	public function setData(d:Dynamic)  untyped {
		error_flag = false;
		data = d;
		in_pos = 0;
		nbits = 0;
		bits = 0;
		crc = 0;
	}

	public function read(n:Dynamic)  untyped {
		while(nbits < n) {
			var c:Dynamic = d64(data?.charAt(in_pos++));
			if( in_pos > data?.length || c == null ) {
				error_flag = true;
				return -1;
			}
			crc ^= c;
			crc &= 0xFFFFFF;
			crc *= c;
			nbits += 6;
			bits <<= 6;
			bits |= c;
		}
		nbits -= n;
		return (bits >> nbits) & ((1 << n) - 1);
	}

	public function nextPart()  untyped {
		nbits = 0;
	}

	public function hasError()  untyped {
		return error_flag;
	}

	public function toString()  untyped {
		if( nbits > 0 )
			write(6-nbits,0);
		return data;
	}

	public function write(n:Dynamic,b:Dynamic)  untyped {
		nbits += n;
		bits <<= n;
		bits |= b;
		var k:Dynamic;
		while(nbits >= 6) {
			nbits -= 6;
			k = (bits >> nbits) & 63;
			crc ^= k;
			crc &= 0xFFFFFF;
			crc *= k;
			data += c64(k);
		}
	}

	public static function ord(code:Dynamic)  untyped {
		return code?.charCodeAt(0);
	}

	public static function chr(code:Dynamic)  untyped {
		return String.fromCharCode(code);
	}

	public static function d64(code:Dynamic)  untyped {
		var chars:Dynamic = "$azAZ_"; // anti obfu
		if( code >= chars?.charAt(1) && code <= chars?.charAt(2) )
			return ord(code) - ord(chars?.charAt(1));
		if( code >= chars?.charAt(3) && code <= chars?.charAt(4) )
			return ord(code) - ord(chars?.charAt(3)) + 26;
		if( code >= "0" && code <= "9" )
			return ord(code) - ord("0") + 52;
		if( code == "-")
			return 62;
		if( code == chars?.charAt(5) )
			return 63;
		return null;
	}

	public static function c64(code:Dynamic)  untyped {
		var chars:Dynamic = "$aA_"; // anti obfu
		if( code < 0 )
			return "?";
		if( code < 26 )
			return chr(code+ord(chars?.charAt(1)));
		if( code < 52 )
			return chr((code-26)+ord(chars?.charAt(2)));
		if( code < 62 )
			return chr((code-52)+ord("0"));
		if( code == 62 )
			return "-";
		if( code == 63 )
			return chars?.charAt(3);
		return "?";
	}

}