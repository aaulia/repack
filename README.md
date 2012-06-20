repack
======

A library and tool for creating texture atlases. Repack can be used as a library to create texture/image atlas at runtime and it also have a tool to generate the atlases before hand.

Installing repack
-----------------
Simply do this ```haxelib install repack``` or you can clone this repository and manually use it.

Using repack as a library
-------------------------
Here is an example of using repack to create texture/image atlas at runtime.
```haxe
package;

import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.Lib;
import flash.display.Sprite;
import org.repack.Packer;

using Std;
using Lambda;

class Main {
	public static function main() {
		var stage  = Lib.current.stage;
		var sizes  = [ 16, 32, 64 ];
		var packer = new Packer<Void>(stage.stageWidth, stage.stageHeight);
		var boxes  = [];

		for (i in 0...80) {
			boxes.push({
				width  : rnd(sizes),
				height : rnd(sizes)
			});
		}

		// Always sort your inputs for the best result
		boxes.sort(function(a, b) { 
			return (b.width * b.height) - (a.width * a.height); 
		});

		for (b in boxes) {
			// in real life, there is possibility that this will fail
			// but for our example, we ignore it
			packer.add(b.width, b.height);
		}

		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align     = StageAlign.TOP_LEFT;

		var canvas   = cast(stage.addChild(new Sprite()), Sprite);
		var graphics = canvas.graphics;

		// draw each packed rectangle that we manage to fit in the packer
		graphics.clear();
		for (pack in packer) {
			var rect  = pack.rect;
			var color = col();

			graphics.lineStyle(1, color, 1.0);
			graphics.beginFill(color, 0.75);
			graphics.drawRect(rect.x, rect.y, rect.width - 1, rect.height - 1);
		}
		graphics.endFill();
	}

	private static inline function col():Int {
		var r = ((Math.random() * 256).int() + 255) >> 1;
		var g = ((Math.random() * 256).int() + 255) >> 1;
		var b = ((Math.random() * 256).int() + 255) >> 1;
		return r << 16 | g << 8 | b;
	}

	private static inline function rnd(v:Array<Int>):Int {
		return v[(Math.random() * v.length).int()];
	}
}
```
You can tweak the packing method, rotation method, and how you sort your data to achive optimal result.

Using repack as a haxelib runnable
----------------------------------
There is also runnable on repack haxelib repo that you can use to generate atlases before hand, for example

```haxelib run repack -input asset -output atlas\output.png -method tl -rotate normal -sort max:min:w:h```

You can find out about the options by using ```haxelib run repack -help```
