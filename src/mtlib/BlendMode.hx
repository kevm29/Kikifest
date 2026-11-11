package mtlib;

abstract BlendMode(Int) from Int to Int {
	public static inline var NORMAL:BlendMode = 1;
	public static inline var LAYER:BlendMode = 2;
	public static inline var MULTIPLY:BlendMode = 3;
	public static inline var SCREEN:BlendMode = 4;
	public static inline var LIGHTEN:BlendMode = 5;
	public static inline var DARKEN:BlendMode = 6;
	public static inline var ADD:BlendMode = 7;
	public static inline var SUBTRACT:BlendMode = 8;
	public static inline var DIFFERENCE:BlendMode = 9;
	public static inline var INVERT:BlendMode = 10;
	public static inline var ALPHA:BlendMode = 11;
	public static inline var ERASE:BlendMode = 12;
	public static inline var OVERLAY:BlendMode = 13;
	public static inline var HARDLIGHT:BlendMode = 14;
}
