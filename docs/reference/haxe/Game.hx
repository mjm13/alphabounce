import ImageDataUtils.ColorMatrix;
import pixi.core.math.shapes.Rectangle;
import pixi.resources.Resource;
import StackBlur.BlurStack;
import pixi.core.graphics.Graphics;
import pixi.filters.blur.BlurFilter;
import pixi.core.math.Matrix;
import js.html.KeyboardEvent;
import haxe.ds.StringMap;
import pixi.core.Pixi.BlendModes;
import mt.bumdum.Sprite;
import mt.bumdum.Phys;
import mt.bumdum.Lib;
import mt.bumdum.Plasma;
import mt.bumdum.Bmp;
import Module;

class AnonSprite11542048 extends display.ASprite {
	public var bmp:RenderTexture;
}

class AnonSprite12545856 extends display.ASprite {
	public var field:pixi.core.text.Text;
	public var timer:Float;
}

class AnonSprite16009672 extends McText {
	public var timer:Float;
	public var act:Int;
	public var trg:Int;
}

class AnonSprite16009671 extends display.ASprite {
	public var dm:mt.DepthManager;
	public var lives:Array<display.ASprite>;
	public var mis:McText;
	public var min:AnonSprite16009672;
}

class AnonSprite1466497 extends display.ASprite {
	public var c:Float;
	public var inc:Float;
	public var pow:Float;
}

class AnonSprite15069626 extends display.ASprite {
	public var c:Float;
}

class McText extends ASprite {
	public var field:pixi.core.text.Text;
}

class Plan extends ASprite {
	public var c:Float;
}

class Title extends ASprite {
	public var mcField:McText;
	public var bl:Float;
	public var t:Float;
}

enum Step {
	Play;
	Ending;
}

class Game extends Module { // }
	public static var FL_DEBUG = false;
	public static var PLAY_AUTO = false;

	public static var DP_BG = 0;
	// public static var DP_PLASMA = 		2;
	public static var DP_UNDERPARTS = 3;
	public static var DP_BLOCK = 4;
	public static var DP_PLASMA = 5;
	public static var DP_PAD = 6;
	public static var DP_OPTION = 7;
	public static var DP_BALL = 8;
	public static var DP_PARTS2 = 9;
	public static var DP_DRONE = 10;
	public static var DP_MONSTER = 11;
	public static var DP_PARTS = 12;
	public static var DP_FRONT_PARTS = 13;
	public static var DP_FRONT = 14;
	public static var DP_INTER = 15;
	public static var DP_PAUSE = 16;

	public var flFirstBall:Bool;
	public var flItemFall:Bool;
	public var flSwap:Bool;

	public var flSafe:Bool;
	public var flItemCollected:Bool;

	var step:Step;

	public var life:Int;

	public var missileType:Int;
	public var missileCadence:Float;
	public var missileTurnSpeed:Float;
	public var difficulty:Float;

	public var block:Int;

	var spaceColor:Int;
	var blockTotal:Int;
	var accTimer:Float;
	var scroll:Float;
	var timeCoef:Float;

	public var shake:Float;
	public var levelTimer:Float;
	public var autoLaunchTimer:Float;
	public var inactiveTimer:Float;
	public var respawnTimer:Float;

	public var grid:StringMap<Block>;
	public var blocks:Array<Block>;
	public var crawlers:Array<{update:Void->Void}>;
	public var monsterGrid:StringMap<Array<el.Molecule>>;

	public var balls:Array<el.Ball>;
	public var options:Array<Option>;
	public var events:Array<Event>;
	public var titles:Array<Title>;
	public var molecules:Array<el.Molecule>;

	public var specialSpent:Array<Int>;

	public var pad:Pad;

	public static var me:Game;

	public var bdm:mt.DepthManager;

	public var base:display.ASprite;

	public var bg:display.ASprite;
	public var mcSunglasses:display.ASprite;

	public var mcPlasma:PixelHelper;
	public var mcPlasmaResource:Resource;
	public var mcTitle:AnonSprite12545856;

	public var mcInter:AnonSprite16009671;
	public var mcFlash:AnonSprite1466497;
	public var mcCursor:display.ASprite;
	public var mcWarning:McText;
	public var bmpBg:RenderTexture;

	public function new(mc:display.ASprite, col:Int) {
		me = this;
		super(mc);

		base = dm.empty(DP_BLOCK);
		Filt.glow(base, 4, 2, 0xFFFFFF);
		bdm = new mt.DepthManager(base);

		spaceColor = col;
		flPause = false;
		flSwap = false;
		flItemFall = false;
		flItemCollected = false;

		//
		balls = [];
		options = [];
		events = [];
		titles = [];
		crawlers = [];
		molecules = [];
		monsterGrid = new StringMap();
		for (x in 0...Cs.XMAX) {
			for (y in 0...Cs.YMAX)
				monsterGrid.set('${x},${y}', []);
		}

		min = 0;
		accTimer = 0;
		// level.lvl = 0; // Level is not defined yet
		pauseCount = 0;

		difficulty = Cs.pi.gotItem(MissionInfo.MODE_DIF) ? 2 : 1;

		life = Cs.pi.getLife();

		missile = Cs.pi.missile;
		missileType = Cs.pi.getMissileType();

		missileCadence = Cs.pi.getMissileCadence(); // 4;
		missileTurnSpeed = Cs.pi.getMissileTurnSpeed();

		// PAD
		newPad();

		//
		if (Cs.PREF_GFX > 0.5)
			initPlasma();
		// initMouseListener();
		initKeyListener();
		initInter();
		//

		initCursor();
		//
		mouseMove();
		//
		if (Cs.pi.missileMax > 0 && Cs.pi.shopItems[ShopInfo.MISSILE_GENERATOR] == 1)
			incMissile(1);

		// haxe.Log.clear();
	}

	// BG
	public function initBg() {
		var rx = wx - navi.Map.SX;
		var ry = wy - navi.Map.SY;

		bg = dm.empty(0);
		bmpBg = getBmpBg(spaceColor);

		// ELEMENTS
		var zid = level.zid;
		if (zid != null)
			drawPlanet(zid, BmpTextureHelper.getASprite("mcZone"));

		var s = bg.attachBitmap(bmpBg, 0);
		s.x = -Module.Margin;
		s.y = -Module.Margin;

		// SUNGLASSES
		if (Cs.pi.shopItems[ShopInfo.SUNGLASSES] == 1) {
			var o = Col.colToObj(spaceColor);
			var br = Math.max(Math.max(o.r * 0.7, o.g), o.b * 0.4);
			if (br > 100) {
				mcSunglasses = new ASprite([Cs.mcw, Cs.mch]);
				mcSunglasses.beginFill(0x000000);
				mcSunglasses.drawRect(0, 0, Cs.mcw, Cs.mch);
				mcSunglasses.alpha = 0.2;
				bg.addChild(mcSunglasses);
			}
		}
	}

	function drawPlanet(zid, mc:ASprite) {
		mc.gotoAndStop(zid + 1);
		var zi = ZoneInfo.list[zid];

		var m = new Matrix();
		m.scale(20, 20);
		m.translate((zi.pos[0] - wx) * Cs.mcw + Module.Margin, (zi.pos[1] - wy) * Cs.mch + Module.Margin);
		var c = 1;

		//Col.setColor(mc, spaceColor);
		bmpBg.draw(mc, m);

		// BASE
		var fl = new BlurFilter();
		fl.blurX = 0.4;
		fl.blurY = 0.4;
		mc.filters = [fl];
		// fl.apply(##, bmp, bmp, PIXI.CLEAR_MODES.AUTO); // bmp.applyFilter(bmp, bmp.rectangle, new flash.geom.Point(0, 0), fl);

		/*// TEXTURE
		var text = RenderTexture.create(Cs.mcw, Cs.mch);
		var seed = new mt.OldRandom(level.wx * 10000 + level.wy);
		// text.perlinNoise(Cs.mcw, Cs.mch, 4, seed.random(1000), false, false, null, true);

		// var ct = new flash.geom.ColorTransform(1, 1, 1, 0.4, 0, 0, 0, 0);
		// bmp.draw(text, new Matrix(), ct, "add");

		// DRAW
		var inc = -30;
		// var ct = new flash.geom.ColorTransform(1, 1, 1, 1, inc, inc, inc, 0);*/
		bmpBg.draw(mc, m);
		//text.destroy();
	}

	// INTER
	function initInter() {
		if (Cs.DEMO)
			return;

		mcInter = cast dm.empty(DP_INTER);
		mcInter.dm = new mt.DepthManager(mcInter);
		mcInter._y = Cs.mch;

		// SPECIALS
		initSpecials();
		placeSpecials();
		// MISSILES
		mcInter.mis = cast mcInter.dm.empty(0);
		mcInter.mis.smc = mcInter.mis.attachMovie("mcMissile", "smc", 0);
		mcInter.mis.smc.x = -10;
		mcInter.mis.smc.y = -2;
		mcInter.mis.smc.scale.set(0.56, 0.56);
		mcInter.mis.smc.rotation = 4.7124;
		mcInter.mis.initTextField("field", {
			x: -12,
			y: -12,
			align: "right",
			font: "GAU_font_cube_B",
			size: 11,
			color: 0xFFFFFF
		});

		mcInter.mis.smc.gotoAndStop(missileType + 1);
		Filt.glow(mcInter, 2, 4, 0);
		incMissile(0);

		// LIVES
		mcInter.lives = [];
		for (n in 0...life)
			newLife(n);
	}

	public function newLife(n, ?flSpark) {
		var mc = mcInter.dm.attach("mcLife", 0);
		mc.removeOnFrame = 7;
		mc._x = 2 + n * 30;
		mc._y = -10;
		mcInter.lives.push(mc);

		if (flSpark) {
			for (n in 0...32) {
				var p = new Phys(dm.attach("partSpark", Game.DP_INTER));
				// p.vy = -1;
				p.x = mcInter._x + mc._x + (Math.random() * 2 - 1) * 10;
				p.y = mcInter._y + mc._y + Math.random() * 3;
				p.weight = -(0.05 + Math.random() * 0.2);
				p.timer = 10 + Math.random() * 10;
				p.sleep = n * 0.5;
				p.fadeType = 0;
				p.setScale(100 + Math.random() * 150);
				p.root.blendMode = pixi.core.Pixi.BlendModes.ADD;
			}
		}
	}

	public function incMissile(n) {
		// missile = Std.int( Math.min(missile+n,Cs.pi.missileMax));
		missile += n;
		if (missile > Cs.pi.missileMax)
			missile = Cs.pi.missileMax;

		mcInter.mis.field.text = Std.string(missile) + "/" + Cs.pi.missileMax;
		mcInter.mis._visible = missile > 0;
		mcInter.mis._x = Cs.mcw - specials.length * 11;
	}

	public function incMinerai(n:Int) {
		/*
			if( mcInter.min == null ){
				mcInter.min = cast mcInter.dm.attach("mcMinCounter",DP_INTER);
				mcInter.min._x = Cs.mcw;
				mcInter.min._y = -Cs.mch;
				mcInter.min.act = min;
				mcInter.min.field.text = Std.string(mcInter.min.act);
			}

			mcInter.min.trg = min+n;
			mcInter.min.timer = 30;
			mcInter.min._alpha = 100;
		 */

		//
		Api.increaseMineralCounter(n);
		min += n;

		//
	}

	function updateInter() {
		if (mcInter.min != null) {
			if (mcInter.min.trg > mcInter.min.act) {
				mcInter.min.act++;
				mcInter.min.field.text = Std.string(mcInter.min.act);
			} else {
				mcInter.min.timer -= mt.Timer.tmod;
				var lim = 10;
				if (mcInter.min.timer < lim)
					mcInter.min._alpha = (mcInter.min.timer / lim) * 10;
				if (mcInter.min.timer < 0) {
					mcInter.min.removeMovieClip();
					mcInter.min = null;
				}
			}
		}
	}

	// CURSOR
	function initCursor() {
		if (Cs.DEMO)
			return;
		mcCursor = Manager.dm.attach("mcCursor", 11);
		mcCursor.anchor.set(0.5, 0.5);
		mcCursor._alpha = 50;
	}

	function updateCursor() {
		if (Cs.DEMO)
			return;

		mcCursor._x = Pad.getPadX();
		mcCursor._y = Cs.MY;

		var m = 0;
		if (!flPause && (mcCursor._x > Cs.mcw + m || mcCursor._x < -m || mcCursor._y > Cs.mch + m || mcCursor._y < -m)) {
			if (mcWarning == null && Cs.PREF_BOOLS[2]) {
				mcWarning = cast dm.attach("mcWarning", DP_INTER);
				mcWarning.initTextField("field", {
					size: 16,
					font: "GAU_font_cube_B",
					x: 200,
					y: 0,
					align: "center",
					color: 0xFFFFFF
				});
				mcWarning.field.text = Text.get.WARNING_ZONE;
			}
		} else {
			if (mcWarning != null) {
				mcWarning.removeMovieClip();
				mcWarning = null;
			}
		}
	}

	// UPDATE
	override public function update() {
		super.update();

		if (mcFlash != null)
			updateFlash();
		updateCursor();
		updateTitle();

		if (pauseCoef != null)
			return;

		if (pad != null && pad.flStop) {
			if (timeCoef == null)
				timeCoef = 1;
			timeCoef = Math.max(timeCoef - 0.3 * mt.Timer.tmod, 0.1);
		} else {
			if (timeCoef != null) {
				timeCoef = Math.min(timeCoef + 0.08 * mt.Timer.tmod, 1);
				if (timeCoef == 1)
					timeCoef = null;
			}
		}

		if (timeCoef != null)
			mt.Timer.tmod = timeCoef;

		if (step != null) {
			switch (step) {
				case Play:
					updatePlay();
				case Ending:
					updateEnding();
			}
		}

		updatePlasma();
		updateInter();

		flClick = false;

		//
		if (respawnTimer != null) {
			respawnTimer -= mt.Timer.tmod;
			if (respawnTimer <= 0) {
				newPad();
				respawnTimer = null;
			}
		}

		//
		if (shake != null) {
			if (Math.abs(shake) < 1)
				shake = 0;
			base._y = shake;
			shake *= -0.75;
			base.filters = null;

			if (shake == 0) {
				shake = null;
			} else {
				Filt.blur(base, 0, Math.abs(shake));
			}
		}

		//
		Plasma.updateAll();
	}

	// PLAY
	override public function initPlay() {
		step = Play;

		// trace("");
		// trace(7+level.dst*0.35);

		/*
			var b = newBall();
			var rnd = (Math.random()*2-1);
			if(!PLAY_AUTO)b.gluePoint = rnd*20;
			b.moveTo(pad.x,pad.y);
			b.vx=0;
			b.vy=1;
			b.update();
			b.colPad(rnd);
		 */

		levelTimer = 0;
		autoLaunchTimer = 0;
		// flSafe = level.lvl == 0;
	}

	function updatePlay() {
		/*
			haxe.Log.clear();j
			for( y in 0...Cs.YMAX ){
				var str = "";
				for( x in 0...Cs.XMAX )	str+= monsterGrid.get('${x},${y}').length+"-";
				trace(str);
			}
			// */

		//
		if (!flFirstBall) {
			levelTimer += mt.Timer.tmod;
			autoLaunchTimer += mt.Timer.tmod;
		}
		if (autoLaunchTimer > 200) {
			autoLaunchTimer = 0;
			for (b in balls)
				b.unglue();
		}

		// BALL ACCELERATION
		var mult = 1.0;
		if (level.lvl >= 10)
			mult = level.lvl * 0.1;
		mult *= difficulty;
		if (!flFirstBall)
			accTimer += mult * mt.Timer.tmod;
		if (accTimer > Cs.TEMPO) {
			for (b in balls) {
				if (b.speed < (7 + level.dst * 0.35) * difficulty)
					b.setSpeed(b.speed + 0.5);
			}
			accTimer = 0;
		}

		// INACTIVE
		if (!flFirstBall)
			inactiveTimer += mt.Timer.tmod;
		var timer = 200 + block * 40 - inactiveTimer;
		if (timer < 200) {
			var c = 1 - timer / 200;
			mcCursor.gotoAndStop(Std.int(c * 160) + 1);
		} else {
			mcCursor.gotoAndStop(1);
		}
		if (timer < 0) {
			if (pad != null) pad.initCharge();
			inactiveTimer = 0;
		}

		// UPDATE
		updateSprites();
		for (e in events)
			e.update();
		for (c in crawlers)
			c.update();
	}

	public function removeBlock() {
		inactiveTimer = 0;
		block--;
		var c = block / blockTotal;
		if (block == 0)
			initEnding(true);
	}

	function cleanAll() {
		while (balls.length > 0)
			balls.pop().kill();
		while (options.length > 0)
			options.pop().kill();
		while (events.length > 0)
			events[0].kill();
		while (crawlers.length > 0)
			crawlers.pop();
	}

	// VICTORY
	override public function initEnding(flVictory) {
		super.initEnding(flVictory);

		if (Cs.DEMO) {
			Demo.me.timer = -1;
			return;
		}

		/*
			if(step==Ending(true) ){
				trace("error ending++");
				return;
			}
		 */
		step = Ending;
		for (b in balls)
			b.flImmortal = true;
		for (mc in titles)
			mc.removeMovieClip();
	}

	override function updateEnding() {
		super.updateEnding();
		if (flEndConnect)
			return;

		// TIMER
		if (flItemFall)
			victoryTimer = 0;
		var lim = 50;
		if (victoryTimer > lim && pad != null) {
			pad.y += (victoryTimer - lim) * 2;
		}

		// SPRITES
		updateSprites();
		for (e in events)
			e.update();
		for (c in crawlers)
			c.update();

		/*
			if( !flEndConnect && victoryTimer > 60 ){
				flEndConnect = true;
				cleanAll();
				//navi.Map.me.initInter();
				navi.Map.me.initConnexion();


				navi.Map.me.setTimeOut(1200);
			}
		 */
	}

	override function endGame() {
		cleanAll();
		var item = null;
		if (flItemCollected)
			item = level.itemId;
		if (flVictory) {
			if (Cs.pi.items[level.itemId] == MissionInfo.TRIGGER) {
				item = level.itemId;
			}
		}

		var intMin = min;
		var intMis = missile;
		Api.endGame(wx, wy, flVictory, intMin, intMis, item, specialSpent);
	}

	// PAD
	function newPad() {
		pad = new Pad(dm.empty(DP_PAD));
		if (respawnTimer != null) {
			mcInter.lives.pop().play();
			pad.init();
			life += -1;
			pad.y = 500;
		}
	}

	public function killPad() {
		pad.explode(Game.me.dm.empty(Game.DP_PARTS));
		pad = null;
		while (balls.length > 0)
			balls.pop().kill();
		if (life > 0) {
			respawnTimer = 30;
		} else {
			initEnding(false);
		}
	}

	// OPTIONS
	public function newOption(t, ?x, ?y) {
		// Api.error("Erreur de reception des données. Cette erreur peut etre provoquée par l'ouverture de deux sessions dans des onglets ou navigateurs différents.");

		if (x == null)
			x = pad.x;
		if (y == null)
			y = pad.y - 60;
		var opt = new Option(dm.attach("mcOption", DP_OPTION));
		opt.x = x;
		opt.y = y;
		opt.setType(t);
	}

	public function getOption(id) {
		switch (id) {
			case 0: // A IMANT
				pad.setType(Cs.PAD_AIMANT);

			case 1: // B LINDAGE
				for (bl in blocks)
					if (bl.type < 5)
						bl.setLife(bl.life + 1);

			case 2: // C OLLE
				pad.setType(Cs.PAD_GLUE);

			case 3: // D IMINUTION
				pad.setRay(Math.max(pad.ray - 15, Pad.SIDE + 1));
				pad.powerUp();

			case 4: // E XTENSION
				pad.setRay(Math.min(pad.ray + 15, 80));
				pad.powerUp();

			case 5: // F LAMME
				for (b in balls)
					b.setType(Cs.BALL_FIRE);

			case 6: // G LACE
				for (b in balls)
					b.setType(Cs.BALL_ICE);

			case 7: // H ALO
				for (b in balls)
					b.setType(Cs.BALL_HALO);

			case 8: // I NDISGESTION
				// for( i in 0...10 )new fx.Fly(null);
				// pad.moveFactor *= -1;
				new ev.Indigestion();

			case 9: // J AVELOT
				pad.initCharge();

			case 10: // K AMIKAZE
				for (b in balls)
					b.setType(Cs.BALL_KAMIKAZE);

			case 11: // L ASER
				pad.setType(Cs.PAD_LASER);

			case 12: // M ULTI-BALL
				var list = balls.copy();
				for (b in list) {
					if (balls.length >= Cs.MAX_BALL)
						break;
					if (b.type != Cs.BALL_SHADE) {
						var ball = b.clone();
						var a = Math.atan2(b.vy, b.vx);
						var ma = 0.15;
						ball.vx = Math.cos(a + ma) * ball.speed;
						ball.vy = Math.sin(a + ma) * ball.speed;
						b.vx = Math.cos(a - ma) * b.speed;
						b.vy = Math.sin(a - ma) * b.speed;
					}
				};

			case 13: // N OUVELLE BALLE
				var b = pad.initStartBall();
				b.fxLight();
			// pad.setType(Cs.PAD_SHAKE);

			case 14: // O UVRE
				new ev.Ouverture();

			case 15: // P ROVISION
				missile = Cs.pi.missileMax;
				incMissile(0);

			case 16: // Q UASAR
				new ev.Quasar();

			case 17: // R EGENERATION
				pad.setType(Cs.PAD_GENERATOR);

			case 18: // S ECONDE CHANCE
				newLife(life, true);
				life += 1;

			case 19: // T EMPORALITE
				pad.setType(Cs.PAD_TIME);

			case 20: // U LTRAVIOLET
				new ev.UltraViolet();

			case 21: // V OLT
				for (b in balls)
					b.setType(Cs.BALL_VOLT);

			case 22: // W HISKY
				for (b in balls)
					b.setType(Cs.BALL_DRUNK);

			case 23: // X ANAX
				for (b in balls)
					b.setSpeed(Math.max(b.speed - 5, 3));

			case 24: // Y OYO
				for (b in balls)
					b.setType(Cs.BALL_YOYO);

			case 25: // Z ELE
				for (b in balls)
					b.setSpeed(b.speed + 5);

			case 26: // MISSILE
				// missile;
				// if(missile>Cs.pi.missileMax)missile = Cs.pi.missileMax;
				incMissile(1);
		}

		// TITLE
		newTitle(Text.get.OPTION_NAMES[id], Option.getCol(id));
	}

	// SPECIAL
	public function initSpecials() {
		while (specials != null && specials.length > 0)
			specials.pop().removeMovieClip();
		specials = [];
		var a = [ShopInfo.BLACKHOLE, ShopInfo.ICE, ShopInfo.FIRE, ShopInfo.STORM];

		var id = 0;
		for (sid in a) {
			if (Cs.pi.shopItems[sid] == 1) {
				var mc:Special = cast mcInter.dm.attach("mcSpecial", 0);
				// mc._x = Cs.mcw - specials.length*ssize;
				mc.gotoAndStop(id + 1);
				mc.id = id;
				mc.sid = sid;
				specials.push(mc);
			}
			id++;
		}
	}

	public function placeSpecials() {
		var id = 1;
		for (mc in specials) {
			mc._x = Cs.mcw - id * 11;
			mc._y = -12;
			id++;
		}
	}

	override public function useSpecial(?id) {
		if (specials.length == 0)
			return;

		var mc:Special = null;
		var i = 0;
		for (spec in specials) {
			if (spec.id == id) {
				mc = spec;
				specials.splice(i, 1);
				break;
			}
			i++;
		}

		if (id == null)
			mc = specials.shift();

		switch (mc.id) {
			case 0:
				new ev.Quasar();
			case 1:
				for (b in balls)
					b.setType(Cs.BALL_ICE);
			case 2:
				for (b in balls)
					b.setType(Cs.BALL_FIRE);
			case 3:
				for (b in balls)
					b.setType(Cs.BALL_VOLT);
		}
		//
		if (specialSpent == null)
			specialSpent = [];
		specialSpent.push(mc.sid);
		//
		mc.removeMovieClip();
		placeSpecials();
		incMissile(0);

		//
		setFlash(1);

		if (flPause) {
			togglePause();
			pauseCoef = 0;
		}
	}

	// GRID
	override public function initLevel(x, y, zid, flMinerai, ?lvl) {
		super.initLevel(x, y, zid, flMinerai, lvl);

		//
		initBg();
		pad.init();
		initGrid();
		fillGrid();
	}

	function initGrid() {
		/*
			var generator = new LevelGenerator(wx,wy);
			generator.build();
			grid = generator.grid();
		 */
		grid = new StringMap();
		for (x in 0...Cs.XMAX) {
			for (y in 0...Cs.YMAX) {
				grid.set('${x},${y}', null);
			}
		}
	}

	function fillGrid() {
		bdm.clear(0);

		level.genModel();
		level.genPalette();

		block = 0;
		blocks = [];
		level.genBonusTable();

		if (Cs.pi.gotItem(MissionInfo.MINES)) {
			var max = 1;
			if (Cs.pi.shopItems[ShopInfo.MINE_0] == 1)
				max++;
			if (Cs.pi.shopItems[ShopInfo.MINE_1] == 1)
				max++;
			if (Cs.pi.shopItems[ShopInfo.MINE_2] == 1)
				max++;
			for (i in 0...max)
				level.addMine();
		}

		// BLOCKS
		for (y in 0...Cs.YMAX) {
			for (x in 0...Cs.XMAX) {
				var type = level.model.get('${x},${y}');
				if (level.flDepleted && type >= Block.BONUS && type < Block.BONUS + Block.BONUS_MAX) {
					type = Block.DEPLETED;
				}
				if (type != null) {
					var bl = new Block(x, y, type);
				}
			}
		}

		//
		blockTotal = block;
	}

	public function hit(px:Int, py:Int, ball) {
		var g = grid.get('${px},${py}');
		if (g != null)
			g.damage(ball);
	}

	public function killZone(px:Int, py:Int) {
		var a = Game.me.monsterGrid.get('${px},${py}');
		while (a != null && a.length > 0)
			a.pop().explode();
	}

	// TITLES
	public function newTitle(str, col, ?flBlink, ?time) {
		var mc:Title = cast dm.empty(DP_INTER);
		mc.mcField = cast mc.createEmptyMovieClip("mcField", 0);
		mc.mcField.initTextField("field", {
			size: 24,
			color: 0xFFFFFF,
			align: "center",
			font: "Kiloton Condensed Italic",
			x: 200,
			y: -12,
		});
		mc.mcField.field.text = str;
		mc.bl = 100;
		mc.t = time;
		if (mc.t == null)
			mc.t = 32;
		mc._y = 12;
		mc._yscale = 10;
		if (flBlink == null)
			mc.mcField.stop();
		Filt.glow(cast mc.mcField, 4, 2, col);

		titles.unshift(mc);
	}

	function updateTitle() {
		var i = 0;
		while (i < titles.length) {
			var mc = titles[i];
			mc.t -= mt.Timer.tmod;
			if (i == 0 && mc.t > 0) {
				mc.bl *= 0.5;
				if (mc.bl < 0.5)
					mc.bl = 0;
				mc._yscale = Math.max(100 - mc.bl, 10);
			} else {
				mc._yscale *= 0.75;
				mc.bl += 20;
				if (mc.bl > 100) {
					mc.removeMovieClip();
					titles.splice(i--, 1);
				}
			}
			if (mc.bl > 0) {
				mc.filters = null;
				Filt.blur(mc, mc.bl, 0);
			}
			i++;
		}
	}

	// LISTENERS
	override public function mouseDown() {
		super.mouseDown();
		autoLaunchTimer = 0;

		if (mcTitle != null) {
			mcTitle.timer = 0;
		}

		if (pad != null)
			pad.action();
	}

	override public function mouseUp() {
		super.mouseUp();
		if (pad != null)
			pad.release();
	}

	override function mouseMove() {
		super.mouseMove();
		if (pad != null) {
			pad.flMouse = true;
		}
	}

	// PLASMA
	function initPlasma() {
		var w = Std.int(Cs.mcw * Cs.PQ);
		var h = Std.int(Cs.mch * Cs.PQ);

		var plasmaRoot = cast dm.empty(DP_PLASMA);
		plasmaRoot.blendMode = pixi.core.Pixi.BlendModes.ADD;

		mcPlasma = pixi.core.textures.RenderTexture.create(w, h).extract();

		var mcPlasmaTexture:Texture = mcPlasma.getTexture();
		var plasmaSprite = new pixi.core.sprites.Sprite(mcPlasmaTexture);
		plasmaRoot.scale.set(1 / Cs.PQ);
		plasmaRoot.addChild(plasmaSprite);

		mcPlasmaResource = untyped mcPlasmaTexture.baseTexture.resource;
	}

	function updatePlasma() {
		// BLUR
		var cm = new ColorMatrix();
		cm.alphaOffset = -2;
		var bl = Math.max(2, mt.Timer.tmod * 4 * Cs.PQ);
		StackBlur.__stackBlurCanvasRGBA(mcPlasma, mcPlasma.width, mcPlasma.height, bl, bl, 1);
		ImageDataUtils.colorTransform(mcPlasma, new Rectangle(0, 0, mcPlasma.width, mcPlasma.height), cm);
		mcPlasmaResource.update();
	}

	public function plasmaDraw(mc:display.ASprite) {
		var m = new Matrix();
		m.scale(mc.scale.x * Cs.PQ, mc.scale.y * Cs.PQ);
		m.rotate(mc._rotation * 0.0174);

		var plasma = RenderTexture.create(mcPlasma.width, mcPlasma.height);
		plasma.draw(mc, m);
		var plasmaPx = plasma.extract();
		var cm = new ColorMatrix();
		cm.alphaMultiplier = mc.alpha;
		ImageDataUtils.colorTransform(plasmaPx, new Rectangle(0, 0, mc.width, mc.height), cm);
		mcPlasma.copyPixels(plasmaPx, new Rectangle(0, 0, mcPlasma.width, mcPlasma.height), new pixi.core.math.Point(0, 0), null, null, true);
		plasma.destroy(true);

		// var ct = new flash.geom.ColorTransform(1, 1, 1, mc._alpha / 100, 0, 0, 0, 0);

		// trace('FIXME');
	}

	// DISPLAY SCORE
	public function displayScore(x, y, sc, ?col, ?size:Float) {
		if (col == null)
			col = 0x222288;
		if (size == null)
			size = 1;

		var psc = new Phys(Game.me.dm.attach("mcScore", Game.DP_PARTS));
		psc.x = x;
		psc.y = y;
		psc.vy = -0.5;
		psc.timer = 30;
		var field:pixi.core.text.Text = (cast psc.root).field;
		field.text = Std.string(sc);
		psc.fadeLimit = 5;
		psc.fadeType = 0;
		psc.setScale(100 * size);
		Filt.glow(cast field, 4, 2, col);
	}

	// FX
	public function setFlash(?c:Float, ?inc:Float, ?pow:Float) {
		if (c == null)
			c = 1;
		if (inc == null)
			inc = -0.1;
		if (pow == null)
			pow = 0.5;

		if (mcFlash == null) {
			mcFlash = cast dm.attach("mcFlash", DP_FRONT);
			mcFlash.blendMode = BlendModes.ADD;
		}
		mcFlash.c = c;
		mcFlash.inc = inc;
		mcFlash.pow = pow;
	}

	public function updateFlash() {
		mcFlash.c = Num.mm(0, mcFlash.c + mcFlash.inc * mt.Timer.tmod, 5);
		if (mcFlash.c == 0) {
			mcFlash.removeMovieClip();
			mcFlash = null;
			return;
		}
		mcFlash._alpha = Math.pow(mcFlash.c, mcFlash.pow) * 100;
	}

	public function swapScreen() {
		flSwap = !flSwap;
		if (flSwap) {
			root._yscale = -100;
			root._y = Cs.mch;
		} else {
			root._yscale = 100;
			root._y = 0;
		}
	}

	// TOOLS
	public function newBall() {
		var ball = new el.Ball(dm.attach("mcBall", DP_BALL));
		return ball;
	}

	public function isFree(px:Int, py:Int) {
		return grid.get('${px},${py}') == null && px >= 0 && px < Cs.XMAX && py >= 0;
	}

	public function getLowestBall() {
		var ball:el.Ball = null;
		for (b in balls) {
			if (ball == null || (b.flUp && b.y > ball.y && b.vy > 0)) {
				if (b.gluePoint == null)
					ball = b;
			}
		}
		return ball;
	}

	// PROTOCOLE
	/*
		public function error(str:String){
			var head = str.substr(0,3);
			if( head.indexOf("CRC")==1 || head.indexOf("crc")==1 ){

			}else{
				trace(str);
			}
			// ;
			// mcBar.field.text = str.toUpperCase;
		}
	 */
	// KILL
	override public function kill() {
		// mcPlasma.bmp.destroy();
		bmpBg.destroy();
		var list = Sprite.spriteList.copy();
		for (sp in list)
			sp.kill();
		me = null;

		super.kill();
	}

	// AUTO
	public function updateAuto() {
		// AUTO CLICK
		if (pad.type == Cs.PAD_LASER || pad.type == Cs.PAD_GLUE || pad.chargeTimer > 30 + Std.random(100)) {
			if (flPress)
				mouseUp();
			if (Math.random() < 0.07) {
				mouseDown();
			}
		}
	}

	// PAUSE
	override public function togglePause() {
		if (step == Ending && !flPause) {
			return;
		}

		super.togglePause();
	}

	// DEBUG
	function initKeyListener() {
		js.Browser.window.addEventListener("keydown", pressKey);
	}

	function pressKey(e:KeyboardEvent) {
		var n = e.keyCode;
		// if( n==flash.Key.SPACE )mouseDown();

		// initVictory();

		switch (n) {
			case 13: // ENTER
				useSpecial();

			case 80: // P AUSE
				togglePause();

			case 27: // ESC AUSE
				togglePause();
		}

		if (Cs.pi.flAdmin) {
			var al = 65;
			if (n >= al && n < al + 26)
				newOption(n - al);
		}
	}

	// {
}
/*
	Les limitation de prix imposées aux marchands interstellaires par le traité de Sproutch viennent d'être abrogées.
	"La libre concurrence entre marchands itinerants est une bonne chose pour l'économie de la galaxie, au final, le client profitera des meilleurs prix s'il prend la peine de choisir le bon magasin ! " a déclaré Moldane propriétaire de la "Belle-Lycanaise" Epicerie fine orbitale [-8][14].


 */ // NOM DES CPASULES A TRADUIRE
// CORRIGER BUG MARCHAND SOL
// X INVENTAIRE SALMEEN + ROLLOVER DES PASSAGERS
// X MONTER LE PRIX DES CHS
// X BUG BLOCK PUSH Avec explosion
// X ayohan3 : il lui manque bien un des elements.
// X moussman23 == moussman2316 ?
// X SHOP - RADIO A LONGUE PORTEE
// X SHOP - PRIX DYNAMICS
// X INV - ECHANGE CONVERTISSEUR / COLLECTEUR
// X INV - PB AFFICHAGE MISSILE
// X INTEGRER PLANETE DETRITUS
// X BUG - TRANSFORMEUR + BRIQUE MOLECULE ?
// X REPARER LE MESSAGE CONNEXION PERDUE
// X PLANETE BALIXT PLUS  VISIBLE
// X PREFERENCE - DETOURAGE DE BALL
// X PREFERENCE - MOUVEMENT AU CLAVIER
// X BUG INDIGESTION SUR BRIQUE INVISIBLE
// X TRANSOFRMATION + BRIQUE INSECTE
// X AMELIORER COMPREHENSION ITINERAIRE = click sur pass
// X PROBLEME BRIQUES MARRONS
// X CHANCER LE DETOURAGE DES COORDS
// X DIMINUTION DIFFICULTE
// X INTERFACE -> voir moteur + vies
// X REMPLIR MISSION AVEC GENERATEUR 2
// X REVOIR RESERVOIR VIDE BOX
// X EDITOR - AJOUTER CONG FERREUX.
// X ESPACE DANS LES COORD DES TEXTES.
// X CURSEUR ROLLOVER COORD.
// X MAP - CLIGNOTEMENT VERT MOISN INTENSE.
// X ABUS PAUSE
// X ADMIN BUILD LEVEL AVEC TOUTE LES BRIQUES
// X TIMEOUT
// X DEEP - DEBRIEFING EN PLEIN ECRAN PAR DESSUS ( voir avec warp )
// X LOLO - DEBUT = 12 CH Solide
// X COMPLETION POURCENTAGE >0 voir lolo
// X MISSION DOUGLAS -> principal
// X MISSION SOUPALINE -> plus loin.
// X TEXTES -> DOUGLAS != AIDE
// X MINERAI GRIS.
// X MISSION - RADAR NON FONCTIONNEL ( pas trouvé en boutique )
// X INTER - DRONE DE SOUTIEN S AFFICHE QUAND ON L'A PAS.
// X INTER - TOOLTIPS SUR LES PASS
// X BUG - PAD APPARAIT HORS-CHAMPS
// X OPTION - TRON / TIMIDE / TENTACULE / TORNADE
// X OPTION - INDIGESTION - EXPAND FILL
// X CASE ? --> BRIQUE STANDARD + OPTION SPEC BLOQUE ENDING
// X GAMEPLAY - VERIFIER PLANETES
// X GAMEPLAY - ENLEVER MINERAI SUR GRIMORN ET TIBOON
// X COMPATIBILITE -  tir balle sur salve = probleme avec nouvelle balle.
// X GAMEPLAY - AJOUTER MINERAI SUR DOURIV
// X FAIRE ICONES MANQUANTS.
// X INTERFACE - affichage pourcentage
// X INTERFACE - affichage hint
// X MOUSE - CADRE ROUGE SI SORTIE DE ZONE
// X POINTEUR UNIQUEMENT SUR ZONE VERTE.
// X TEMPS DE DEPART DESACTIVE pour debut + nouveau pad.
// X REDUIRE ANGLE DEMARRAGE BALLE.
// X MINERAI - REGARDER UPDATE MINERAI TEMPS REEL
// X GAMEPLAY - CEINTEURE FERREUSE --> LINES
// X SHOP - DESCRIPTION ITEMS
// X VOIR LES MISSILES MAX
// X JAVELOT - SURLIGNE LIGNE DE BRIQUES.
// X JAVELOT - CHARGEMENT SUR CURSEUR
// X PARAMETRES DE JEUX EDITABLES
// X GAME - TITLE SUR ITEM RAMASSE.
// X MISSION CREATION DES VIGNETTES EN 100x100
// X COLLE TIRER BALLE SUR PRESS
// X boutons sur super attaque
// X SHOP - CAPSULE ECLAIR.
// X SHOP - REMPLACER GRAPH CAPSULE HYDROGENE.
// X SHOP - SKIN radar de secours
// X BUG HALO + COLLE
// X BUG HALO + AIMANT
// X PROBLEME - MISSILE PAS ASSEZ JOUABLE
// X BLOCK - reapparait quand sous la balle
// X BLOCK - missile
// X Remplacer curseur souris.
// X SOURIS + PAD = +de sensibilité.
// X FX BLUR ADD BLANC QUAND LE PAD MEURT
// X FX BALL LEVEL UP / DOWN
// X RECUL SUR LE PAD
// X remettre minerais sur planètes
// X FOG PROGRESSIF ( = SHOP_RADAR + SUPER RADAR ? )
// X bug missileMax
// X ETOILE DASH sur ZOOM MAP
// X HALO DOIT TOUCHER BRIQUE LA PLUS HAUTE
// X EMPECHER LES TIR DES STORMS TROP NOMBREUX
// X PAD - BALL CREATOR
// X ICONES DE PIERRE DE LYCANS / SPYGNISOS NON PRESENTS
// X MODE DEMO VISIBLE + REVOIR LES OPTIONS DE START
// X BALL - KILL + steel = blockage
// X BLOCK - INSECT
// X BLOCK - qui retourne l'ecran
// X FAIRE DEFILER COMPTEUR MINERAI
// X DEMO - GERER GAMEOVER
// X MESSAGE PLUS DE FUEL
// X CLIQUER SUR LA ZONE VERTE POUR COMMENCER
// X LOADING DES PLANETES
// X MISSIONS - GAIN de CHS scenarisé au debut du jeu
// X MISSIONS - LIFE +3 AU DEPART TANT QUE LE JOUEUR NE DEPASSE PAS DST 5
// X CODER LA PAUSE
// X BALL - EMPECHER DE TIRER LES BALLES COLLEES OFF-SCREEN
// X IMPLEMENTER LES NOUVEAUX MISSILES
// X API - ENDITEM
// X BUG - TIR REDUCTRINE SUR PAD NULL
// X BUG - EDITOR type molecule change
// X ETUDIER encodage niveau
// X IMPLEMENTER LES NOUVELLES BALLES
// X CORRIGER PB CIBLAGE DRONE + CREER LURE BLOCK
// X BRIQUE LURE / ANTI-DRONE
// X IMPLEMENTER CAPSULES ICE FIRE HOLE
// X AMELIORER DESSIN PLANETES
// X TOOL = MAP MONDE
// X EDITEUR / ENREGISTREUR DE NIVEAU
// X BRIQUE GENERATEUR DE MONSTRE
// X IMPLEMENTATION DES LUNETTES DE SOLEIL
// X JAVE CHARGER BUILD
// X ZONE DE TROU-NOIR
// X OPTIONS SEEDEES
// X COLLAGE DE BALLE
// X VIE SUP
// X BUG NOUVELLE PARTIE
// X RECUP MINERAI
// X FAIRE LES DRONES
// X BUG Paillette de charge qui ne se retirent pas.
// X SHOP - DRONE + RAPIDE
// X SHOP - DRONE TRANSFORME + VITE
// X SHOP - DRONE CONVERTIS EN MINERAI
// X SHOP - DRONE PEUVENT COLLECTER MINERAI.
// X SHOP - Empecher d'acheter des recharges quand missile plein
// X MISSILE - AMELiORER LA CADENCE DE TIR
// X MISSILE - AMELIORER LA PUISSANCE DE TIR
// X MISSILE - AMELIORER LA VITESSE DE ROTATION
// ABANDON - FAIRE UNE MAP SCAN
