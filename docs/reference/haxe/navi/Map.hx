package navi;

import Game;
import ImageDataUtils.ColorMatrix;
import js.Browser;
import js.lib.Promise;
import haxe.ds.StringMap;
import pixi.core.Pixi.RendererType;
import pixi.core.Pixi.BlendModes;
import pixi.core.graphics.Graphics;
import pixi.core.sprites.Sprite;
import pixi.core.math.Matrix;
import pixi.core.math.shapes.Rectangle;
import pixi.filters.extras.GlowFilter;
import pixi.filters.displacement.DisplacementFilter;
import mt.bumdum.Lib;
import mt.bumdum.Phys;

typedef Zone = {
	id:Int,
	list:Array<Array<Int>>,
	prc:Float
}

class AnonSprite11130252 extends display.ASprite {
	public var bmp:PixelHelper;
	public var map:RenderTexture;
	public var mdl:Texture;
	public var dm:mt.DepthManager;
	public var pad:display.ASprite;
}

class AnonSprite11791322 extends display.ASprite {
	public var vy:Float;
	public var vr:Float;
}

class AnonSprite2439514 extends display.ASprite {
	public var dec:Float;
}

class Box extends display.ASprite {
	public var but:display.ASprite;
	public var fieldText:pixi.core.text.Text;
	public var fieldBut:pixi.core.text.Text;
	public var fieldTitle:pixi.core.text.Text;
}

class Star extends display.ASprite {
	public var c:Float;
	public var dx:Float;
	public var dy:Float;
	public var fonce:Float;
}

class Bmp extends display.ASprite {
	public var bmp:Texture;
}

class Icon extends display.ASprite {
	public var flBlink:Bool;
}

class MenuButton extends display.ASprite {
	public var id:Int;
}

class Field extends display.ASprite {
	public var field:pixi.core.text.Text;
	public var field2:pixi.core.text.Text;
	public var flFade:Bool;
}

enum Step {
	Move;
	Connexion;
	Zoom(x:Int, y:Int, sens:Int);
	Hole(step:Int);
	Land;
	Play;
	Error;
}

class Map { // }
	public static var ZONE_MARGIN = 10;

	public static var XMAX = 20;
	public static var YMAX = 20;
	public static var BW = 20;
	public static var BH = 18;
	static var WW = 0;
	static var HH = 0;
	public static var SX = 0;
	public static var SY = 0;

	public static var DP_GAME = 0;
	public static var DP_MAP = 1;
	public static var DP_LAYER = 2;
	public static var DP_WINDOW = 3;
	public static var DP_COORD = 4;
	public static var DP_INTER = 5;

	public static var DP_BG = 0;
	public static var DP_FOG = 1;
	public static var DP_MOVE = 2;
	public static var DP_ICONS = 3;

	public var flActive:Bool;
	public var flView:Bool;
	public var flFuel:Bool;

	var playMode:Int;
	var hx:Int;
	var hy:Int;
	var mx:Int;
	var my:Int;
	var zoomCoef:Float;
	var zoomSpeed:Float;
	var iconBlink:Float;
	var menuTimer:Float;
	var timeOut:Float;

	var isRunning:Bool = false;

	var step:Step;

	public var game:Module;

	var zones:Array<Zone>;
	var fog:StringMap<Int>;
	var expandedFog:StringMap<Bool>;
	var reach:StringMap<Bool>;
	var icons:Array<Icon> = [];
	var stars:Array<Star>;

	public var spaceColors:StringMap<Int>;
	public var zoneTable:StringMap<Int>;
	public var seedTable:StringMap<Random>;
	public var menus:Array<MenuButton> = [];
	public var menu:navi.Menu;

	var heroMove:{
		icon:Icon,
		c:Float,
		sx:Int,
		sy:Int,
		ex:Int,
		ey:Int
	};

	var bmpBg:RenderTexture;
	var bmpFog:PixelHelper;
	var layer:AnonSprite11130252;

	var map:display.ASprite;
	var miniPad:AnonSprite11791322;
	var mcGame:display.ASprite;
	var mcFarWarning:McText;
	var mcScreenshot:Bmp;

	public var box:Box;

	var mcCoord:Field;

	public var mcMoveZone:AnonSprite2439514;

	// var mcBar:{>display.ASprite,field:pixi.core.text.Text};
	var root:display.ASprite;
	var bg:display.ASprite;

	public var dm:mt.DepthManager;
	public var mdm:mt.DepthManager;

	public static var me:Map;

	public var onReceiveLevels:Array<String>->Void;

	var dkl:Dynamic;

	public function new(mc) {
		root = mc;
		me = this;
		dm = new mt.DepthManager(root);

		WW = XMAX * BW;
		HH = YMAX * BH;
		hx = Std.int(XMAX * 0.5);
		hy = Std.int(YMAX * 0.5);

		flView = true;

		// SOUND
		Sound.init();

		// initInter();

		// Crash ?
		/*if (Cs.pi.flAdmin || Api.FL_DEBUG)
			initDebugListener(); */
	}

	function init() {
		flFuel = Cs.pi.chs + Cs.pi.chl > 0;

		SX = Cs.pi.x - hx;
		SY = Cs.pi.y - hy;
		// dst = Math.sqrt(Cs.pi.x*Cs.pi.x + Cs.pi.y*Cs.pi.y );

		// SEED TABLE
		seedTable = new StringMap();
		for (x in 0...XMAX + ZONE_MARGIN * 2) {
			for (y in 0...YMAX + ZONE_MARGIN * 2) {
				var px = x + SX - ZONE_MARGIN;
				var py = y + SY - ZONE_MARGIN;
				var n = Std.int(px * (1000 + py) + py);
				seedTable.set('$x,$y', new Random(n));
			}
		}

		// STUFF
		initZones();
		initMap();

		// step = Move;

		if (layer == null) {
			zoomCoef = 1;
			step = Zoom(hx, hy, -1);
		} else {
			step = Hole(0);
		}

		//
		// mcBar.field.text = "";

		// launchMenu({id:6});
		if (!isRunning) {
			js.Browser.window.requestAnimationFrame(update);
			isRunning = true;
		}
	}

	// UPDATE
	var last_update:Float = 0;

	public function update(ts:Float) {
		mt.Timer.update(ts);
		js.Browser.window.requestAnimationFrame(update);
		/*if (ts - last_update < 1000 / 24) // 24 FPS
			{
				return;
		}*/
		last_update = ts;

		Sound.update();

		Manager.dm.getMC().update();

		if (step != null) {
			switch (step) {
				case Move:
					updateMove();
				case Connexion:
					updateConnexion();
				case Zoom(x, y, sens):
					updateZoom(x, y, sens);
				case Hole(sens):
					updateHole(sens);
				case Land:
					updateLand();
				default:
			}
		}

		updateIcons();
		updateMenu();

		if (game != null)
			game.update();

		if (timeOut != null) {
			timeOut -= mt.Timer.tmod;
			if (timeOut < 0) {
				timeOut = null;
				displayError(Text.get.WARNING_CNX);
			}
		}
	}

	// MOVE
	function initMove() {
		menus = [];

		initIcons();
		// initMoveZone();
		initMenu();

		flActive = true;

		switchView(true);

		//
		// STARS

		// updateStars(0);
	}

	function updateMove() {
		if (Cs.PREF_BOOLS[1]) {
			mcMoveZone.dec = (mcMoveZone.dec + 23 * mt.Timer.tmod) % 628;
			mcMoveZone._alpha = 30 + Math.cos(mcMoveZone.dec * 0.01) * 45;
		}
		updateCoord();
		if (heroMove != null)
			updateHero();
	}

	function updateCoord() {
		var p = getMouseSector();

		var tx = ((p.x + 0.5) - SX) * BW;
		var ty = ((p.y + 0.5) - SY) * BH;

		if (mcCoord == null) {
			mcCoord = cast dm.attach("mcCoord", DP_COORD);
			mcCoord.anchor.set(0.5, 0.5);
			mcCoord._x = tx;
			mcCoord._y = ty;

			// TEXT
			mcCoord.initTextField("field2", {
				x: -30,
				y: -16,
				bold: true,
				color: 0x00FF00,
				font: "Verdana",
				size: 10,
				align: "right"
			});
			mcCoord.initTextField("field", {
				x: 12,
				y: -16,
				bold: true,
				color: 0x00FF00,
				font: "Verdana",
				size: 10
			});

			// mcCoord._alpha = 50;
		}

		var flFarWarning = false;

		if (reach.get('${p.x - SX},${p.y - SY}')) {
			if (mcCoord._currentframe == 2) {
				mcCoord.gotoAndStop(1);
				mcCoord.field.style.fill = 0x00FF00;
				mcCoord.field2.style.fill = 0x00FF00;
			}
			if (!Cs.pi.gotItem(MissionInfo.BALL_DRILL) && Math.max(Math.abs(p.x), Math.abs(p.y)) >= 3) {
				flFarWarning = true;
				if (mcFarWarning == null)
					mcFarWarning = cast dm.attach("mcFarZone", DP_INTER);
				mcFarWarning.gotoAndStop(2);
				mcFarWarning.initTextField("field", {
					align: "center",
					font: "Verdana",
					bold: true,
					y: 8,
					x: 200,
					wordWrap: 383,
					size: 10,
					color: 0xFF0000,
				});
				mcFarWarning.field.text = Text.get.WARNING_CARDS;
			}
		} else {
			if (mcCoord._currentframe == 1) {
				mcCoord.field.style.fill = 0xFF0000;
				mcCoord.field2.style.fill = 0xFF0000;
				mcCoord.gotoAndStop(2);
			}
			if (Math.abs(Cs.pi.x) + Math.abs(Cs.pi.y) <= 3) {
				flFarWarning = true;
				if (mcFarWarning == null && Cs.pi.missions[0].status != 0)
					mcFarWarning = cast dm.attach("mcFarZone", DP_INTER);

				if (mcFarWarning != null) {
					mcFarWarning.gotoAndStop(1);
					mcFarWarning.initTextField("field", {
						align: "center",
						font: "Verdana",
						bold: true,
						y: 8,
						x: 200,
						wordWrap: 383,
						size: 10,
						color: 0x00FF00,
					});
					mcFarWarning.field.text = Text.get.WARNING_FAR;
				}
			}
		}
		if (!flFarWarning && mcFarWarning != null) {
			mcFarWarning.removeMovieClip();
			mcFarWarning = null;
		}

		mcCoord.field.text = "[" + p.x + "][" + p.y + "]";
		mcCoord.field2.text = getSquareName(p.x - SX, p.y - SY);

		var c = 0.5;
		mcCoord._x += ((tx - mcCoord._x) * c) + 1;
		mcCoord._y += ((ty - mcCoord._y) * c) + 1;
	}

	function getSquareName(x:Int, y:Int) {
		var name = ZoneInfo.list[zoneTable.get('$x,$y')];
		if (name == null)
			return "";

		return name.name.toUpperCase();
	}

	// ZOOM
	function startZoom(x, y, flMinerai, ?lvl:String) {
		flActive = false;

		zoomCoef = 0;
		step = Zoom(x, y, 1);

		var wx = x + SX;
		var wy = y + SY;

		// GAME
		/*
			game = null;
			mcGame = dm.empty( DP_GAME );
			switch(playMode){
				case 0:	game = new Game( mcGame, spaceColors.get('${x},${y}') );
				case 1:	game = new lander.Game( mcGame, spaceColors.get('${x},${y}') );

			}
		 */

		game.initLevel(wx, wy, zoneTable.get('$x,$y'), flMinerai, lvl);

		trace("FIXME (mcScreenshot)");
		// SCREEN
		mcScreenshot = cast mdm.empty(DP_ICONS);
		mcScreenshot.bmp = mcScreenshot.createEmptyMovieClip('bmp', 0).texture;
		/*var bmp = new Texture(Cs.mcw, Cs.mch, false, 0);
				var m = new Matrix();
				m.scale(1.001, 1.001);
				bmp.draw(mcGame, m);

			//
			mcScreenshot.attachBitmap(bmp, 0);
			mcScreenshot._x = x * BW;
			mcScreenshot._y = y * BH;
			mcScreenshot._xscale = 100 / 20;
			mcScreenshot._yscale = 100 / 20;
			mcScreenshot._alpha = 0;
			mcScreenshot.bmp = bmp; */

		// CLEAN
		// mcBar.removeMovieClip();
		initStars();
	}

	function updateZoom(x, y, sens) {
		if (sens == 1) {
			zoomCoef = Num.mm(0, (zoomCoef + 0.00005 * mt.Timer.tmod) * 1.5, 1);
		} else {
			zoomCoef = Num.mm(0, (zoomCoef - 0.05 * mt.Timer.tmod) * 0.8, 1);
		}
		map._xscale = 100 * (1 - zoomCoef) + zoomCoef * 2000;
		map._yscale = 100 * (1 - zoomCoef) + zoomCoef * 2000;

		if (mcScreenshot != null) {
			mcScreenshot._alpha = zoomCoef * 100;
		}

		var tx = Cs.mcw * 0.5 - (x + 0.5) * BW * 20;
		var ty = Cs.mch * 0.5 - (y + 0.5) * BH * 20;

		map._x = tx * zoomCoef;
		map._y = ty * zoomCoef;

		if (zoomCoef == 1) {
			initPlay();
		} else if (zoomCoef == 0) {
			initMove();
		}

		var cc = 1 - zoomCoef;
		var cx = Cs.mcw * 0.5 + (x + 0.5 - 10) * BW * cc;
		var cy = Cs.mch * 0.5 + (y + 0.5 - 10) * BH * cc;

		if (sens == 1) {
			updateStars(zoomCoef, cx, cy);
		} else {
			var dist = 50 + Math.random() * 20 / zoomCoef;
			if (dist < 300) {
				for (i in 0...8) {
					if (zoomCoef == 0)
						dist = 50;
					var a = Math.random() * 6.28;
					var mc = dm.attach("mcZoomRay", DP_INTER);
					mc.play();
					mc.removeOnFrame = 3;
					mc._x = cx + Math.cos(a) * dist;
					mc._y = cy + Math.sin(a) * dist;
					mc._rotation = a / 0.0174;
					mc._xscale = 100 + Math.random() * 200;
					mc.blendMode = pixi.core.Pixi.BlendModes.ADD;
				}
			}
		}
	}

	function initStars() {
		stars = [];
		var ma = 20;
		for (i in 0...200) {
			var mc:Star = cast dm.attach("partStar", DP_LAYER);
			mc.c = 0.2 + Math.pow(Math.random(), 2) * 0.8;
			var a = i / 200 * 6.28;
			var dist = (20 + Math.random() * 250);
			mc.dx = Math.cos(a) * dist;
			mc.dy = Math.sin(a) * dist;
			mc.fonce = 25 + Math.pow(Math.random(), 2) * 250;
			mc.blendMode = pixi.core.Pixi.BlendModes.ADD;
			mc.set__xscale(300);
			mc.set__yscale(300);
			stars.push(mc);
		}
	}

	function updateStars(zc:Float, cx, cy) {
		var list = stars.copy();
		for (mc in list) {
			var c = mc.c + zc * mc.fonce;

			mc._x = cx + mc.dx * c;
			mc._y = cy + mc.dy * c;

			if (c > 0.9) {
				mc._alpha = ((1 - c) / 0.1) * 100;
			} else {
				mc._alpha = (1 - zc) * 100;
			}
			if (zc < 0.0005)
				mc._alpha = (zc / 0.0005) * 100;

			if (c > 1) {
				stars.remove(mc);
				mc.removeMovieClip();
			};
		}
	}

	// WORMHOLE
	function initHole() {
		zoomCoef = 0;
		zoomSpeed = 0;

		// PREPARE LAYER
		layer = cast dm.empty(DP_LAYER);
		layer.bmp = bmpBg.extract();
		layer.map = RenderTexture.create(Cs.mcw, Cs.mch);
		layer.mdl = cast bmpBg.clone();
		layer.onPress = function() {};

		var mc = dm.attach("mapBlackHole", 0);
		PixelHelper.draw(layer.map, mc, new Matrix());
		mc.removeMovieClip();
		layer.attachBitmap(layer.mdl, 0);

		layer.dm = new mt.DepthManager(layer);
		layer.pad = layer.dm.attach("mcMapIcon", 1);
		layer.pad.anchor.set(0.5, 0.5);
		layer.pad._x = (hx + 0.5) * BW;
		layer.pad._y = (hy + 0.5) * BH;

		// SEND INFO
		initConnexion();
		Api.warp();
		cleanAll();
	}

	function updateHole(step) {
		switch (step) {
			case 0:
				zoomCoef = Num.mm(0, zoomCoef + ((1 - zoomCoef) * 0.1 + 0.01), 1);
				if (zoomCoef == 1)
					this.step = Hole(1);

				layer.pad._y = Cs.mch * 0.5 + zoomCoef * 70;
			case 1:
				zoomSpeed += -zoomCoef * 0.25;
				zoomSpeed *= 0.9;
				zoomCoef += zoomSpeed;
				if (Math.abs(zoomSpeed) + Math.abs(zoomCoef) < 0.1) {
					layer._alpha -= 10;
					if (layer._alpha <= 0) {
						layer.mdl.destroy();
						layer.map.destroy();
						layer.removeMovieClip();
						layer = null;
						this.step = Land;
					}
				}

				layer.pad._y -= 20;
				layer.pad._rotation += 20;
		}

		trace("FIXME");
		// The Goal here is to update the layer that handle the map/grid

		//Original Code:
		/*
		var fl = new flash.filters.DisplacementMapFilter();
		fl.mapBitmap = layer.map;
		fl.componentX = 0;
		fl.componentY = 1;
		fl.scaleX = zoomCoef*100;
		fl.scaleY = -zoomCoef*300;
		layer.bmp.applyFilter( layer.mdl, layer.mdl.rectangle, new flash.geom.Point(0,0), fl );
		*/

		//Tentative:
		// var deplacementSprite:ASprite = new ASprite();
		// deplacementSprite.load(cast layer.pad.mask);
		// deplacementSprite.set__x(0);
		// deplacementSprite.set__y(0);
		// deplacementSprite.set__xscale(zoomCoef*100);
		// deplacementSprite.set__yscale(-zoomCoef*300);

		// var wormHoleFilter = new DisplacementFilter(deplacementSprite);
		// var deplacementGraphic:ASprite = new ASprite();
		// deplacementGraphic.load(layer.mdl);
		// deplacementGraphic.filters = [wormHoleFilter];
		
		// var distorcedBmp = RenderTexture.create(WW, HH);
		// distorcedBmp.draw(new Sprite(layer.mdl), new Matrix());
		// distorcedBmp.draw(deplacementGraphic, new Matrix());
		// distorcedBmp.draw(layer.pad, new Matrix());
		
		// 3 known possible solutions (none works):
		// 1: layer.bmp.copyPixels(distorcedBmp.extract(), new Rectangle(0, 0, WW, HH), new pixi.core.math.Point(0, 0));
		// 2: layer.map or mdl = cast distorcedBmp.clone();
		// 3: PixelHelper.applyFilter(cast layer.mdl, wormHoleFilter);
	}

	// LAND
	function updateLand() {
		if (miniPad == null) {
			miniPad = cast dm.attach("mcMapIcon", DP_INTER);
			miniPad.anchor.set(0.5, 0.5);
			miniPad._x = (hx + 0.5) * BW;
			miniPad._y = -(20 + Cs.mch * 0.5);
			miniPad.vy = 15;
			miniPad.vr = 20;
			miniPad._rotation = 0;
		}

		miniPad.vy += 1;
		miniPad._y += miniPad.vy;
		miniPad._rotation += miniPad.vr;

		var gy = (hy + 0.5) * BH;

		if (miniPad._y > gy) {
			miniPad.vy *= -0.5;
			miniPad._y = gy;
			miniPad.vr *= -0.45;
			// miniPad._rotation *= 0.5;
			miniPad._rotation = 0;
			if (miniPad.vy > -1) {
				initMove();
				miniPad.removeMovieClip();
				miniPad = null;
			}
		}
	}

	// PLAY
	function initPlay() {
		cleanAll();

		step = Play;
		game.initPlay();

		// CLEAN

		//
	}

	function updatePlay() {
		game.update();
	}

	function cleanAll() {
		bmpBg.destroy();
		if (bmpFog != null) {
			// bmpFog.destroy();
			bmpFog = null;
		}

		if (mcScreenshot != null) {
			mcScreenshot.removeMovieClip();
			mcScreenshot.bmp.destroy();
		}

		map.removeMovieClip();
		while (menus.length > 0)
			menus.pop().removeMovieClip();
	}

	// ZONES
	function initZones() {
		var id = 0;
		zones = [];
		zoneTable = new StringMap();

		for (zone in ZoneInfo.list) {
			if (isZoneIn(zone.pos)) {
				var zone:Zone = cast {
					id: id,
					list: ZoneInfo.getSquares(id)
				}
				zones.push(zone);
				for (p in zone.list) {
					var x = p[0] - SX;
					var y = p[1] - SY;
					zoneTable.set('$x,$y', id);
				}
			};
			id++;
		}
	}

	// MENU
	function initMenu() {
		menuTimer = 0;

		// PREFERENCES
		newMenu(4);

		// EDITOR
		if ((Cs.pi.gotItem(MissionInfo.EDITOR) && Cs.pi.pendingLevels >= 0 && Cs.pi.pendingLevels < 32) || Cs.pi.flEditor) {
			newMenu(2);
		}

		// LANDER
		if (Cs.pi.gotItem(MissionInfo.LANDER_REACTOR) && zoneTable.get('${Cs.pi.x - SX},${Cs.pi.y - SY}') != null)
			newMenu(6);

		// RETOUR
		if (Cs.pi.gotItem(MissionInfo.RETROFUSER))
			newMenu(8, initHole);

		if (Cs.pi.flAdmin) {
			// WORLD MAP
			newMenu(3);

			//
			// newMenu(8,initHole);

			// FORCE EDIT
			newMenu(6);

			// FORCE LANDER
			// newMenu(2);
		}
	}

	function updateMenu() {
		for (mc in menus) {
			var ty = Cs.mch - 37;
			mc._y += (ty - mc._y) * 0.5;
		}

		if (menu != null)
			menu.updateMenu();
	}

	public function newMenu(?id:Int, ?f:Void->Void, ?seed:mt.OldRandom) {
		var n = menus.length;
		var mc:MenuButton = cast dm.attach("mcMenu", DP_INTER);
		mc._x = 5 + n * 38;
		mc._y = Cs.mch;
		mc.id = id;
		mc.gotoAndStop(id + 1);

		menus.push(mc);

		dm.getMC().interactive = true;
		mc.interactive = true;
		mc.onRollOver = function() {
			Filt.glow(mc, 2, 4, 0xFFFFFF);
			Filt.glow(mc, 10, 1, 0xFFFFFF);
			mc.blendMode = pixi.core.Pixi.BlendModes.ADD;

			if (this.mcCoord != null) {
				this.mcCoord._alpha = 0;
			}
		};
		mc.onRollOut = function() {
			mc.filters = null;
			mc.blendMode = pixi.core.Pixi.BlendModes.NORMAL;

			if (this.mcCoord != null) {
				this.mcCoord._alpha = 100;
			}
		};

		if (id != null)
			mc.onPress = this.launchMenu.bind(cast mc);
		if (f != null)
			mc.onPress = f;

		switch (id) {
			case 0:
				navi.menu.Shop.initAlien(mc.smc, seed);
		}
	}

	public function removeMenu(id) {
		var i = 0;
		while (i < menus.length) {
			var mc = menus[i];
			mc._x = 5 + i * 38;
			mc._y = Cs.mch;
			if (mc.id == id) {
				menus.splice(i--, 1);
				mc.removeMovieClip();
			}
			i++;
		}
	}

	public function launchMenu(mc) {
		switch (mc.id) {
			case 0:
				menu = new navi.menu.Shop(mc._x, mc._y);
			case 2:
				menu = new navi.menu.Editor(mc._x, mc._y);
			case 3:
				menu = new navi.menu.World(mc._x, mc._y);
			case 4:
				menu = new navi.menu.Pref(mc._x, mc._y);
			case 5:
				menu = new navi.menu.Asteroid(mc._x, mc._y);
			case 6:
				setTimeOut(200);
				Api.playLander(Cs.pi.x, Cs.pi.y);
				playMode = 1;
				initConnexion();
		}
	}

	public function switchView(vis) {
		for (mc in menus) {
			mc.onRollOut();
			mc._visible = vis;
		}

		if (!flActive)
			return;

		flView = vis;
		for (mc in icons)
			mc._visible = vis;
		if (vis) {
			active();
		} else {
			unactive();
		}
	}

	public function active() {
		step = Move;
		initMoveZone();
		bg.onPress = clickMap;
		bg.onRollOver = rOverMap;
		bg.onRollOut = rOutMap;
	}

	public function unactive() {
		step = null;
		mcCoord.removeMovieClip();
		mcCoord = null;
		mcMoveZone.removeMovieClip();
		bg.onPress = null;
		bg.onRollOver = null;
		bg.onRollOut = null;
		if (mcFarWarning != null) {
			mcFarWarning.removeMovieClip();
			mcFarWarning = null;
		}
	}

	// MAP
	function initMap() {
		map = dm.empty(DP_MAP);
		mdm = new mt.DepthManager(map);

		var col = Cs.COL_SPACE;
		if (Cs.pi.gotItem(MissionInfo.MODE_DIF))
			col = 0x500048;

		bg = mdm.empty(DP_BG);
		bg.useHandCursor = false;
		drawFog();

		bmpBg = RenderTexture.create(WW, HH);
		bmpBg.fill(col);
		drawBg();

		bg.attachBitmap(bmpBg);

		var fogSprite = new Sprite(bmpFog.getTexture());
		fogSprite.alpha = 0.5;
		bg.addChild(fogSprite);
	}

	function drawBg() {
		var ma = ZONE_MARGIN;

		var stars = [];
		var brushLight = BmpTextureHelper.getSprite("mcLuz");
		brushLight.blendMode = pixi.core.Pixi.BlendModes.ADD;

		// CLOUDS
		for (px in 0...XMAX + 2 * ma) {
			for (py in 0...YMAX + 2 * ma) {
				var x = px - ma;
				var y = py - ma;

				x -= 5;

				// CLOUD
				var sc = 5;
				var seed = seedTable.get('${x + ZONE_MARGIN},${y + ZONE_MARGIN}');
				if (seed != null && seed.random(70) == 0) {
					var bi = 5;
					var ri = 90; // 50
					var o = {
						r: bi + seed.random(ri),
						g: bi + seed.random(ri),
						b: bi + seed.random(ri)
					}

					var m = new Matrix();
					m.scale((0.5 + seed.rand()) * sc, (0.5 + seed.rand()) * sc);
					m.translate(x * BW, y * BH);
					brushLight.tint = Col.objToCol(o);

					bmpBg.draw(brushLight, m);
				}

				// STARS
				if (x >= 0 && x < XMAX && y >= 0 && y < YMAX) {
					var max = seed.random(3);
					for (i in 0...max) {
						stars.push([(x + seed.rand()) * BW, (y + seed.rand()) * BH, 0.2 + seed.rand() * 0.3]);
					}
				}
			}
		}

		var px = PixelHelper.extract(bmpBg);

		// GET COLORS
		spaceColors = new StringMap();
		for (x in 0...XMAX) {
			for (y in 0...YMAX) {
				var pix = px.getPixel(Std.int(x + 0.5) * BW, Std.int(y + 0.5) * BH);
				spaceColors.set('$x,$y', pix);
			}
		}

		// STARS
		var brushStar = BmpTextureHelper.getSprite("mcStar");
		if (Cs.pi.gotItem(MissionInfo.MODE_DIF))
			brushStar = BmpTextureHelper.getSprite("mcDifStar");

		for (p in stars) {
			var sc = p[2];

			var m = new Matrix();
			m.scale(sc, sc);
			m.translate(p[0], p[1]);

			bmpBg.draw(brushStar, m);
		}

		// ASTEROIDES
		var brush = BmpTextureHelper.getSprite("mcMapAsteroide");
		// brush.anchor.set(0, 0);
		var strength = 10;
		var noise = 0.3;
		var freq = 0.3;
		for (x in 0...XMAX) {
			for (y in 0...YMAX) {
				var seed = seedTable.get('${x + ZONE_MARGIN},${y + ZONE_MARGIN}');
				var dx = SX + x - ZoneInfo.ASTEROBELT_CX;
				var dy = SY + y - ZoneInfo.ASTEROBELT_CY;
				var a = Math.atan2(dy, dx);
				var dist = Math.abs(Math.sqrt(dx * dx + dy * dy) - ZoneInfo.ASTEROBELT_RAY);
				if (dist < strength) {
					var coef = dist / strength;
					if (seed.rand() > (1 - freq) + coef * freq) {
						var m = new Matrix();
						var px = x + (seed.rand() * 2 - 1) * noise + 0.5;
						var py = y + (seed.rand() * 2 - 1) * noise + 0.5;
						m.translate(px * BW, py * BH);
						brush.rotation = seed.rand() * 360;
						var sc = 0.3 + 0.5 * (1 - coef) + seed.rand() * 0.4;
						brush.scale.set(sc, sc);
						// brush.gotoAndStop(seed.random(brush._totalframes) + 1);
						// brush.tint = spaceColors.get('$x,$y');

						bmpBg.draw(brush, m);

						zoneTable.set('$x,$y', ZoneInfo.ASTEROBELT);
					}
				}
			}
		}

		// ZONES //
		var brush = BmpTextureHelper.getASprite("mcZone");
		for (zone in zones) {
			var zi = ZoneInfo.list[zone.id];
			brush.gotoAndStop(zone.id + 1);

			var m = new Matrix();
			m.translate((zi.pos[0] - SX) * BW, (zi.pos[1] - SY) * BH);

			bmpBg.draw(brush, m);
		}

		// LINES GRID //
		var bmp = new Graphics();
		bmp.beginFill(0xFFFFFF, 0.3);
		for (x in 0...XMAX)
			bmp.drawRect(x * BW, 0, 1, HH);
		for (y in 0...YMAX)
			bmp.drawRect(0, y * BH, WW, 1);

		bmpBg.draw(bmp, new Matrix());
	}

	public function drawFog() {
		// GEN FOG
		fog = new StringMap();
		for (x in 0...XMAX) {
			for (y in 0...YMAX) {
				var n = Cs.pi.fog[x * YMAX + y];
				if (n == null)
					n = -1;

				fog.set('$x,$y', n + 1);
			}
		}

		// EXPAND FOG
		expandedFog = new StringMap();
		var ray = Cs.pi.radar;
		var max = ray * 2 + 1;
		for (x in 0...XMAX) {
			for (y in 0...YMAX) {
				if (fog.get('$x,$y') == 2) {
					for (dx in 0...max) {
						for (dy in 0...max) {
							expandedFog.set('${x + dx - ray},${y + dy - ray}', true);
						}
					}
				}
			}
		}

		var visitedTilesG = new Graphics();
		visitedTilesG.beginFill(0xFFFFFF); // Will be hidden by knockout.

		// DRAW
		bmpFog = RenderTexture.create(WW, HH).extract();
		for (x in 0...XMAX) {
			for (y in 0...YMAX) {
				var n = fog.get('$x,$y');
				var a = [0x000000FF, 0x330000FF];
				if (n < 2)
					bmpFog.fillRect(new Rectangle(x * BW, y * BH, BW, BH), a[n]);
				else
					visitedTilesG.drawRect(x * BW, y * BH, BW, BH);
			}
		}

		var skullMc = BmpTextureHelper.getSprite("mcSkull");
		skullMc.anchor.set(0, 0);
		var skullRT = RenderTexture.create(20, 18);
		skullRT.draw(skullMc, new Matrix());
		var skullPixels = PixelHelper.extract(skullRT);
		var skullPixelsRect = new Rectangle(0, 0, skullPixels.width, skullPixels.height);
		skullMc.destroy();

		for (x in 0...XMAX) {
			for (y in 0...YMAX) {
				var n = fog.get('$x,$y');
				var a = [0x00000088, 0x33000088];
				if (expandedFog.get('$x,$y'))
					if (n < 2)
						bmpFog.fillRect(new Rectangle(x * BW, y * BH, BW, BH), a[n]);
				if (n == 1) {
					bmpFog.copyPixels(skullPixels, skullPixelsRect, new pixi.core.math.Point(x * BW, y * BH), null, null, true);
				}
			}
		}

		visitedTilesG.filters = [
			Type.createInstance(GlowFilter, [
				{
					distance: 6,
					outerStrength: 3,
					color: 0xAA00FF,
					knockout: true,
				}
			])
		];

		var bmpFogRT = RenderTexture.create(WW, HH);
		var fog = new Sprite(bmpFog.getTexture());
		bmpFogRT.draw(fog, new Matrix());
		bmpFogRT.draw(visitedTilesG, new Matrix());

		bmpFog.copyPixels(bmpFogRT.extract(), new Rectangle(0, 0, WW, HH), new pixi.core.math.Point(0, 0));
		fog.destroy();
	}

	// ACTIONS
	function clickMap() {
		var p = getMouseSector();

		if (!flFuel) {
			initBoxFuel();
			return;
		}

		if (reach.get('${p.x - SX},${p.y - SY}') || (Cs.pi.flAdmin && p.x - SX > 0 && false)) {
			callPlay(p.x, p.y);
		}
	}

	public function callPlay(x, y) {
		setTimeOut(200);
		Api.play(x, y);
		playMode = 0;
		initConnexion();
	}

	function rOverMap() {}

	function rOutMap() {}

	public function continueTasks() {
		Web.checkTasks();
	}

	// HERO
	function updateHero() {
		if (mcMoveZone != null)
			mcMoveZone._visible = false;
		heroMove.c = Math.min(heroMove.c + 0.04 * mt.Timer.tmod, 1);
		var mc = heroMove.icon;
		var x = heroMove.sx * (1 - heroMove.c) + heroMove.ex * heroMove.c;
		var y = heroMove.sy * (1 - heroMove.c) + heroMove.ey * heroMove.c;
		mc._x = x * BW;
		mc._y = y * BH;

		if (heroMove.c == 1) {
			if (mcMoveZone != null)
				mcMoveZone._visible = true;
			heroMove = null;
		}
	}

	// ICONS
	function initIcons() {
		icons = [];
		iconBlink = 0;

		// TROU NOIRS
		for (a in ZoneInfo.holes) {
			for (p in a) {
				var rx = p[0] - SX;
				var ry = p[1] - SY;
				if (rx >= 0 && rx < XMAX && ry >= 0 && ry < YMAX) {
					if (Cs.pi.flAdmin)
						displayIcon(2, rx, ry, false);
					if (rx == hx && ry == hy) {
						newMenu(1, initHole);
					}
				}
			}
		}

		// BOUTIQUE
		for (x in 0...XMAX) {
			for (y in 0...YMAX) {
				var wx = SX + x;
				var wy = SY + y;
				if (Cs.pi.gotItem(MissionInfo.MAP_SHOP) || (wx == -2 && wy == 3)) {
					var dst = Math.sqrt(wx * wx + wy * wy);
					var seed = seedTable.get('${x + ZONE_MARGIN},${y + ZONE_MARGIN}');
					if (seed.random(Std.int(40 + Math.pow(dst, 1.4))) == 0) {
						displayIcon(1, x, y, false).set__alpha(50);
						if (x == hx && y == hy) {
							newMenu(0);
						}
					}
				}
			}
		}

		// ITEMS
		var id = 0;
		for (o in MissionInfo.ITEMS) {
			if (o.x > SX && o.x < SX + XMAX && o.y > SY && o.y < SY + YMAX) {
				var o = MissionInfo.ITEMS[id];
				if (Cs.pi.items[id] == 1 || (o.fam == 1 && Cs.pi.shopItems[ShopInfo.MISSILE_MAP] == 1 && !Cs.pi.gotItem(id))) {
					displayIcon(id + 10, o.x - SX, o.y - SY, true);
				}
			}
			id++;
		}

		// HERO
		var h = displayIcon(0, hx, hy);
		if (Cs.pi.ox != null) {
			var dx = Cs.pi.ox - Cs.pi.x;
			var dy = Cs.pi.oy - Cs.pi.y;
			var sum = Math.abs(dx) + Math.abs(dy);
			if (sum > 0 && sum < 10) {
				heroMove = {
					ex: hx,
					ey: hy,
					sx: hx + dx,
					sy: hy + dy,
					icon: h,
					c: 0.0
				}
				updateHero();
			}
		}

		// START CLICK
		if (Cs.pi.missions[0].status == 0) {
			var mc:Icon = cast mdm.empty(DP_ICONS);
			mc._x = 10.5 * BW;
			mc._y = 10.5 * BH;
			var field = mc.initTextField("field", {
				x: 25,
				y: -22,
				font: "GAU_font_cube_B",
				size: 12,
				color: 0xFFFFFF,
				wordWrap: 150,
			});
			field.text = Text.get.START_CLIC_GREEN;
			icons.push(mc);
		}

		// MINE ZONE
		if (Cs.pi.levelMission != null) {
			var mc:Icon = cast mdm.attach("mcMineZone", DP_ICONS);
			mc.anchor.set(0, 1);
			mc.smc = mc.attachMovie("mcMineZoneSquare", "smc", 0);
			mc.smc.gotoAndStop(Cs.pi.levelMission.size);
			mc._x = (Cs.pi.levelMission.x - SX) * BW;
			mc._y = (Cs.pi.levelMission.y - SY) * BH;
			mc.flBlink = true;
			icons.push(mc);

			// ESCORP / FURI
			var frame = 1;
			if (Cs.pi.gotItem(MissionInfo.EVASION))
				frame = 2;
			mc.gotoAndStop(frame);
			Filt.glow(mc, 10, 1, [0x00FF00, 0xFF0000][frame - 1]);
		}
	}

	function displayIcon(id, x, y, ?flBlink) {
		var mc:Icon = cast mdm.attach("mcMapIcon", DP_ICONS);
		mc._x = x * BW;
		mc._y = y * BH;
		mc.flBlink = flBlink;
		// mc.blendMode = pixi.core.Pixi.BlendModes.ADD;
		if (id >= 10) {
			mc.gotoAndStop(0);
			mc.smc = mc.attachMovie("mcMapIconSmc", "smc", 0);
			mc.smc.gotoAndStop((id - 10) + 1);
		} else {
			mc.gotoAndStop(id + 1);
		}

		icons.push(mc);
		return mc;
	}

	function updateIcons() {
		if (!flView)
			return;
		iconBlink += mt.Timer.tmod;
		if (iconBlink > 25) {
			iconBlink = 0;
			for (mc in icons) {
				if (mc.flBlink) {
					// mc._visible = !mc._visible;
					// if( !mc._visible && iconBlink == 0) iconBlink = 20;
					if (mc._alpha == 0) {
						mc._alpha = 100;
					} else {
						mc._alpha = 0;
						iconBlink = 20;
					}
				}
			}
		}
	}

	function removeIcons() {
		while (icons.length > 0)
			icons.pop().removeMovieClip();
	}

	// MOVES
	public function initMoveZone() {
		if (mcMoveZone != null)
			mcMoveZone.removeMovieClip();

		mcMoveZone = cast mdm.empty(DP_MOVE);
		mcMoveZone.useHandCursor = true;
		mcMoveZone._x = hx * BW;
		mcMoveZone._y = hx * BH;
		mcMoveZone._alpha = 15;

		mcMoveZone.blendMode = BlendModes.ADD;
		mcMoveZone.dec = 0;
		// Filt.glow(mcMoveZone, 100, 2, 0xFFFFFF);
		mcMoveZone._alpha = 0;

		mcMoveZone.onPress = clickMap;

		reach = new StringMap();
		reach.set('${hx},${hy}', true);
		var zone = [[hx, hy]];
		var list = [[hx, hy]];

		var max = Cs.pi.engine;

		for (i in 0...max) {
			zone = extendZone(zone);
			for (p in zone)
				list.push(p);
		}

		if (Cs.pi.missions[0].status != 0) {
			list.shift();
			reach.set('${hx},${hy}', false);
		}

		var fr = 1;
		if (!flFuel)
			fr = 2;
		var dm = new mt.DepthManager(mcMoveZone);
		for (p in list) {
			var mc = dm.attach("mcMove", 0);
			mc._x = (p[0] - hx) * BW;
			mc._y = (p[1] - hy) * BH;
			mc.gotoAndStop(fr);
		}

		/*
			count = 0;
			var done = [];
			for( x in 0...XMAX )done[x] = [];
			setMoveZone(hx,hy,7,new mt.DepthManager(mcMoveZone),done);
		 */
	}

	function extendZone(zone:Array<Array<Int>>) {
		var list = [];
		for (p in zone) {
			if (fog.get('${p[0]},${p[1]}') == 2 || expandedFog.get('${p[0]},${p[1]}')) {
				for (d in Cs.DIR) {
					var nx = p[0] + d[0];
					var ny = p[1] + d[1];

					if (reach.get('${nx},${ny}') == null) {
						reach.set('${nx},${ny}', true);
						list.push([nx, ny]);
					}
				}
			}
		}
		return list;
	}

	// TOOLS
	function getGX(x:Float) {
		return Std.int(x / BW);
	}

	function getGY(y:Float) {
		return Std.int(y / BH);
	}

	function getMouseSector() {
		var x = Std.int(Num.mm(0, getGX(map._xmouse), XMAX - 1) + Cs.pi.x - Std.int(XMAX * 0.5));
		var y = Std.int(Num.mm(0, getGY(map._ymouse), YMAX - 1) + Cs.pi.y - Std.int(YMAX * 0.5));
		return {x: x, y: y};
	}

	function isZoneIn(pos:Array<Int>) {
		if (pos[2] == 0)
			return false;

		var xMin = SX;
		var yMin = SY;
		var xMax = SX + XMAX;
		var yMax = SY + YMAX;

		if (pos.length == 3) {
			xMin -= pos[2];
			yMin -= pos[2];
			xMax += pos[2];
			yMax += pos[2];
		} else {
			xMin -= pos[2];
			yMin -= pos[3];
		}

		var x = pos[0];
		var y = pos[1];

		return x >= xMin && x < xMax && y >= yMin && y < yMax;
	}

	// BOX
	function initBoxFuel() {
		box = cast dm.attach("boxFuel", DP_INTER);
		box.smc.onPress = function() {};
		// box.field
		box.fieldTitle.text = Text.get.FUEL_TITLE;
		box.fieldText.text = Text.get.FUEL_TEXT; // fixme: htmlText
		box.fieldBut.text = Text.get.FUEL_BANK;

		var mc = box.but;
		var me = this;
		mc.stop();
		box.but.onPress = function() {
			mc.gotoAndStop(3);
			me.redirectBank();
		};
		box.but.onRollOver = function() {
			mc.gotoAndStop(2);
		};
		box.but.onRollOut = function() {
			mc.gotoAndStop(1);
		};
		box.but.onDragOver = box.but.onRollOver;
		box.but.onDragOut = box.but.onRollOut;
		box.but.onRelease = box.but.onRollOver;
		box.but.onReleaseOutside = box.but.onRollOut;
	}

	function redirectBank() {
		// flash.external.ExternalInterface.call("game_load_bank");
		// var lv = new flash.LoadVars();
		// lv.send( Reflect.field(flash.Lib._root,"bankUrl"), "_self" );
	}

	// PROTOCOLE
	public function initConnexion() {
		step = Connexion;
		// mcBar.field.text = "CONNEXION";

		// CLEAN
		switchView(false);
		while (menus.length > 0)
			menus.pop().removeMovieClip();
		// mcMoveZone.removeMovieClip();
		removeIcons();

		if (map != null) {
			map.onPress = null;
			map.onRollOver = null;
			map.onRollOut = null;
			map.useHandCursor = false;
		}
	}

	function updateConnexion() {
		// mcBar.field.text = mcBar.field.text+".";
		// if(mcBar.field.text.length>12)mcBar.field.text = "CONNEXION";
	}

	public function confirmMove(x, y, flMinerai, ?lvl) {
		mcGame = dm.empty(DP_GAME);
		game = new Game(mcGame, spaceColors.get('${x - SX},${y - SY}'));

		setTimeOut(null);
		startZoom(x - SX, y - SY, flMinerai, lvl);
	}

	public function confirmLander(flMinerai, capsType, flHouseVisited) {
		mcGame = dm.empty(DP_GAME);
		game = new lander.Game(mcGame, spaceColors.get('$hx,$hy'), flHouseVisited);

		setTimeOut(null);
		startZoom(hx, hy, flMinerai, null);
	}

	public function error(str:String) {
		displayError(str);
	}

	public function setTimeOut(n) {
		timeOut = n;
		if (n == null)
			Manager.dm.clear(17);
	}

	public function displayError(str:String) {
		var head = str.substr(0, 3);
		if (head.indexOf("CRC") == 1 || head.indexOf("crc") == 1) {
			str = Text.get.ERROR_CRC;
		}

		mcFarWarning = cast Manager.dm.attach("mcFarZone", 17);
		mcFarWarning.gotoAndStop(3);
		mcFarWarning.initTextField("field", {
			align: "center",
			font: "Verdana",
			bold: true,
			y: 8,
			x: 200,
			wordWrap: 383,
			size: 12,
			color: 0xFFFFFF,
		});
		mcFarWarning.field.text = str;
		if (game != null) {
			game.kill();
		}
		step = Error;
	}

	// SET INFOS
	public function setInfos(?str) {
		setTimeOut(null);

		Cs.pi = new PlayerInfo();
		Cs.pi.parseInfo(str);

		// PLACE EARTH
		var earth = null;
		for (pl in ZoneInfo.list) {
			if (pl.name == "Terre")
				earth = pl;
		}

		var pid = Std.parseInt(Cs.pi.pid);
		var seed = new mt.Rand(pid);
		if (Cs.pi.gotItem(MissionInfo.MODE_DIF))
			seed.random(100);
		var ray = 1500 + seed.random(500);
		earth.pos[0] = seed.random(ray) * (seed.random(2) * 2 - 1);
		earth.pos[1] = Std.int((ray - Math.abs(earth.pos[0])) * (seed.random(2) * 2 - 1));

		if (game != null) {
			game.kill();
			mcGame = null;
			game = null;
		}
		init();

		Web.initCurrentPage();
	}

	// DEBUG KEY
	function initDebugListener() {}

	function pressKey() {}

	function releaseKey() {}

	/*function warp(dx, dy) {
		Cs.pi.x += dx;
		Cs.pi.y += dy;
		Cs.pi.saveCache();
		cleanAll();
		setInfos();
		zoomCoef = 0;
	}*/
	//
	public function kill() {
		bmpBg.destroy();
		// bmpFog.destroy();
		root.removeMovieClip();
	}

	// {
}
