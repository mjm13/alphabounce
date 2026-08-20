package navi.menu;

import pixi.core.Pixi.BlendModes;

class AnonSprite1485835 extends display.ASprite {
	public var field:pixi.core.text.Text;
}

class AnonSprite9705834 extends display.ASprite {
	public var dm:mt.DepthManager;
	public var list:Array<display.ASprite>;
}

class People extends navi.Menu { // }
	var skin:AnonSprite1485835;
	var mcButs:AnonSprite9705834;

	var endTimer:Float;
	var txt:String;
	var cursor:Int;

	override function init() {
		super.init();
		skin = cast dm.attach("mcPeople", 1);
		skin.anchor.set(0, 0);
		skin.initTextField('field', {
			x: 10,
			y: 144,
			align: "left",
			font: "Verdana",
			wordWrap: 360,
			size: 11,
			color: 0x00FF00
		});
		navi.menu.Shop.initAlien(skin, bs);
		skin._x = navi.Menu.MARGIN;
		skin._y = navi.Menu.MARGIN * (Cs.mch / Cs.mcw);
	}

	function setText(str) {
		txt = str;
		cursor = 0;
		skin.field.text = str;
		skin.field.y = Math.max(143, 216 - skin.field.height * 0.5);
		skin.field.text = "";
	}

	function addBut(id, f) {
		if (mcButs == null) {
			mcButs = cast dm.empty(2);
			mcButs.list = [];
			mcButs.dm = new mt.DepthManager(mcButs);
			mcButs._y = 317;
		}

		var mc = mcButs.dm.attach("mcButPeople", 0);
		mc.anchor.set(0, 0);
		mc.initTextField('field', {
			x: 50,
			y: 0,
			align: "center",
			font: "GAU_font_cube_B",
			size: 15,
			color: 0xFFFFFF
		});
		var field:pixi.core.text.Text = (cast mc).field;
		field.text = Text.get.BUTTON_PEOPLE[id];
		// mc.smc._xscale = field.width;

		mc.onPress = f;
		mc.onRollOver = function() {
			mc.blendMode = pixi.core.Pixi.BlendModes.ADD;
		};
		mc.onRollOut = function() {
			mc.blendMode = BlendModes.NORMAL;
		};

		mcButs.list.push(mc);
		updateButPos();
	}

	function updateButPos() {
		var x = 0.0;
		for (mc in mcButs.list) {
			mc._x = x;
			x += mc._width + 10;
		}

		mcButs._x = Cs.mcw * 0.5 - mcButs._width * 0.5;
	}

	function removeAllButs() {
		mcButs.removeMovieClip();
	}

	override public function update() {
		super.update();

		if (cursor != null) {
			cursor++;
			var str = txt.substr(0, cursor);
			if (cursor % 3 > 0)
				str += "_";
			skin.field.text = str;

			if (txt.length == cursor)
				cursor = null;
		}

		if (endTimer != null) {
			endTimer -= mt.Timer.tmod;
			if (endTimer <= 0) {
				endTimer = null;
				quit();
			}
		}
	}

	// {
}
