package;

import haxe.io.Path;
import haxe.Json;
import haxe.io.Bytes;
import org.repack.Packer;
import org.repack.Rectangle;
import sys.FileSystem;
import sys.io.File;
import format.png.Data;
import format.png.Reader;
import format.png.Writer;
import format.png.Tools;

using Std;
using Lambda;
using StringTools;


class Main {
	
	public static function main() {
		var args = Sys.args();
		Sys.setCwd(new Path(args.pop()).toString());

		if (args.length == 0) {
			printHelp();
		}

		var inputs = [];
		var output = new Path(Sys.getCwd());
		var config = new Config();

		while(!args.empty()) {
			var key = args.shift().toLowerCase();
			if (key.startsWith("-") == false) {
				continue;
			}

			switch (key) {
				case "-help"         : printHelp();
				case "-o", "-output" : output = new Path(args.shift());
				case "-i", "-input"  : inputs = args.shift().split(":");
				default              : config.parse(key, args);
			}
		}

		
		
		var images   = parsePaths(inputs, []);
		var oversize = function(d) { 
			return (d.image.width > config.width || d.image.height > config.height); 
		}
		
		if (images.exists(oversize)) {
			error("There is one or more image that is bigger than the canvas size.");
		}
		
		images.sort(function(a:PackData, b:PackData):Int {
			var d = 0;
			for (s in config.sorter) {
				d = s(a, b);
				if (d != 0) {
					break;
				}
			}
			return d;
		});
		

		var odir  = (output.dir  == null || output.dir  == "") ? "."    : output.dir;
		var ofile = (output.file == null || output.file == "") ? "pack" : output.file;
		var oext  = (output.ext  == null || output.ext  == "") ? "png"  : output.ext; 

		if (oext != "png") { oext = "png"; }
		if (FileSystem.exists(odir) == false) {	
			FileSystem.createDirectory(odir); 
		}
		odir = FileSystem.fullPath(odir); 
		
		
		
		var page   = 0;
		var coords = [];
		var canvas = Image.create(config.width, config.height);
		var packer = new Packer<PackData>(config.width, config.height, config.padding, config.method, config.rotate);

		while (images.length > 0) {
			packer.clear();
			
			var index = 0;
			var count = images.length;
			while (index < count) {
				var entry = images[index];
				if (packer.add(entry.image.width, entry.image.height, entry)) {
					images.remove(entry);
					--index;
					--count;
				}
				++index;
			}

			coords = [];
			canvas.fill([ 0, 0, 0, 0 ]);
			for (p in packer) {
				canvas.put(p.rect.x, p.rect.y, p.data.image, p.rotated);
				coords.push({
					x       : p.rect.x,
					y       : p.rect.y,
					width   : p.rect.width,
					height  : p.rect.height,
					rotated : p.rotated,
					path    : p.data.path
				});
			}
			
			canvas.save('${odir}/${ofile}_${page}.${oext}');
			saveJSON(coords, '${odir}/${ofile}_${page}.json');
			++page;
		}

	}

	private static function printHelp() {
		Sys.println("Usage: repack [options]");
		Sys.println("Options are:");
		Sys.println("-help       : Print this help");
		Sys.println("-i, -input  : File(s) or directories to be used as input path, ");
		Sys.println("              separated by ':'. Directories are read recursively." );
		Sys.println("-o, -output : File or directory to place the result");
		Sys.println("-w, -width  : Canvas/atlas width");
		Sys.println("-h, -height : Canvas/atlas height");
        Sys.println("-p, -padding: Amount of padding between rectangles");
		Sys.println("-m, -method : Packing method, which can be one of:");
		Sys.println("                  tl -> TopLeftPacking");
		Sys.println("                  a  -> BestAreaPacking");
		Sys.println("                  ss -> BestShortSidePacking");
		Sys.println("                  ls -> BestLongSidePacking");
		Sys.println("");
		Sys.println("-s, -sort   : Sort method(s) used to sort the input images, can be ");
		Sys.println("              one or more (separeted by ':') of:");
		Sys.println("                  w   -> Sort by width descending");
		Sys.println("                  h   -> Sort by height descending");
		Sys.println("                  a   -> Sort by area descending");
		Sys.println("                  min -> Sort by min(w, h) descending");
		Sys.println("                  max -> Sort by max(w, h) descending");
		Sys.println("");
		Sys.println("-r, -rotate : Use rotation to maximize placement, can be one of:");
		Sys.println("              normal     -> Only rotate if there is no space found.");
		Sys.println("              aggressive -> Always rotate, and choose the best one.");
		Sys.println("-po2        : Round the width & height to the next highest power of 2");
		Sys.println("-square     : Keep width == height");
		Sys.exit(0);
	}

	private static function saveJSON(data, path) {
		var f = File.write(path);
		f.writeString(Json.stringify(data));
		f.close();
	}

	private static function parsePaths(inputs:Iterable<String>, output:Array<PackData>, ?directory:String):Array<PackData> {
		var cwd = (directory == null) ? "" : directory;
		for (input in inputs) {
			if (input.endsWith("/") || input.endsWith("\\")) {
				input = input.substr(0, input.length - 1);
			}

			var path = cwd + input;
			if (!FileSystem.exists(path)) {
				error('Invalid path: $path');
				return [];
			}
			//path = FileSystem.fullPath(path);

			if (FileSystem.isDirectory(path)) {
				if (!path.endsWith("\\") || !path.endsWith("/")) {
					path += "/";
				}
				parsePaths(FileSystem.readDirectory(path), output, path);
			} else {
				if (!path.endsWith(".png")) {
					continue;
				}
				output.push(new PackData(Image.open(path), path));
			}
		}
		return output;
	}

	private static inline function error(msg, code = -1) {
		Sys.println(msg);
		Sys.exit(code);
	}
}



private class PackData {

	public var image (default, null) :Image;
	public var path  (default, null) :String;

	public function new(image, path) {
		this.image = image;
		this.path  = path;
	}
}



private class Image {

	public  var width  (default, null) :Int;
	public  var height (default, null) :Int;
	public  var pixels (default, null) :Bytes;
	private var color  (default, null) :Int;

	public static function create(width:Int, height:Int):Image {
		return new Image(width, height, Bytes.alloc(width * height * 4), Color.ColTrue(true));
	}

	public static function open(path:String):Image {
		var f = File.read(path, true);
		var d = new Reader(f).read();
		var b = Tools.extract32(d);
		var h = Tools.getHeader(d);
		f.close();
		return new Image(h.width, h.height, b, h.color);
	}

	public function new(width:Int, height:Int, pixels:Bytes, ?color:Color) {
		this.width  = width;
		this.height = height;
		this.pixels = pixels;
		this.color  = if (color != null) {
			switch(color) {
				case ColTrue(a) : (a) ? 4 : 3;
				case ColGrey(a) : throw "Unsupported image format";
				case ColIndexed : throw "Unsupported image format";
			}
		} else {
			4;
		}
	}

	public function get(x:Int, y:Int):Array<Int> {
		if (x < 0 || y < 0 || x >= width || y >= height) {
			return null;
		}

		var p = ((y * width) + x) * 4;
		var a = 0; var r = 0; var g = 0; var b = 0;
		if (color == 4) {
			r = pixels.get(p++) & 0xFF;
			g = pixels.get(p++) & 0xFF;
			b = pixels.get(p++) & 0xFF;
			a = pixels.get(p++) & 0xFF;
		} else {
			a = pixels.get(p++) & 0xFF;
			r = pixels.get(p++) & 0xFF;
			g = pixels.get(p++) & 0xFF;
			b = pixels.get(p++) & 0xFF;
		}
		return [ r, g, b, a ];
	}

	public function set(x:Int, y:Int, color:Array<Int>):Void {
		if (x < 0 || y < 0 || x >= width || y >= height) {
			return;
		}

		var p = ((y * width) + x) * 4;
		pixels.set(p++, color[0]);
		pixels.set(p++, color[1]);
		pixels.set(p++, color[2]);
		pixels.set(p++, color[3]);
	}

	public function fill(color:Array<Int>):Void {
		for (i in 0...(width * height)) {
			var p = i * 4;
			pixels.set(p++, color[0]);
			pixels.set(p++, color[1]);
			pixels.set(p++, color[2]);
			pixels.set(p++, color[3]);
		}
	}

	public function put(x:Int, y:Int, img:Image, rotated:Bool = false):Void {
		var c = new Rectangle(0, 0, width, height);
		var d = (rotated == false) ? new Rectangle(x, y, img.width, img.height) : new Rectangle(x, y, img.height, img.width);
		var s = (rotated == false) ? new Rectangle(0, 0, img.width, img.height) : new Rectangle(0, 0, img.height, img.width);

		if (!c.intersects(d)) {
			return;
		}

		if (d.left   < c.left)   { s.left   += (c.left   - d.left);   d.left    = c.left;   }
		if (d.top    < c.top)    { s.top    += (c.top    - d.top);    d.top     = c.top;    }
		if (d.right  > c.right)  { s.right  -= (d.right  - c.right);  d.right   = c.right;  }
		if (d.bottom > c.bottom) { s.bottom -= (d.bottom - c.bottom); d.bottom  = c.bottom; }

		if (!rotated) {
			if (color == img.color) {
				for (py in 0...d.height) {
					var dp = ((d.top + py) *   c.width + d.left) * 4;
					var sp = ((s.top + py) * img.width + s.left) * 4;
					pixels.blit(dp, img.pixels, sp, s.width * 4);
				}
			} else {
				for (py in 0...d.height) {
					var dy = d.y + py;
					var sy = s.y + py;
					for (px in 0...d.width) {
						set(d.x + px, dy, img.get(s.x + px, sy));
					}
				}
			}
		} else {

			var dx = d.x;
			var dy = d.y + s.height - 1;
			var sx = img.width - (s.y + s.height);
			var sy = s.x;

			for (py in 0...s.width) {
				var dxpy = dx + py;
				var sypy = sy + py;
				for (px in 0...s.height) {
					set(dxpy, dy - px, img.get(sx + px, sypy));
				}
			}
		}
	}

	public function save(path:String) {
		var f = File.write(path, true);
		var w = new Writer(f);
		var d = Tools.build32BGRA(width, height, pixels);
		w.write(d);
		f.close();
	}
}

private class Config {

	public  var width  (get, set) :Int;
	public  var height (get, set) :Int;
	
	private var _width :Int;
	private var _height:Int;
	
	private function set_width(v:Int) { return _width = v; }
	private function get_width():Int {
		if (square) { _width = max(_width, _height); }
		if (powOf2 && !isPo2(_width)) {
			_width = toPo2(_width);
		}
		
		return _width;
	}
	
	private function set_height(v:Int) { return _height = v; }
	private function get_height():Int {
		if (square) { _height = max(_width, _height); }
		if (powOf2 && !isPo2(_height)) {
			_height = toPo2(_height);
		}
		
		return _height;
	}
	
	private inline function isPo2(v:Int):Bool {
		return (v > 0) && ((v & (v - 1)) == 0);
	}
	
	private inline function toPo2(v:Int):Int {
		v--;
		v |= v >> 1;
		v |= v >> 2;
		v |= v >> 4;
		v |= v >> 8;
		v |= v >> 16;
		v++;
		return v;
	}
	
	public var method  (default, null) :PackingMethod;
	public var sorter  (default, null) :Array< PackData->PackData->Int >;
	public var rotate  (default, null) :RotateMethod;
	public var padding (default, null) :Int;
	public var powOf2  (default, null) :Bool;
	public var square  (default, null) :Bool;

	public function new() {
		width   = 256;
		height  = 256;
		method  = parseMethod("tl");
		sorter  = parseSorter("max:min:w:h");
		rotate  = NoRotation;
		padding = 0;
		powOf2  = false;
		square  = false;
	}

	private function parseMethod(s:String) {
		return switch (s.toLowerCase()) {
			case "tl" : TopLeftPacking;
			case "a"  : BestAreaPacking;
			case "ss" : BestShortSidePacking;
			case "ls" : BestLongSidePacking;
			default   : TopLeftPacking;
		};
	}

	private inline function max(a, b) {	return (a < b) ? b : a;	}
	private inline function min(a, b) {	return (a > b) ? b : a;	}

	private function parseSorter(s:String) {
		var res = [];
		var opt = s.toLowerCase().split(":");
		var dup = [];
		for (o in opt) {
			if (dup.indexOf(o) >= 0) {
				continue;
			}

			var fun = switch (o) {
				case "min": 
					function(a:PackData, b:PackData) { 
						return min(b.image.width, b.image.height) - min(a.image.width, a.image.height); 
					}
				case "max": 
					function(a:PackData, b:PackData) { 
						return max(b.image.width, b.image.height) - max(a.image.width, a.image.height); 
					}
				case "w": 
					function(a:PackData, b:PackData) { 
						return b.image.width  - a.image.width;  
					}
				case "h": 
					function(a:PackData, b:PackData) { 
						return b.image.height - a.image.height; 
					}
				case "a": 
					function(a:PackData, b:PackData) { 
						return (b.image.width * b.image.height) - (a.image.width * a.image.height);
					}
				default: null;
			}

			if (fun == null) {
				continue;
			}

			res.push(fun);
			dup.push(o);
		}

		return res;
	}

	function parseRotate(r:String):RotateMethod {
        var method:RotateMethod = RotateMethod.NoRotation;
		switch (r) {
			case "normal"     : method = NormalRotate;
			case "aggressive" : method = AggressiveRotate;
		}
        return method;
	}

	public function parse(key:String, args:Array<String>):Void {
		switch (key) {
			case "-w", "-width"  : this.width   = args.shift().parseInt();
			case "-h", "-height" : this.height  = args.shift().parseInt();
			case "-p", "-padding": this.padding = args.shift().parseInt();
			
			case "-m", "-method" : this.method  = parseMethod(args.shift());
			case "-s", "-sort"   : this.sorter  = parseSorter(args.shift());
			case "-r", "-rotate" : this.rotate  = parseRotate(args.shift());
			
			case "-po2"          : this.powOf2  = true;
			case "-square"       : this.square  = true;
		}
	}

	public function toString() {
		return '{ width: $width, height: $height, method: $method, sorter: $sorter, rotate: $rotate, powerOfTwo: $powOf2 }';
	}
}
