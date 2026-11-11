// Converti automatiquement depuis lib/PersistCodec.mt (Motion Twin)
package mtlib;

import swf.*;
import mtlib.*;
using mtlib.StringExt;

class PersistCodec {

	/*
		TYPE-BITS =

		- number
			int 	00
			float	010
			NaN		0110
			+Inf	01110
			-Inf	01111

		- array		100
		- object	101
		- boolean
			true	1101
			false	1100

		- string	1110

		- undefined 1111

		DATA =

		- int
			normal	NN [XX|XX|XX]  : 2 bits + 2-6 bits
			medium	1100 + 16 bits
			big		1101 + 32 bits
			negatif 111 + int

		- float
			as a string with :
			string length	5
			character		4
				number 0-9
				dot     10
				plus    11
				minus   12
				exp     13

		- array
			element	0
			jump	10 + int
			end		11

		- object
			key
				0 + index
				10 + string
			end
				11

		- string
			extended	11
			ASCII		10
			B64			0
			len			int
			chars		 7/8


	*/

	public var obfu_mode : Bool;


	public var bc : BitCodec;
	public var fields : Hash<Int>;
	public var fieldtbl : Array<String>;
	public var nfields : Int;
	public var next_field_bits : Int;
	public var nfields_bits : Int;
	public var cache : Array<Dynamic>;
	public var result : Dynamic;
	public var fast : Bool;
	public var crc : Bool;

	public function new()  untyped {
		obfu_mode = false;
		crc = false;
	}

	public function encode_array(a:Dynamic)  untyped {
		var i:Dynamic;
		var njumps:Dynamic = 0;
		{ i=0; while (i<a?.length) {
			if( a[i] == null )
				njumps++;
			else {
				if( njumps > 0 ) {
					bc?.write(2,2);
					encode_int(njumps);
					njumps = 0;
				}
				bc?.write(1,0);
				do_encode(a[i]);
			}
		
i++; } }
		bc?.write(2,3);
	}

	public function decode_array()  untyped {
		var a:Dynamic = new Array();
		{ if (((a):Dynamic) != null) ((a):Dynamic).pos = 0; }
		cache?.unshift((cast (a)));
		return (cast (a));
	}

	public function decode_array_item(a:Dynamic)  untyped {
		var elt:Dynamic = (bc?.read(1) == 0);
		if( elt )
			a[a.pos++] = do_decode();
		else {
			var exit:Dynamic = (bc?.read(1) == 1);
			if( exit )
				return false;
			{ if (((a):Dynamic) != null) ((a):Dynamic).pos += decode_int(); }
		}
		return true;
	}

	public function decode_array_fast()  untyped {
		var a:Dynamic = new Array();
		var pos:Dynamic = 0;
		while( true ) {
			var elt:Dynamic = (bc?.read(1) == 0);
			if( elt )
				a[pos++] = do_decode();
			else {
				var exit:Dynamic = (bc?.read(1) == 1);
				if( exit )
					break;
				pos += decode_int();
			}
			if( bc?.error_flag )
				break;
		}
		return (cast (a));
	}

	public function encode_string(s:Dynamic)  untyped {
		var is_b64:Dynamic = true;
		var is_ascii:Dynamic = true;
		var i:Dynamic;
		{ i=0; while (i<s?.length) {
			if( s?.charCodeAt(i) > 127 ) {
				is_b64 = false;
				is_ascii = false;
				break;
			} else if( is_b64 ) {
				var c:Dynamic = s?.charAt(i);
				if( BitCodec.d64(c) == null )
					is_b64 = false;
			}
	 	
i++; } }
	 	encode_int(s?.length);
		if( is_b64 ) {
			bc?.write(1,0);
			{ i=0; while (i<s?.length) {bc?.write(6,BitCodec.d64(s?.charAt(i)));
i++; } }
 		} else {
			bc?.write(2,is_ascii?2:3);
			{ i=0; while (i<s?.length) {bc?.write(is_ascii?7:8,s?.charCodeAt(i));
i++; } }
		}
	}

	public function decode_string()  untyped {
		var len:Dynamic = decode_int();
		var is_b64:Dynamic = (bc?.read(1) == 0);
		var s:Dynamic = "";
		var i:Dynamic;
		if( is_b64 ) {
			{ i=0; while (i<len) {s += BitCodec.c64(bc?.read(6));
i++; } }
		} else {
			var is_ascii:Dynamic = (bc?.read(1) == 0);
			{ i=0; while (i<len) {s += BitCodec.chr(bc?.read(is_ascii?7:8));
i++; } }
		}
		return (cast (s));
	}

	public function encode_object(o:Dynamic)  untyped {
		var me:Dynamic = this;
		((MtStd):Dynamic)?.forin(o,function(k) { me?.encode_object_field(k,(cast (o))[(cast (k))]); });
		bc?.write(2,3);
	}

	public function encode_object_field(k:Dynamic,d:Dynamic)  untyped {
		if( ((MtStd):Dynamic)?._typeof(d) != "function" && d != null ) {
			if( obfu_mode && k?.charAt(0) == "$" )
				k = k?.substring(1);
			if( fields?.get(k) != null ) {
				bc?.write(1,0);
				bc?.write(nfields_bits,fields?.get(k));
			} else {
				fields?.set(k,nfields++);
				if( nfields >= next_field_bits ) {
					nfields_bits++;
					next_field_bits *= 2;
				}
				bc?.write(2,2);
				encode_string(k);
			}
			do_encode(d);
		}
	}

	public function decode_object_fast()  untyped {
		var o:Dynamic = (({}):Dynamic);
		while( true ) {
			var k:Dynamic;
			var is_field_index:Dynamic = (bc?.read(1) == 0);
			if( is_field_index )
				k = fieldtbl[bc?.read(nfields_bits)];
			else {
				var is_end:Dynamic = (bc?.read(1) == 1);
				if( is_end )
					break;
				k = decode_string();
				if( obfu_mode && k?.charAt(0) != "$" )
					k = "$"+k;
				fieldtbl[nfields++] = k;
				if( nfields >= next_field_bits ) {
					nfields_bits++;
					next_field_bits *= 2;
				}
			}
			o[(cast (k))] = do_decode();
			if( bc?.error_flag )
				break;
		}
		return (cast (o));
	}


	public function decode_object()  untyped {
		var o:Dynamic = (cast ({}));
		cache?.unshift(o);
		return (cast (o));
	}

	public function decode_object_field(o:Dynamic)  untyped {
		var k:Dynamic;
		var is_field_index:Dynamic = (bc?.read(1) == 0);

		if( is_field_index )
			k = fieldtbl[bc?.read(nfields_bits)];
		else {
			var is_end:Dynamic = (bc?.read(1) == 1);
			if( is_end )
				return false;
			k = decode_string();
			if( obfu_mode && k?.charAt(0) != "$" )
				k = "$"+k;
			fieldtbl[nfields++] = k;
			if( nfields >= next_field_bits ) {
				nfields_bits++;
				next_field_bits *= 2;
			}
		}
		o[(cast (k))] = do_decode();
		return true;
	}

	public function encode_int(o : Dynamic)  untyped {
		if( o < 0 ) {
			bc?.write(3,7);
			encode_int(-o);
		} else if( o < 4 ) {
			bc?.write(2,0);
			bc?.write(2,o);
		} else if( o < 16 ) {
			bc?.write(2,1);
			bc?.write(4,o);
		} else if( o < 64 ) {
			bc?.write(2,2);
			bc?.write(6,o);
		} else if( o < 65536 ) {
			bc?.write(4,12);
			bc?.write(16,o);
		} else {
			bc?.write(4,13);
			bc?.write(16,o & 0xFFFF);
			bc?.write(16,(o >> 16) & 0xFFFF);
		}
	}

	public function decode_int() : Dynamic  untyped {
		var nbits:Dynamic = bc?.read(2);
		if( nbits == 3 ) {
			var is_neg:Dynamic = (bc?.read(1) == 1);
			if( is_neg )
				return (cast ( -decode_int() ));
			var is_big:Dynamic = (bc?.read(1) == 1);
			if( is_big ) {
				var n:Dynamic = bc?.read(16);
				var n2:Dynamic = bc?.read(16);
				return (cast ( n | (n2 << 16) ));
			} else
				return (cast ( bc.read(16) ));
		}
		var i:Dynamic = bc?.read((nbits+1)*2);
		return (cast (i));
	}

	public function encode_float(o:Dynamic)  untyped {
		var s:Dynamic = Std.string(o);
		var l:Dynamic = s?.length;
		var i:Dynamic;
		bc?.write(5,l);
		{ i=0; while (i<l) {
			var c:Dynamic = s?.charCodeAt(i);
			if( c >= 48 && c <= 58 ) // 0 - 9
				bc?.write(4,c-48);
			else if( c == 46 ) // '.'
				bc?.write(4,10);
			else if( c == 43 ) // '+'
				bc?.write(4,11);
			else if( c == 45 ) // '-'
				bc?.write(4,12);
			else // 'e'
				bc?.write(4,13);
		
i++; } }
	}

	public function decode_float()  untyped {
		var l:Dynamic = bc?.read(5);
		var i:Dynamic;
		var s:Dynamic = "";
		{ i=0; while (i<l) {
			var k:Dynamic = bc?.read(4);
			if( k < 10 )
				k += 48;
			else switch( k ) {
			case 10: k = 46; break;
			case 11: k = 43; break;
			case 12: k = 45; break;
			default: k = 101; break;
			}
			s += String.fromCharCode(k);
		
i++; } }
		return MtStd.getGlobal("parseFloat")(s);
	}

	public function do_encode(o : Dynamic) : Bool  untyped {
		if( o == null )
			bc?.write(4,15);
		else if( ((MtStd):Dynamic)?._instanceof(o,Array) ) {
			bc?.write(3,4);
			encode_array((cast (o)));
		} else { var __sw:Dynamic = ((MtStd):Dynamic)?._typeof(o);
if (__sw == ("string")) {
			bc.write(4,14);
			encode_string((cast (o)));
			
		}
else if (__sw == ("number")) {
			var n:Dynamic = (cast (o));
			if( MtStd.isNaN(n) )
				bc?.write(4,6);
			else if( n == ((MtStd):Dynamic)?.infinity )
				bc?.write(5,14);
			else if( n == -((MtStd):Dynamic)?.infinity )
				bc?.write(5,15);
			else if( Std.int(n) == n ) {
				bc?.write(2,0);
				encode_int(n);
			} else {
				bc?.write(3,2);
				encode_float(n);
			}
			
		}
else if (__sw == ("boolean")) {
			if( (cast (o)) == true )
				bc?.write(4,13);
			else
				bc?.write(4,12);
			
		}
else {
			bc.write(3,5);
			encode_object((cast (o)));
			
		}
}
		return true;
	}

	public function do_decode() : Dynamic  untyped {
		var is_number:Dynamic = (bc?.read(1) == 0);
		if( is_number ) {
			var is_float:Dynamic = (bc?.read(1) == 1);
			if( is_float ) {
				var is_special:Dynamic = (bc?.read(1) == 1);
				if( is_special ) {
					var is_infinity:Dynamic = (bc?.read(1) == 1);
					if( is_infinity ) {
						var is_negative:Dynamic = (bc?.read(1) == 1);
						if( is_negative )
							return (cast (-((MtStd):Dynamic).infinity));
						else
							return ((MtStd):Dynamic)?.infinity;
						return null;
					} else
						return (cast (0 * null)); // NaN
				} else
					return decode_float();
			} else
				return decode_int();
		}
		var is_array_obj:Dynamic = (bc?.read(1) == 0);
		if( is_array_obj ) {
			var is_obj:Dynamic = (bc?.read(1) == 1);
			if( is_obj )
				return (fast?decode_object_fast():decode_object());
			else
				return (fast?decode_array_fast():decode_array());
		}
		var tflag:Dynamic = bc?.read(2);
		if( tflag == 0 )
			return (cast (false));
		else if( tflag == 1 )
			return (cast (true));
		else if( tflag == 2 )
			return decode_string();
		else
			return null;
	}

	public function encodeInit( o:Dynamic )  untyped {
		fast = false;
		bc = new BitCodec();
		fields = new Hash();
		nfields = 0;
		next_field_bits = 1;
		nfields_bits = 0;
		cache = new Array();
		cache?.push((cast (o)));
 	}

 	public function encodeLoop()  untyped {
		if( cache?.length == 0 )
			return true;
		do_encode(cache?.shift());
		return false;
	}

	public function encodeEnd()  untyped {
		var s:Dynamic = bc?.toString();
		if( crc )
			s += bc?.crcStr();
		return s;
	}

	public function encode(o:Dynamic)  untyped {
		encodeInit(o);
		fast = true;
		while( encodeLoop() ) {
		}
		return encodeEnd();
	}

	public function progress()  untyped {
		return bc?.in_pos * 100 / bc?.data?.length;
	}

 	public function decodeInit( data:Dynamic )  untyped {
		fast = false;
		bc = new BitCodec();
		bc?.setData(data);
		fieldtbl = new Array();
		nfields = 0;
		next_field_bits = 1;
		nfields_bits = 0;
		cache = new Array();
		result = null;
	}

	public function decodeLoop()  untyped {
		if( cache?.length == 0 )
			result = do_decode();
		else {
			var o:Dynamic = cache[0];
			if( ((MtStd):Dynamic)?._instanceof(o,Array) ) {
				if( !decode_array_item((cast (o))) )
					cache?.shift();
			} else {
				if( !decode_object_field((cast (o))) ) {
					MtStd.deleteField((cast (o)),"pos");
					cache?.shift();
				}
			}
		}
		if( bc?.error_flag ) {
			result = null;
			return false;
		}
		return (cache?.length != 0);
	}

	public function decodeEnd()  untyped {
		if( crc ) {
			var s:Dynamic = bc?.crcStr();
			var s2:Dynamic = bc?.data?.substr(bc?.in_pos,4);
			if( s != s2 )
				return null;
		}
		return (cast (result));
	}

	public function decode( data:Dynamic )  untyped {
		decodeInit(data);
		//fast = true;
		while( decodeLoop() ) {
		}
		return decodeEnd();
	}

}
