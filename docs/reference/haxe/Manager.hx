import navi.menu.Shop.PixiGlowFilter;
import pixi.core.utils.Utils;
import mt.Timer;
import js.Browser;
import haxe.PosInfos;
import pixi.core.text.Text;
import pixi.core.Application;

class AnonSprite10003040 extends display.ASprite {
	public var field:pixi.core.text.Text;
	public var str:String;
}

class AnonSprite1070818 extends display.ASprite {
	public var field:pixi.core.text.Text;
}

@:expose("Manager")
class Manager { // }
	public static var DP_BG = 0;
	public static var DP_MAP = 1;
	public static var DP_MODULE = 2;
	public static var DP_MENU = 3;
	public static var DP_FRONT = 4;

	static var _main:{update:Void->Void};
	public static var dm:mt.DepthManager;
	public static var mcLog:AnonSprite10003040;
	public static var mcWaitScreen:AnonSprite1070818;

	public static var app:Application;

	public static function main() {
		haxe.Log.trace = log;

		KeyboardManager.init();
		Cs.init();

		Utils.skipHello();

		var view = cast js.Browser.document.getElementById("main");
		app = new pixi.core.Application({width: Cs.mcw, height: Cs.mch, view: view});

		// INIT
		var root = new ASprite();
		app.stage.addChild(root);

		dm = new mt.DepthManager(root);
		var bg = dm.attach("mcManagerBg", DP_BG);

		// LANG
		// Text.setLang(Reflect.field(flash.Lib._root, "lang"));

		// PLANET
		loadPlanet();
	}

	public static function initLeReste() {
		// CHECK DEMO
		_main = cast new navi.Map(dm.empty(DP_MAP));

		// UPDATE
		// _main.update();

		navi.Map.me.initConnexion();
		Api.askInfos();
	}

	// PLANET
	public static function loadPlanet() {
		var toPreload = [
			'mcZone', 'mcShape', 'mcBrush', "mcLuz", "mcStar", "groundText", "mcDifStar", "mcMapAsteroide", "mcSkull", "mcHouse", "mcTransformerImpact",
		];

		for (i in 1...24) {
			toPreload.push('landerDecor/${i}');
		}

		BmpTextureHelper.preload(toPreload).then(onTextureLoaded);
	}

	public static function onTextureLoaded(_) {
		initLeReste();
	}

	// WAIT SCREEN
	public static function initWaitScreen() {
		mcWaitScreen = cast dm.attach("mcWaitScreen", DP_FRONT);
		mcWaitScreen.play();
		mcWaitScreen.initTextField("field", {
			align: "center",
			size: 14,
			font: "GAU_font_cube_B",
			color: 0xFFFFFF,
			x: 200,
			y: 161,
		});
		mcWaitScreen.field.filters = [
			new PixiGlowFilter({
				distance: 5,
				outerStrength: 1,
				color: 0x00FF00,
				quality: 0.1
			})
		];
		mcWaitScreen.field.text = Text.get.CONNECTION_SERVER;
	}

	public static function removeWaitScreen() {
		mcWaitScreen.removeMovieClip();
	}

	// LOG
	public static function log(str:String, ?pos:PosInfos) {
		if (str.startsWith("FIXME")) {
			Browser.console.warn('$str at ${pos.className}::${pos.methodName}');
		} else {
			Browser.console.info('${pos.fileName}:${pos.lineNumber} $str');
		}
	}

	// {
}
/*

	DRONES :
	- ANTI-MINE
	- ANTI-SPEEDER

	MOTEUR :
	- HYPERDRIVE 2
	- HYPERDRIVE 3
	- HYPERDRIVE 4
	- HYPERDRIVE 5
	- HYPERDRIVE 6
	- HYPERDRIVE 7
	- HYPERDRIVE 8

	MUNITION
	- VIE SUP
	- VIE SUP


 */
