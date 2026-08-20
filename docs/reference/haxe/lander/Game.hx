package lander;

import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.math.shapes.Rectangle;
import pixi.core.math.Matrix;
import pixi.core.graphics.Graphics;
import pixi.core.Pixi.BlendModes;
import pixi.core.textures.RenderTexture;
import mt.bumdum.Lib;
import Protocol;

@:native("PIXI.filters.GlowFilter")
extern class NativeGlowFilter extends Filter {
	public function new(options:Dynamic);
}

class AnonSprite12350422 extends display.ASprite {
	public var fuel:display.ASprite;
}

class AnonSprite11295997 extends display.ASprite {
	public var field:pixi.core.text.Text;
}

class AnonSprite12449861 extends display.ASprite {
	public var hor:display.ASprite;
}

class AnonSprite13489412 extends display.ASprite {
	public var list:Array<Air>;
}

class Plan extends display.ASprite {
	public var c:Float;
	public var bx:Float;
	public var flHor:Bool;
	public var dy:Float;
}

class Air extends display.ASprite {
	public var c:Float;
}

class Choice extends display.ASprite {
	public var fieldTitle:pixi.core.text.Text;
	public var field:pixi.core.text.Text;
}

enum Step {
	Play;
	End;
	Outro;
}

private typedef Planete = {gri:Array<Array<Int>>, pop:Float, hor:Int, gMax:Int, dMax:Int, hc:Float, min:Array<Int>, type:Int, g:Float};

// typedef House = { x:Int, y:Int, type:Int, rc:Float, sx:Int };

class Game extends Module { // }
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

	public var flMarkHouse:Bool;
	public var flHouseVisited:Bool;
	public var col:Int;

	public var fadeCoef:Float;

	public var chs:Int;
	public var item:Int;
	public var debit:Int;
	public var travel:_Travel;

	public var focus:{
		x:Float,
		y:Float,
		vx:Float,
		vy:Float
	};

	public var plans:Array<Plan>;
	public var houses:Array<lander.House>;
	public var minerals:Array<lander.Mineral>;
	public var currentPlanet:Planete;

	public var step:Step;
	public var pad:Pad;
	public var hero:Hero;
	public var seed:mt.OldRandom;

	public var mcInter:AnonSprite12350422;

	var table:AnonSprite11295997;
	var bg:AnonSprite12449861;
	var mcAir:AnonSprite13489412;

	public var base:display.ASprite;
	public var mcGround:display.ASprite;
	public var mcForeground:display.ASprite;
	public var bmpGround:RenderTexture;
	public var bmpGroundPx:PixelHelper;

	public var bmpForeground:RenderTexture;

	public var bmpDecor:RenderTexture;
	public var bmpDecorPx:PixelHelper;

	public var bmpCol:PixelHelper;

	public var bdm:mt.DepthManager;
	public var gdm:mt.DepthManager;
	public var fdm:mt.DepthManager;

	static public var me:lander.Game;

	public function new(mc, col:Int, flh:Bool) {
		flHouseVisited = flh;

		this.col = col;

		me = this;
		super(mc);

		flMarkHouse = false;
		min = 0;
		debit = 0;

		chs = 0;
		missile = Cs.pi.missile;

		initInter();
	}

	override public function initLevel(x, y, zid, flMinerai, ?lvl) {
		super.initLevel(x, y, zid, flMinerai, lvl);

		seed = new mt.OldRandom(x * 10000 + y);
		currentPlanet = PLANETES[zid];

		// BG
		bg = cast dm.attach("bgLander", DP_BG);
		var bmpBg = getBmpBg(col);
		var s = bg.attachBitmap(bmpBg, 0);
		s.x = -Module.Margin;
		s.y = -Module.Margin;

		// PLANS
		initPlans();

		if (currentPlanet.gMax > 0) {
			// GROUND
			mcGround = bdm.empty(DP_GROUND);
			Filt.glow(mcGround, 2, 2, 0);
			gdm = new mt.DepthManager(mcGround);

			// BMP GROUND
			bmpForeground = RenderTexture.create(WIDTH, currentPlanet.dMax);
			drawGround();

			// BMP DECOR
			var mc = gdm.empty(DP_DECOR);
			mc._y = HEIGHT - currentPlanet.dMax;
			bmpDecor = RenderTexture.create(WIDTH, currentPlanet.dMax);

			// HOUSES
			if (houses == null)
				houses = [];
			var scn = lander.House.getScenario(level.zid, seed);

			if (scn != null)
				new lander.House(seed.random(10000), scn);

			drawDecor();
			mc.attachBitmap(bmpDecor, 0);

			// COL BMP
			// genColBmp(); // Useless ???

			// FOREGROUND
			mcForeground = bdm.empty(DP_FOREGROUND);
			fdm = new mt.DepthManager(mcForeground);
			var m = new Matrix();
			m.translate(0, currentPlanet.dMax - currentPlanet.gMax);
			bmpForeground.draw(new pixi.core.sprites.Sprite(bmpGround), m);

			var mc = fdm.empty(0);
			mc.attachBitmap(bmpForeground, 0);
			mc._y = HEIGHT - currentPlanet.dMax;
			Filt.glow(mc, 1, 1, 0);

			// CREUSE CAVITE HOUSE
			for (h in houses)
				h.dig();

			// MINERALS
			if (flMinerai)
				initMinerals();
		}

		// PAD
		initPad();

		// INIT
		updatePlans();
		updateSprites();
	}

	public function initPad() {
		pad = new lander.Pad();
		pad.x = WIDTH * 0.5;
		pad.y = Cs.mch * 0.5;
		focus = pad;
	}

	public function initMinerals() {
		minerals = [];

		// SURFACE
		var valueMax = Std.int(Math.pow(seed.rand(), 2) * currentPlanet.min[0]);

		while (valueMax > 0) {
			var min = new lander.Mineral(seed);
			var value = Std.int(Num.mm(1, seed.random(valueMax), 30));
			valueMax -= value;
			min.setValue(value);
			min.root._x = seed.random(lander.Game.WIDTH);
			min.dropToSurface();

			for (h in houses) {
				if (Math.abs(h.x - min.root._x) < 90)
					min.kill();
			}
		}
	}

	override public function initPlay() {
		super.initPlay();
		step = Play;
	}

	// UPDATE
	override public function update() {
		if (!flView)
			return;
		super.update();
		if (pauseCoef != null)
			return;
		switch (step) {
			case Play:
				updatePlans();

				if (hero != null)
					hero.update();

				if (pad.y < -(pad.ray + 10) && pad.vy < 0)
					initEnding(true);
			case End:
				updateEnding();
			case Outro:
				updateOutro();
		}

		updateSprites();

		flClick = false;
	}

	// PLANS
	function initPlans() {
		plans = [];

		// HORIZON

		var mc:Plan = cast dm.attachMovieImage("horLander", (level.zid + 1).string(), DP_PLAN);
		mc.anchor.set(0, 465 / 617);
		var c = currentPlanet.hc;
		mc.c = c;
		mc.bx = 0;
		mc.dy = 0;
		mc.flHor = true;
		plans.push(mc);

		// PLANS

		var numFrames = [
			76, 132, 81, 53, 63, 63, 46, 32, 52, 60, 45, 78, 70, 69, 56, 41, 76, 45, 131, 48, 52, 41
		];

		var max = numFrames[level.zid]; // Not +1 because we start at 0 here

		var obx:Float;
		for (i in 0...max) {
			var cc = Math.pow((i + 1) / max, 2);
			var c = currentPlanet.hc + cc * (1 - currentPlanet.hc);
			var mc:Plan = null;

			if (i == max - 1) {
				mc = cast dm.empty(DP_PLAN);
				mc.bx = 0;
				mc.flHor = false;
				bdm = new mt.DepthManager(mc);
				base = mc;
			} else {
				mc = cast dm.attachMovieImage("landerPlan" + (level.zid + 1), Std.string(i + 1), DP_PLAN);

				var xmax = WIDTH * c + Cs.mcw * (1 - c);
				var ymax = -GMIN * c + currentPlanet.hor * (1 - c);
				while (true) {
					mc.bx = seed.rand() * (xmax / c);
					break;
					if (obx == null || Math.abs(obx - mc.bx) > 50)
						break;
				}
				var dy = 0;
				if (level.zid == ZoneInfo.ASTEROBELT)
					dy = 400;

				obx = mc.bx;
				mc.flHor = true;
				mc.dy = -seed.rand() * dy;

				// mc.smc.gotoAndStop(i + 1);

				/*if (mc.smc.smc != null)
						mc.smc.smc.gotoAndStop(seed.random(mc.smc.smc._totalframes) + 1);
					if (mc.smc.smc.smc != null)
						mc.smc.smc.smc.gotoAndStop(seed.random(mc.smc.smc.smc._totalframes) + 1); */
				mc._xscale = mc._yscale = c * 100;
			}

			mc.c = c;
			plans.push(mc);
		}

		focus = {
			x: 0,
			y: 0,
			vx: 0,
			vy: 0,
		};

		updatePlans();

		// AIR
		mcAir = cast dm.empty(DP_PLAN);
		mcAir.list = [];
		var adm = new mt.DepthManager(mcAir);

		var max = Std.int(Cs.PREF_GFX * 20);

		for (i in 0...max) {
			var mc:Air = cast adm.attach("partAir", 0);
			mc._x = Math.random() * Cs.mcw;
			mc._y = Math.random() * Cs.mch;
			mc.c = 1 + Math.random();
			mcAir.list.push(mc);
		}
	}

	function updatePlans() {
		var obx = base._x;
		var oby = base._y;

		var sx = Num.mm(Cs.mcw - WIDTH, Cs.mcw * 0.5 - focus.x, 0);
		var sy = Num.mm(Cs.mch - HEIGHT, Cs.mch * 0.5 - focus.y, 0);

		for (mc in plans) {
			if (mc.flHor) {
				var dy = Cs.mch - currentPlanet.hor;
				var by = HEIGHT - (dy + GMIN);
				mc._x = (mc.bx + sx) * mc.c;
				mc._y = (sy + mc.dy + by) * mc.c + dy;
			} else {
				mc._x = sx * mc.c;
				mc._y = sy * mc.c;
			}
		}

		var dx = obx - base._x;
		var dy = oby - base._y;

		if (mcAir != null) {
			mcAir._alpha = (Math.abs(dx) + Math.abs(dy)) * 10;

			for (mc in mcAir.list) {
				mc._x -= dx * mc.c;
				mc._y -= dy * mc.c;
				mc._x = Num.sMod(mc._x, Cs.mcw);
				mc._y = Num.sMod(mc._y, Cs.mch);
			}
		}
	}

	// DECOR
	public function drawGround() {
		// SHAPE
		var shape = RenderTexture.create(WIDTH, currentPlanet.gMax);
		var mcShape = new Graphics();
		mcShape.beginFill(0xFF0000, 100);
		var gy = currentPlanet.gMax - GMIN;
		var x = 0.0;
		var y = gy * 0.5;

		mcShape.moveTo(0, y);
		while (true) {
			x = Math.min(x + 50 + seed.rand() * 200, WIDTH);
			y = Num.mm(25, y + (seed.rand() * 2 - 1) * 40, gy);
			mcShape.lineTo(x, y);
			if (x == WIDTH)
				break;
		}
		mcShape.lineTo(WIDTH, currentPlanet.gMax);
		mcShape.lineTo(0, currentPlanet.gMax);
		mcShape.lineTo(0, 0);
		mcShape.endFill();
		shape.draw(mcShape, new Matrix());
		mcShape.destroy();

		// GROUND TEXTURE
		var side = 100;
		var text = RenderTexture.create(side, side);
		var mcText = BmpTextureHelper.getASprite("groundText");
		mcText.anchor.set(0, 0);
		mcText.x = -338;
		mcText.gotoAndStop(level.zid + 1);
		text.draw(mcText, new Matrix());
		mcText.destroy();

		var textPx = text.extract();
		var shapePx = shape.extract();

		bmpGroundPx = RenderTexture.create(WIDTH, currentPlanet.gMax).extract();

		// APPLY
		var xmax = Std.int(WIDTH / side) + 1;
		var ymax = Std.int(currentPlanet.gMax / side) + 1;
		for (x in 0...xmax) {
			for (y in 0...ymax) {
				var p = new pixi.core.math.Point(x * side, y * side);
				bmpGroundPx.copyPixels(textPx, new Rectangle(0, 0, side, side), p, shapePx, p, true);
			}
		}
		text.destroy();
		shape.destroy();

		bmpGround = cast bmpGroundPx.getTexture();
		var s = new pixi.core.sprites.Sprite(bmpGround);
		s.filters = [];

		// SOL

		var list = currentPlanet.gri;
		for (a in list) {
			s.filters.push(new NativeGlowFilter({
				distance: a[0],
				outerStrength: a[1],
				color: a[2],
				quality: 1,
			}));
		}

		var finalRenderTexture = RenderTexture.create(WIDTH, currentPlanet.gMax);
		finalRenderTexture.draw(s, new Matrix());
		bmpGround = cast finalRenderTexture.extract().getTexture();
	}

	public function drawDecor() {
		// ELEMENTS
		var max = 20;
		for (i in 0...max) {
			var mc = BmpTextureHelper.getASprite('landerDecor/${level.zid + 1}');
			var x = seed.random(WIDTH);
			var y = getGround(x);

			var p = new lander.Pix(x, y, 1);
			var a = p.getNormal(10);

			y -= HEIGHT - currentPlanet.dMax;

			var m = new Matrix();
			m.rotate(a + 1.57);
			m.translate(x, y);
			mc.gotoAndStop(seed.random(mc._totalframes) + 1);
			/*if (mc.smc.smc != null)
				mc.smc.smc.gotoAndStop(seed.random(mc.smc.smc._totalframes) + 1); */
			bmpDecor.draw(mc, m);
		}

		// GROUND
		var m = new Matrix();
		m.translate(0, currentPlanet.dMax - currentPlanet.gMax);
		bmpDecor.draw(new pixi.core.sprites.Sprite(bmpGround), m);

		bmpDecorPx = bmpDecor.extract();
	}

	// PAD
	public function newHero() {
		var skinId = 0;
		if (currentPlanet.type == 1 && !Cs.pi.gotItem(MissionInfo.COMBINAISON))
			skinId = 1;
		hero = new lander.Hero(skinId);
		lander.Game.me.focus = cast hero;

		if (currentPlanet.type == 2) {
			hero.flControl = false;
		};

		return hero;
	}

	// TOOLS
	public function isFree(x, y, ?bmp:PixelHelper, ?col:Int) {
		if (bmp == null)
			bmp = bmpGroundPx;

		if (bmp == null)
			return true;

		var lim = HEIGHT - bmp.height;

		if (y < lim) {
			return true;
		}

		var px = Std.int(x);
		var py = Std.int(y - lim);
		if (col != null)
			return col != bmp.getPixel(px, py);

		return bmp.getPixelAlpha(px, py) < 100;
	}

	public function isLandingFree(x, y, ?col:Int) {
		return isFree(x, y) && isFree(x, y, bmpDecorPx, col);
	}

	public function getGround(x) {
		var y = HEIGHT - currentPlanet.gMax;
		while (true) {
			if (!isFree(x, y) || y == HEIGHT)
				return y - 1;
			y++;
		}
		return null;
	}

	// INTER
	function initInter() {
		mcInter = cast dm.empty(DP_INTER);
		mcInter._x = Cs.mcw;
		var dm = new mt.DepthManager(mcInter);
		mcInter.fuel = dm.attach("mcInterFuel", 0);
		mcInter.fuel.anchor.set(0, 0);
	}

	public function incMinerai(n:Int) {
		min += n;
		Api.increaseMineralCounter(n);
	}

	public function incCaps(n:Int) {
		chs += n;
	}

	// ENDING
	override public function initEnding(fl) {
		super.initEnding(fl);
		step = End;
		pad.kill();
	}

	override function updateEnding() {
		super.updateEnding();
	}

	override function endGame() {
		var intMin = min - debit;
		var intMis = missile;
		var intCaps = chs;
		var intItem = item;

		Api.endLander(flVictory, intMin, intMis, intCaps, travel, intItem, flMarkHouse);
	}

	// OUTRO
	var mcScreen:display.ASprite;
	var bmpScreen:RenderTexture;

	public function initOutro() {
		step = Outro;
		fadeCoef = 0;
		bmpScreen = RenderTexture.create(Cs.mcw, Cs.mch);
		// bmpScreen.draw(root);
		trace("FIXME");
		dm.destroy();

		mcScreen = dm.empty(0);
		mcScreen.attachBitmap(bmpScreen, 0);
	}

	public function updateOutro() {
		if (fadeCoef < 1) {
			fadeCoef = Math.min(fadeCoef + 0.05 * mt.Timer.tmod, 1);
			Filt.grey(root, fadeCoef);
			if (fadeCoef == 1) {
				// bmpScreen.draw(root._parent);
				mcScreen.removeMovieClip();
				table = cast dm.attach("mcTable", 1);
				table.smc.smc.attachBitmap(bmpScreen, 10);

				root.filters = null;

				var txt = Text.get.OUTRO_0;
				if (Cs.pi.gotItem(MissionInfo.BADGE_FURI))
					txt = Text.get.OUTRO_1;
				table.field.text = txt;
				table.field.height = table.field.height + 10;
			}
		} else {
			var lim = 40 - table.field.height;
			if (table.field.y > lim) {
				var coef = 1;
				if (lander.Game.me.flPress)
					coef = 6;
				table.field.y -= coef * mt.Timer.tmod;
				if (table.field.y < lim)
					table.field.y = lim;
			} else {
				var a = Text.get.OUTRO_2;

				if (table.field.y == lim) {
					table.field.y--;
					for (i in 0...2) {
						var mc:Choice = cast dm.attach("mcChoice", 5);
						mc._y = 65 + 150 * i;
						mc.fieldTitle.text = a[i][0];
						var txt = a[i][1];
						if (i == 0 && !Cs.pi.gotItem(MissionInfo.MODE_DIF))
							txt += "\n<b>" + a[i][2] + "</b>";
						if (i == 1 && !Cs.pi.gotItem(MissionInfo.EARTH_PASS))
							txt += "\n<b>" + a[i][2] + "</b>";
						// txt+="</b>";
						mc.field.text = txt; // Fixme : HTML
						mc.field.y = 60 - mc.field.height * 0.5;
						mc.smc._alpha = 20;
						mc.onRollOver = function() {
							mc.smc._alpha = 60;
						};
						mc.onRollOut = function() {
							mc.smc._alpha = 20;
						};
						mc.onDragOver = mc.onRollOver;
						mc.onDragOut = mc.onRollOut;
						mc.onPress = choice.bind(i);
					}
				}
			}
		}
	}

	public function choice(n) {
		var itemId = null;
		if (n == 0)
			itemId = MissionInfo.MODE_DIF;
		if (n == 1)
			itemId = MissionInfo.EARTH_PASS;
		if (Cs.pi.gotItem(itemId))
			itemId = null;
		Api.endStory(n, itemId);
	}

	//
	override public function kill() {
		super.kill();
	}

	// INFO
	public static var PLANETES:Array<Planete> = [
		{
			type: 0,
			pop: 1.6,
			g: 1.0,
			hor: 80,
			gMax: 120,
			dMax: 400,
			hc: 0.1,
			min: [50, 150],
			gri: [[4, 4, 0xDB0202], [4, 2, 0xFB0D0D]]
		}, // 0 MOLTEAR
		{
			type: 1,
			pop: 2.0,
			g: 0.8,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.25,
			min: [50, 20],
			gri: [[12, 12, 0x58B858], [4, 2, 0xCCFFAA]]
		}, // 1 SOUPALINE
		{
			type: 0,
			pop: 1.4,
			g: 0.7,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.05,
			min: [75, 0],
			gri: [[10, 10, 0x8C4A2F], [4, 2, 0x794028]]
		}, // 2 LYCANS
		{
			type: 0,
			pop: 1.3,
			g: 3.5,
			hor: 120,
			gMax: 200,
			dMax: 440,
			hc: 0.1,
			min: [100, 250],
			gri: [[10, 10, 0xB05E0B], [8, 8, 0xE3B602], [4, 2, 0xFFCC00]]
		}, // 3 SAMOSA
		{
			type: 0,
			pop: 1.3,
			g: 0.7,
			hor: 120,
			gMax: 120,
			dMax: 150,
			hc: 0.35,
			min: [10, 150],
			gri: [[6, 6, 0xEBD994], [4, 2, 0xFCE9A3]]
		}, // 4 TIBOON
		{
			type: 0,
			pop: 2.5,
			g: 2.5,
			hor: 120,
			gMax: 100,
			dMax: 400,
			hc: 0.10,
			min: [100, 0],
			gri: [[8, 8, 0x4E1700], [4, 2, 0x743D19]]
		}, // 5 BALIXT
		{
			type: 0,
			pop: null,
			g: 0.7,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.25,
			min: [50, 10],
			gri: [[12, 12, 0x58B858], [4, 2, 0xCCFFAA]]
		}, // 6
		{
			type: 0,
			pop: 1.2,
			g: 1.5,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.10,
			min: [75, 120],
			gri: [[20, 20, 0xFFFFFF], [4, 2, 0xAAFFFF]]
		}, // 7 SPIGNYSOS
		{
			type: 0,
			pop: 1.5,
			g: 1.8,
			hor: 120,
			gMax: 80,
			dMax: 300,
			hc: 0.25,
			min: [150, 0],
			gri: [[4, 4, 0x58B858], [4, 2, 0xCCFFAA]]
		}, // 8 POFIAK
		{
			type: 0,
			pop: null,
			g: 0.5,
			hor: 160,
			gMax: 0,
			dMax: 0,
			hc: 0.15,
			min: [0, 0],
			gri: [[12, 12, 0], [4, 2, 0]]
		}, // 9 SENEGARDE
		{
			type: 0,
			pop: 1.8,
			g: 2.5,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.1,
			min: [300, 0],
			gri: [[4, 4, 0x8C1408], [8, 4, 0xCF0D41]]
		}, // 10 DOURIV
		{
			type: 0,
			pop: 1.01,
			g: 0.7,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.25,
			min: [10, 0],
			gri: [[10, 10, 0x888888], [6, 4, 0xAAAAAA]]
		}, // 11 GRIMORN
		{
			type: 0,
			pop: 1.4,
			g: 1.0,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.25,
			min: [150, 10],
			gri: [[12, 12, 0x787831], [4, 2, 0x95954E]]
		}, // 12 D-TRITUS
		{
			type: 0,
			pop: 1.01,
			g: 0.2,
			hor: 160,
			gMax: 120,
			dMax: 400,
			hc: 0.0,
			min: [100, 10],
			gri: [[6, 6, 0x835830], [4, 4, 0xA06D3D]]
		}, // 13 ASTEROIDE
		{
			type: 0,
			pop: 2.0,
			g: 1.0,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.1,
			min: [150, 50],
			gri: [[6, 6, 0x34A0A0], [4, 4, 0x4ABFBF]]
		}, // 14 NALIKORS
		{
			type: 0,
			pop: 1.8,
			g: 1.8,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.1,
			min: [100, 50],
			gri: [[6, 6, 0x54104E], [4, 4, 0xA33D88]]
		}, // 15 HOLOVAN
		{
			type: 1,
			pop: 1.5,
			g: 1.2,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.1,
			min: [150, 50],
			gri: [[6, 6, 0x89B388], [4, 4, 0xB0CAAC]]
		}, // 16 KHORLAN
		{
			type: 1,
			pop: 1.5,
			g: 1.5,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.1,
			min: [150, 50],
			gri: [[6, 6, 0x915874], [4, 4, 0xAE7591]]
		}, // 17 CILORILE
		{
			type: 0,
			pop: 1.01,
			g: 1.0,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.25,
			min: [20, 50],
			gri: [[6, 6, 0x7C7869], [4, 4, 0x989489]]
		}, // 18 TARCITURNE
		{
			type: 0,
			pop: 1.01,
			g: 1.0,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.25,
			min: [300, 50],
			gri: [[6, 6, 0x657C77], [2, 2, 0x92A5A1]]
		}, // 19 CHAGARINA
		{
			type: 1,
			pop: 1.5,
			g: 1.0,
			hor: 120,
			gMax: 120,
			dMax: 300,
			hc: 0.25,
			min: [150, 0],
			gri: [[2, 2, 0x7E4686], [2, 2, 0x9F57A8]]
		}, // 20 VOLCER
		{
			type: 0,
			pop: 1.25,
			g: 1.0,
			hor: 120,
			gMax: 120,
			dMax: 400,
			hc: 0.25,
			min: [20, 50],
			gri: [[4, 4, 0x764A38], [6, 4, 0xAC6D53]]
		}, // 21 BALMANCH
		{
			type: 0,
			pop: null,
			g: 0.5,
			hor: 160,
			gMax: 0,
			dMax: 0,
			hc: 0.15,
			min: [0, 0],
			gri: [[12, 12, 0], [4, 2, 0]]
		}, // 22 FOLKET
		{
			type: 2,
			pop: null,
			g: 0.8,
			hor: 120,
			gMax: 80,
			dMax: 400,
			hc: 0.25,
			min: [0, 0],
			gri: [[12, 12, 0x555555], [4, 2, 0x888888]]
		}, // 23 TERRE
	];

	// astero dy:400
	// dec:20
	// gmin:40

	public static function isAlive(id) {
		var pop = PLANETES[id].pop;
		return pop != null && pop >= 1.1;
	}

	// {
} // --- CHECK ---
// MISSION RADAR
// MISSIONS ESCORP
// --- LOLO ---
// MISSIONS - TOUTES LES 10 MISSIONS = +10 CHS
// WRAP -> VOIR POUR L'INTEGRATION DU WRAP-BACK --> MissionInfo.Retrofuser
// --- TODO ---
// INVENTAIRE - JUMELEUR DE BALLE
// INVENTAIRE - CAPSULE
// INVENTAIRE - SALMEEN
// INVENTAIRE - REACTEUR + PODS
// CORRIGER UTILISATION LUNETTE
// CAPSULE FUEL CLIGNOTE QUAND BIENTOT VIDE
// LANDER - DESSINER DES ELEMENTS RARES
// + MISSION POUR DONNER ENVIE DE QUITTER LA ZONE
// + MISSION LORSQUE L'ON PEUT ATTERRIR
// HOUSES - D'autres types de maisons
// HOUSES - inventer missions sup
// --- IMPLEMENTATION ---
// LANCEUR DE BALLE  = same MISSILE
// DRONE TELEGUIDE ?
// PISTOLER LASER + MONSTRE
// /c LARGUER DES BOMBES
// /c POSER DES BOMBES
// /c POUVOIR TIRER DES MISSILES
// --- OBJETS ---
// GYROSTABILISATEUR 		Permet de tourner plus vite
// SCAPHANDRE DE SORTIE		Permet de sortir du pad
// REACTEUR DE SURFACE niv1
// REACTEUR DE SURFACE niv2
// REACTEUR DE SURFACE niv3
// ???				Consomme 2x moins de fuel.
// TRAIN D'ATTERRISAGE
// EXTENSION DE TRAIN
// --- GENERAL ---
// ASTEROIDS ATTERRISSABLES + GENERER CHAMP D'ASTEROIDS
// MAISION
