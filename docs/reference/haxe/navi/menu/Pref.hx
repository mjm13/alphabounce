package navi.menu;

import mt.bumdum.Lib;

class AnonSprite14094327 extends display.ASprite {
	public var but0:display.ASprite;
	public var but1:display.ASprite;
	public var fieldTitle:pixi.core.text.Text;
	public var fieldMouse:pixi.core.text.Text;
	public var fieldQuality:pixi.core.text.Text;
}

class SlotBool extends display.ASprite {
	public var field:pixi.core.text.Text;
	public var id:Int;
	public var box:display.ASprite;
}

class Pref extends navi.Menu { // }
	static var START = 87;
	static var RANGE = 226;

	var skin:AnonSprite14094327;
	var bools:Array<SlotBool>;

	override function init() {
		super.init();

		skin = cast dm.attach("mcPref", 0);

		skin.initTextField("fieldTitle", {
			font: "GAU_font_cube_B",
			size: 20,
			x: 200,
			y: 18,
			align: "center",
			color: 0x00FF00,
		});
		skin.initTextField("fieldMouse", {
			font: "GAU_font_cube_B",
			size: 20,
			x: 200,
			y: 91,
			align: "center",
			color: 0x00FF00,
		});
		skin.initTextField("fieldQuality", {
			font: "GAU_font_cube_B",
			size: 20,
			x: 200,
			y: 166,
			align: "center",
			color: 0x00FF00,
		});

		skin.fieldTitle.text = Text.get.PREF_TITLE;
		skin.fieldMouse.text = Text.get.PREF_MOUSE;
		skin.fieldQuality.text = Text.get.PREF_QUALITY;

		initInter();
	}

	function initInter() {
		// BUTTONS
		var a = [quit];
		var x = Cs.mcw - 0.0;
		var id = 0;
		for (f in a) {
			var mc = dm.attach("mcWorldBut", 1);
			mc.gotoAndStop(id + 1);
			x -= mc._width + 4;
			mc._x = x;
			mc._y = Cs.mch - 22;
			mc.onRollOver = function() {
				mc.blendMode = pixi.core.Pixi.BlendModes.ADD;
			};
			mc.onRollOut = function() {
				mc.blendMode = pixi.core.Pixi.BlendModes.NORMAL;
			};
			mc.onDragOut = mc.onRollOut;
			mc.onPress = f;
			id++;
		}

		// SLIDER
		/*var a = [skin.but0, skin.but1];
			// var ly = [a[0]._y,a[1]._y];
			var me = this;
			for (i in 0...2) {
				var mc = a[i];
				mc.onPress = function() {
					mc.startDrag(false, START, mc._y, START + RANGE, mc._y);
				};
				mc.onRelease = function() {
					mc.stopDrag();
					me.setVal(i, (mc._x - START) / RANGE);
				};
				mc.onReleaseOutside = mc.onRelease;
		}*/

		// BOOLS
		bools = [];
		for (id in 0...4) {
			var mc:SlotBool = cast dm.empty(1);
			mc.initTextField("field", {
				font: "GAU_font_cube_B",
				size: 14,
				x: 72,
				color: 0x00FF00,
			});
			mc._y = 244 + id * 24;
			mc.id = id;
			mc.field.text = Text.get.PREF_FLAGS[id];
			mc.box = mc.attachMovie('radioBut', 'box', 0);
			mc.box.position.set(312, 2);
			mc.box.gotoAndStop(Cs.PREF_BOOLS[id] ? 2 : 1);
			mc.box.onPress = toggleBool.bind(id);
			bools.push(mc);
		}

		// DEFAULT
		var so = JSSharedObject.getLocal("pref");
		// skin.but0._x = START + RANGE * so.data.mouse;
		// skin.but1._x = START + RANGE * so.data.gfx;
	}

	function toggleBool(id) {
		var so = JSSharedObject.getLocal("pref");
		so.data.bools[id] = !so.data.bools[id];
		so.flush();
		Cs.loadPref();
		bools[id].box.gotoAndStop(Cs.PREF_BOOLS[id] ? 2 : 1);
	}

	function setVal(id, c) {
		var so = JSSharedObject.getLocal("pref");
		switch (id) {
			case 0:
				so.data.mouse = c;
			case 1:
				so.data.gfx = c;
		}
		// so.flush();
		Cs.loadPref();
	}

	// UPDATE
	override public function update() {
		super.update();
	}

	// {
}
