package org.repack;
using Std;

class Rectangle {

	public var x:Int;
	public var y:Int;
	public var width:Int;
	public var height:Int;

	public function new(x:Int, y:Int, width:Int, height:Int) {
		this.x       = x;
		this.y       = y;
		this.width   = width;
		this.height  = height;
	}

	public function intersects(b:Rectangle):Bool {
		return !(left >= b.right || top >= b.bottom || right <= b.left || bottom <= b.top);
	}

	public function contains(b:Rectangle):Bool {
		return !(left > b.left || top > b.top || right < b.right || bottom < b.bottom);
	}

	public function clone():Rectangle {
		return new Rectangle(x, y, width, height);
	}

	public function splits(b:Rectangle):Array<Rectangle> {
		if (empty || b.empty || !intersects(b)) {
			return null;
		}
		
		var r:Array<Rectangle> = [];
		if (left < b.right && right > b.left) {
			if (top < b.top && bottom > b.top) {
				var n = clone();
				n.bottom = b.top;
				r.push(n);
			}
			
			if (top < b.bottom && bottom > b.bottom) {
				var n = clone();
				n.top = b.bottom;
				r.push(n);
			}
		}
		
		if (top < b.bottom && bottom > b.top) {
			if (left < b.left && right > b.left) {
				var n = clone();
				n.right = b.left;
				r.push(n);
			}
			
			if (left < b.right && right > b.right) {
				var n = clone();
				n.left = b.right;
				r.push(n);
			}
		}
		
		return r;
	}

	public function toString() {
		return "{ x: $x, y: $y, width: $width, height: $height }".format();
	}

	public var left (g_left, s_left):Int;
	private inline function g_left():Int  { return x; }
	private inline function s_left(v:Int):Int { 
		width -= (v - x); 
		return x = v; 
	}

	public var top (g_top, s_top):Int;
	private inline function g_top():Int  { return y; }
	private inline function s_top(v:Int):Int { 
		height -= (v - y); 
		return y = v; 
	}

	public var right (g_right,  s_right):Int;
	private inline function g_right ():Int  { return (x + width);  }
	private inline function s_right (v:Int):Int { 
		width = (v - x); 
		return v; 
	}

	public var bottom (g_bottom, s_bottom):Int;
	private inline function g_bottom():Int  { return (y + height); }
	private inline function s_bottom(v:Int):Int { 
		height = (v - y); 
		return v; 
	}

	public var empty (g_empty, never):Bool;
	private inline function g_empty():Bool { 
		return (width <= 0 || height <= 0); 
	}

}
