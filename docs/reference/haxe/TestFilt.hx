import ImageDataUtils.ColorMatrix;
import js.lib.Uint8Array;
import js.Browser;
import pixi.resources.Resource;
import StackBlur.BlurStack;
import pixi.core.Application;
import mt.bumdum.Sprite;
import haxe.Timer;
import pixi.core.text.TextStyle;
import pixi.core.math.Point;
import js.html.CanvasElement;
import pixi.core.math.shapes.Rectangle;
import pixi.filters.extras.GlowFilter;
import mt.DepthManager;
import pixi.core.math.Matrix;
import mt.bumdum.Lib.Num;
import navi.menu.Shop.PixiGlowFilter;
import mt.bumdum.Lib.Filt;
import pixi.core.graphics.Graphics;
import pixi.core.utils.Utils;

private typedef Planete = {gri:Array<Array<Int>>, pop:Float, hor:Int, gMax:Int, dMax:Int, hc:Float, min:Array<Int>, type:Int, g:Float};

@:expose("main")
class TestFilt {
	public static var WIDTH = 1600;
	public static var HEIGHT = 700;

	public static var GMIN = 60;

	// DM
	public static var DP_BG = 0;
	public static var DP_PLAN = 1; // > B DM
	public static var DP_INTER = 2;

	// B DM
	public static var DP_UNDERPARTS = 0;
	public static var DP_PAD = 1;
	public static var DP_GROUND = 2; // > G DM
	public static var DP_HERO = 3;
	public static var DP_FOREGROUND = 4;
	public static var DP_DRONES = 5;
	public static var DP_PARTS = 6;

	// G DM
	public static var DP_DECOR = 1;
	public static var DP_MINERALS = 2;
	public static var DP_FRONT = 4;

	static public var flMarkHouse:Bool;
	static public var flHouseVisited:Bool;
	static public var col:Int;

	static public var fadeCoef:Float;

	static public var chs:Int;
	static public var item:Int;
	static public var debit:Int;

	static public var pl:Planete;
	static public var seed:mt.OldRandom;

	static public var app:Application;

	static public var pixels:PixelHelper;
	static public var r:Resource;

	static function main() {
		Utils.skipHello();

		var view:CanvasElement = cast js.Browser.document.getElementById("main");
		view.width = WIDTH;
		view.height = HEIGHT;
		app = new pixi.core.Application({width: WIDTH, height: HEIGHT, view: view});

		seed = new mt.OldRandom(50 * 10000 + 27);

		PixelHelper.app = app;

		pl = lander.Game.PLANETES[7];

		// INIT
		var root = new ASprite();
		root.beginFill(0xCC0000);
		root.drawRect(0, 0, 50, 50);

		var plasma = RenderTexture.create(500, 500);

		plasma.draw(root, new Matrix());

		pixels = plasma.extract();
		plasma.destroy();

		var newTexture:Texture = untyped Texture.fromBuffer(pixels.getPixels(), 500, 500);
		app.stage.addChild(new pixi.core.sprites.Sprite(newTexture));
		r = untyped newTexture.baseTexture.resource;

		var t2 = new Timer(50);
		t2.run = () -> {
			var root = new ASprite();
			root.beginFill(0xCC0000);
			root.drawRect(0, 0, 50, 50);

			var plasma = RenderTexture.create(500, 500);
			plasma.draw(root, new Matrix());
			pixels.copyPixels(plasma.extract(), new Rectangle(0, 0, 50, 50), new Point(Std.random(400), Std.random(400)));
			r.update();
			plasma.destroy(true);
		};

		Browser.window.requestAnimationFrame(update);
	}

	static function update(t:Float) {
		mt.Timer.update(t);

		var bl = Math.max(2, mt.Timer.tmod * 4 * Cs.PQ);

		StackBlur.__stackBlurCanvasRGBA(pixels, 500, 500, bl, bl, 1);
		var cm = new ColorMatrix();
		cm.alphaOffset = -2;
		ImageDataUtils.colorTransform(pixels, new Rectangle(0, 0, pixels.width, pixels.height), cm);
		r.update();

		Browser.window.requestAnimationFrame(update);
	}
}
