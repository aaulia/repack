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
	
	public function inflate(v:Int) {
		left   -= v;
		top    -= v;
		right  += v;
		bottom += v;
	}
	
	public function deflate(v:Int) {
		left   += v;
		top    += v;
		right  -= v;
		bottom -= v;		
	}

	public function toString() {
		return '{ x: $x, y: $y, width: $width, height: $height }';
	}

	public var left (get, set):Int;
	private inline function get_left():Int  { return x; }
	private inline function set_left(v:Int):Int { 
		width -= (v - x); 
		return x = v; 
	}

	public var top (get, set):Int;
	private inline function get_top():Int  { return y; }
	private inline function set_top(v:Int):Int { 
		height -= (v - y); 
		return y = v; 
	}

	public var right (get, set):Int;
	private inline function get_right ():Int  { return (x + width);  }
	private inline function set_right (v:Int):Int { 
		width = (v - x); 
		return v; 
	}

	public var bottom (get, set):Int;
	private inline function get_bottom():Int  { return (y + height); }
	private inline function set_bottom(v:Int):Int { 
		height = (v - y); 
		return v; 
	}

	public var empty (get, never):Bool;
	private inline function get_empty():Bool { 
		return (width <= 0 || height <= 0); 
	}

}
