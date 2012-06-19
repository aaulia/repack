package org.repack;
import haxe.rtti.Generic;

using Std;
using Lambda;

typedef TRect = {
	public var x       (default, never) :Int;
	public var y       (default, never) :Int;
	public var width   (default, never) :Int;
	public var height  (default, never) :Int;
};


enum PackingMethod {
	TopLeftPacking;
	BestAreaPacking;
	BestShortSidePacking;
	BestLongSidePacking;
}

enum RotateMethod {
	NoRotation;
	NormalRotate;
	AggressiveRotate;
}


class Packed<T> {
	public var rect    (default, null) :TRect;
	public var data    (default, null) :T;
	public var rotated (default, null) :Bool;

	public function new(rect:TRect, data:T, rotated:Bool = false) {
		this.rect    = rect;
		this.data    = data;
		this.rotated = rotated;
	}
}


class Packer<T> implements Generic {

	public var width  (default, null) :Int;
	public var height (default, null) :Int;
	public var method (default, null) :PackingMethod;
	public var rotate (default, null) :RotateMethod;


	public var length (g_length, never) :Int;
	inline function g_length():Int {
		return used.length;
	}


	private var free:Array<Rectangle>;
	private var used:Array<Packed<T>>;


	public function new(width:Int, height:Int, ?method:PackingMethod, ?rotate:RotateMethod) {
		this.width  = width;
		this.height = height;
		this.method = (method == null) ? TopLeftPacking : method;
		this.rotate = (rotate == null) ? NoRotation     : rotate;

		clear();
	}

	public function clear():Void {
		used = [];
		free = [ new Rectangle(0, 0, this.width, this.height) ];
	}

	public function get(index:Int):Packed<T> {
		return used[index];
	}

	public function add(width:Int, height:Int, ?data:T):Bool {

		var find = switch (method) {
			case TopLeftPacking       : findTopLeft;
			case BestAreaPacking      : findBestArea;
			case BestShortSidePacking : findBestShortSide;
			case BestLongSidePacking  : findBestLongSide;
		}

		var rotated = false;
		var space   = null;
		switch(this.rotate) {
			case NoRotation:
				space = find(width, height);
			case NormalRotate:
				space = find(width, height);
				if (space == null) {
					rotated = true;
					space   = find(height, width);
				}
			case AggressiveRotate:
				var a = find(width, height);
				var b = find(height, width);

				space = if (a == null)                { b; } 
				else    if (b == null)                { a; } 
				else    if (a == b)                   { a; }
				else    if (a.y < b.y)                { a; } 
				else    if (a.x < b.x && a.y == b.y)  { a; } 
				else    { b; }

				rotated = (a != b && b != null && space == b);
		}

		if (space == null) {
			return false;
		}

		var rect    = space.clone();
		rect.width  = (rotated == false) ? width  : height;
		rect.height = (rotated == false) ? height : width;

		place(rect);
		purge();

		used.push(new Packed<T>(rect, data, rotated));
		return true;
	}

	inline function min(a:Int, b:Int):Int { return (a < b) ? a : b; }
	inline function max(a:Int, b:Int):Int { return (a > b) ? a : b; }

	function findTopLeft(width:Int, height:Int):Rectangle {
		var px = 0xffffff;
		var py = 0xffffff;
		var rc = null;

		for (f in free) {
			if (width > f.width || height > f.height) {
				continue;
			}

			if (py > f.y) {
				py = f.y;
				px = f.x;
				rc = f;
			} else 
			if (py == f.y) {
				if (px > f.x) {
					px = f.x;
					rc = f;
				}
			}
		}

		return rc;
	}

	function findBestShortSide(width:Int, height:Int):Rectangle { 
		var ds = 0xffffff;
		var px = 0xffffff;
		var py = 0xffffff;
		var rc = null;

		for (f in free) {
			if (width > f.width || height > f.height) {
				continue;
			}

			var cs = min(f.width - width, f.height - height);
			if (ds > cs) {
				ds = cs;
				px = f.x;
				py = f.y;
				rc = f;
			} else 
			if (ds == cs) {
				if (py > f.y) {
					ds = cs;
					px = f.x;
					py = f.y;
					rc = f;
				} else 
				if (py == f.y) {
					if (px > f.x) {
						ds = cs;
						px = f.x;
						py = f.y;
						rc = f;
					}
				}
			}
		}

		return rc;
	}

	function findBestLongSide(width:Int, height:Int):Rectangle { 
		var ds = 0xffffff;
		var px = 0xffffff;
		var py = 0xffffff;
		var rc = null;

		for (f in free) {
			if (width > f.width || height > f.height) {
				continue;
			}

			var cs = max(f.width - width, f.height - height);
			if (ds > cs) {
				ds = cs;
				px = f.x;
				py = f.y;
				rc = f;
			} else 
			if (ds == cs) {
				if (py > f.y) {
					ds = cs;
					px = f.x;
					py = f.y;
					rc = f;
				} else 
				if (py == f.y) {
					if (px > f.x) {
						ds = cs;
						px = f.x;
						py = f.y;
						rc = f;
					}
				}
			}
		}

		return rc;
	}

	function findBestArea(width:Int, height:Int):Rectangle { 
		var da = 0xffffff;
		var px = 0xffffff;
		var py = 0xffffff;
		var rc = null;

		for (f in free) {
			if (width > f.width || height > f.height) {
				continue;
			}

			var ca = (f.width * f.height) - (width * height);
			if (da > ca) {
				da = ca;
				px = f.x;
				py = f.y;
				rc = f;
			} else 
			if (da == ca) {
				if (py > f.y) {
					da = ca;
					px = f.x;
					py = f.y;
					rc = f;
				} else 
				if (py == f.y) {
					if (px > f.x) {
						da = ca;
						px = f.x;
						py = f.y;
						rc = f;
					}
				}
			}
		}

		return rc;
	}

	inline function place(rect:Rectangle):Void {
		var c = free.length;
		var i = 0;
		while (i < c) {
			var f = free[i];
			var s = f.splits(rect);
			if (s != null) {
				free.remove(f);
				while (s.length > 0) {
					free.push(s.pop());
				}
				--i; 
				--c;
			}
			++i;
		}
	}

	inline function purge() {
		var c = free.length;
		var i = 0;
		while (i < c) {
			var f = free[i];
			var j = i + 1;
			while (j < c) {
				var g = free[j];
				if (f.contains(g)) {
					free.remove(g);
					--j; 
					--c;
				} else 
				if (g.contains(f)) {
					free.remove(f);
					--i; 
					--c;
					break;
				}
				++j;
			}
			++i;
		}
	}

	public function iterator():Iterator<Packed<T>> {
		return used.iterator();
	}

}

