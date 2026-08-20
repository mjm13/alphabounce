package navi.menu;

import pixi.filters.colormatrix.ColorMatrixFilter;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.filters.extras.GlowFilter;
import mt.bumdum.Lib;
import mt.bumdum.Bouille;

class AnonSprite15664502 extends display.ASprite {
	public var alien:display.ASprite;
	public var bg:display.ASprite;
}

class AnonSprite15664501 extends display.ASprite {
	public var screen:display.ASprite;
	public var vig:AnonSprite15664502;
	public var field:pixi.core.text.Text;
	public var gem:display.ASprite;
	public var quit:display.ASprite;
	public var buy:display.ASprite;
}

class Slot extends display.ASprite {
	public var icon:display.ASprite;
	public var field:pixi.core.text.Text;
	public var id:Int;
}

@:native("PIXI.filters.GlowFilter")
extern class PixiGlowFilter extends Filter {
	public function new(options:Dynamic);

	public var color:Int;
}

class Shop extends navi.Menu { // }
	var selection:Slot;
	var slots:Array<Slot>;
	var skin:AnonSprite15664501;
	var sdm:mt.DepthManager;

	var seed:mt.OldRandom;

	override function init() {
		super.init();

		skin = cast dm.attach("mcShop", 1);
		skin.initTextField('field', {
			size: 30,
			color: 0x00FF00,
			font: "Digital",
			align: "right",
			x: 353,
			y: 151,
		});
		skin.field.filters = [
			new PixiGlowFilter({
				distance: 5,
				outerStrength: 1,
				color: 0x00FF00,
				quality: 0.1
			})
		];

		skin._x = navi.Menu.MARGIN;
		skin._y = navi.Menu.MARGIN * (Cs.mch / Cs.mcw);

		skin.screen = skin.createEmptyMovieClip('screen', 0);
		skin.screen.position.set(2, 2);
		sdm = new mt.DepthManager(skin.screen);
		skin.gem = skin.attachMovie('shopGem', 'smc', 0);
		skin.gem.anchor.set(0.5, 0.5);
		skin.gem.position.set(361, 165);
		skin.gem._visible = false;
		skin.quit = skin.attachMovie('mcQuit', 'smc', 0);
		skin.quit.position.set(309, 300);
		skin.quit.gotoAndStop(1);
		skin.buy = skin.attachMovie('mcQuit', 'smc', 0);
		skin.buy.position.set(236, 300);
		skin.buy.gotoAndStop(2);
		Filt.glow(skin, 2, 4, 0xFFFFFF);

		active(skin.quit, quit);
		unactive(skin.buy);

		initSeed();

		// PRESS
		skin.onPress = unselect;
	}

	function initSeed() {
		// seed = bs.clone();

		var n = Cs.pi.x * (967 + Cs.pi.y) + Cs.pi.y;
		seed = new mt.OldRandom(n);

		// initAlien(skin.vig, bs.clone());
		trace('FIXME: init alien');
		genContent();
	}

	// CONTENT
	function genContent() {
		var list = [];
		var dst = Math.sqrt(Cs.pi.x * Cs.pi.x + Cs.pi.y * Cs.pi.y);

		var id = 0;
		for (info in ShopInfo.ITEMS) {
			if ((info.pb[1] <= dst || info.pb.length == 1) && seed.random(info.pb[0]) == 0) {
				if (isVisible(id))
					list.push(id);
			}

			id++;
		}

		slots = [];
		var ma = 4;

		for (i in 0...12) {
			var n = list[i];
			var mc:Slot = cast sdm.attach("mcShopSlot", 0);
			mc._x = ma + (i % 2) * 117;
			mc._y = ma + Std.int(i / 2) * (52 + ma - 1);

			if (n != null) {
				mc.stop();
				mc.id = n;
				mc.icon = mc.attachMovie('shopIcon', 'icon', 0);
				mc.icon.position.set(0, 0);
				mc.icon.gotoAndStop(n + 1);
				mc.interactive = true;
				mc.initTextField("field", {
					font: "Verdana",
					color: 0x00FF00,
					wordWrap: 50,
					x: 54,
					y: 3,
					size: 10,
				});
				slots.push(mc);

				mc.field.text = Text.get.SHOP_ITEM_NAMES[n];

				if (isBuyable(n)) {
					mc.onPress = select.bind(mc);
				} else {
					mc._alpha = 50;
					mc.blendMode = pixi.core.Pixi.BlendModes.NORMAL;
				}
			} else {
				mc.gotoAndStop(2);
			}
		}
	}

	function cleanContent() {
		while (slots.length > 0)
			slots.pop().removeMovieClip();
	}

	// ALIEN
	static public function initAlien(mc, ?seed:mt.OldRandom) {
		if (seed == null) {
			var n = Cs.pi.x * (967 + Cs.pi.y) + Cs.pi.y;
			seed = new mt.OldRandom(n);
		}

		var b = new Bouille();
		b.colorDecal = 10;
		b.firstDecal = 0;
		b.skin = [];
		b.palette = PALETTE;
		b.paletteRedirect = [0, 1, 1, 2, 3];

		for (i in 0...20) {
			// if( i == 0 )b.skin.push(24);
			// else b.skin.push(seed.random(200));
			b.skin.push(seed.random(200));
		}
		b.framize(mc);
		b.colorize(mc);
	}

	// TOOLS
	function isVisible(n) {
		var flHave = Cs.pi.shopItems[n] == 1;
		switch (n) {
			case ShopInfo.RADAR:
				return !Cs.pi.gotItem(MissionInfo.RADAR_OK);
			case ShopInfo.AMMO:
				return true;
			case ShopInfo.LIFE:
				return !flHave && !Cs.pi.gotItem(MissionInfo.MODE_DIF);
			case ShopInfo.DRONE:
				return Cs.pi.drone < 10;
			case ShopInfo.PODS:
				return !flHave && Cs.pi.gotItem(MissionInfo.LANDER_REACTOR) && Cs.pi.x == -12 && Cs.pi.y == -1 && Cs.pi.getLife() > 0;
			case ShopInfo.PODS_EXTEND_0:
				return !flHave && Cs.pi.shopItems[ShopInfo.PODS] == 1;
			case ShopInfo.PODS_EXTEND_1:
				return !flHave && Cs.pi.shopItems[ShopInfo.PODS] == 1;
			case ShopInfo.PODS_EXTEND_2:
				return !flHave && Cs.pi.shopItems[ShopInfo.PODS] == 1;
			case ShopInfo.LANDER_REACTOR_0:
				return !flHave && Cs.pi.gotItem(MissionInfo.LANDER_REACTOR);
			case ShopInfo.LANDER_REACTOR_1:
				return !flHave && Cs.pi.gotItem(MissionInfo.LANDER_REACTOR);
			case ShopInfo.LANDER_REACTOR_2:
				return !flHave && Cs.pi.gotItem(MissionInfo.LANDER_REACTOR);
			case ShopInfo.MINE_0:
				return !flHave && Cs.pi.gotItem(MissionInfo.MINES);
			case ShopInfo.MINE_1:
				return !flHave && Cs.pi.gotItem(MissionInfo.MINES);
			case ShopInfo.MINE_2:
				return !flHave && Cs.pi.gotItem(MissionInfo.MINES);
		}
		if (n >= ShopInfo.MISSILE && n < ShopInfo.MISSILE + 3) {
			return Cs.pi.missileMax > 0 && !flHave;
		}

		return !flHave;
	}

	function isBuyable(n) {
		switch (n) {
			case ShopInfo.AMMO:
				return Cs.pi.missileMax > Cs.pi.missile;
			case ShopInfo.DRONE_PERFO:
				return Cs.pi.drone > 0;
			case ShopInfo.DRONE_SPEED:
				return Cs.pi.drone > 0;
			case ShopInfo.DRONE_CONVERTER:
				return Cs.pi.drone > 0;
			case ShopInfo.DRONE_COLLECTOR:
				return Cs.pi.drone > 0;
		}

		return true;
	}

	// ITEMS
	function select(mc) {
		if (selection != null)
			unselect();

		selection = mc;
		mc.blendMode = pixi.core.Pixi.BlendModes.ADD;

		var price = Cs.pi.getPrice(mc.id);
		skin.field.text = Std.string(price);
		skin.gem._visible = true;
		//
		if (Cs.pi.minerai >= price) {
			active(skin.buy, buyItem);
			Col.setPercentColor(skin.gem, 0, 0);
			skin.field.style.fill = 0x00FF00;
			(cast skin.field.filters[0]).color = 0x00FF00;
			skin.gem.filters = [];
		} else {
			(cast skin.field.filters[0]).color = 0xFF0000;
			skin.field.style.fill = 0xFF0000;
			var c = new ColorMatrixFilter();
			c.hue(-120, false);
			skin.gem.filters = [c];
		}
	}

	function unselect() {
		selection.blendMode = pixi.core.Pixi.BlendModes.NORMAL;
		skin.field.text = "";
		skin.gem._visible = false;
		unactive(skin.buy);
	}

	// ACTION
	function buyItem() {
		switch (selection.id) {
			case ShopInfo.RADAR:
				Cs.pi.radar++;
				map.drawFog();
		}

		rOut(skin.buy);

		Api.buyItem(selection.id);
		unselect();
		cleanContent();
		initSeed();

		//
	}

	override function quit() {
		skin.removeMovieClip();
		initSquare(1);
	}

	function active(mc:display.ASprite, f) {
		mc.onRollOver = rOver.bind(mc);
		mc.onRollOut = rOut.bind(mc);
		mc.onDragOut = rOut.bind(mc);
		mc.onPress = f;
		mc.interactive = true;
		mc._alpha = 100;
	}

	function unactive(mc:display.ASprite) {
		mc.onRollOver = null;
		mc.onRollOut = null;
		mc.onDragOut = null;
		mc.onPress = null;
		mc.useHandCursor = false;
		mc.interactive = false;
		mc._alpha = 20;
	}

	function rOver(mc:display.ASprite) {
		mc.blendMode = pixi.core.Pixi.BlendModes.ADD;
	}

	function rOut(mc:display.ASprite) {
		mc.blendMode = pixi.core.Pixi.BlendModes.NORMAL;
	}

	public static var PALETTE = [
		[0x009933, 0x869405, 0x8D730C, 0x246F11,],
		[
			0x4176F1, 0x0F48CE, 0x0C389E, 0x12CBA6, 0x0FA485, 0x0C856C, 0xE8390F, 0xA8290B, 0x681A06, 0xF2DC15, 0xDCB10A, 0xDCB10A, 0x7D5924, 0x5C421B,
			0x8D61D1,
			0x5A2E9E, 0x402170, 0x838327, 0x686820, 0x55551A,
		],
		[
			0xF7FADA,
			0xEFF5B4,
			0xFDE4CE,
			0xFCD5AD,
			0xECDFCE,
			0xDDC8AA,
			0xDDE0B8,
			0xDDE0B8,
			0xD1D79F
		],
		[0xFF0000, 0xFF8800, 0x0044DD, 0x33DD00,],
	];
	// {
}
