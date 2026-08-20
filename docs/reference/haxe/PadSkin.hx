import pixi.core.Pixi.BlendModes;
import mt.bumdum.Phys;
import mt.bumdum.Lib;

class MidSprite extends ASprite {
	public var bar:display.ASprite;
}

class AnonSprite964824 extends display.ASprite {
	public var side0:display.ASprite;
	public var side1:display.ASprite;
	public var mid:MidSprite;
}

class PadSkin extends Phys { // }
	public static var SIDE = 12;
	public static var HEIGHT = 10;

	public var ray:Float;
	public var type:Int;

	public var skinId:Int;

	var dm:mt.DepthManager;

	public var skin:AnonSprite964824;

	var mcReactor:display.ASprite;

	public function new(mc) {
		super(mc);
		skin = cast root;
		skin.anchor.set(0.5, 0);
		skin.mid = cast mc.attachMovie('mcPadMid', 'mid', 2);
		skin.mid.y = -1;
		skin.mid.bar = skin.mid.attachMovie('mcPadMidSmc', 'bar', 0);
		skin.mid.bar.x = 50;
		skin.mid.bar.y = 6;
		skin.mid.bar.anchor.set(0.5, 0.5);

		skin.side0 = mc.attachMovie('mcPadSide', 'side0', 1);
		skin.side0.y = -5;
		skin.side1 = mc.attachMovie('mcPadSide', 'side1', 1);
		skin.side1.y = -5;
		skin.side1.scale.x = -1;

		dm = new mt.DepthManager(root);
		skinId = 0;

		if (Cs.pi.gotItem(MissionInfo.MEDAL))
			skinId = 1;
	}

	public function setType(n:Int) {
		type = n;
		
		// sides
		switch (type) {
			case 2 | 3:
				skin.side0.gotoAndStop(skinId + 3);
				skin.side1.gotoAndStop(skinId + 3);
			case _:
				skin.side0.gotoAndStop(skinId + 1);
				skin.side1.gotoAndStop(skinId + 1);
		}
		
		// bar
		skin.mid.bar.visible = false;
		switch (type) {
			case 0:
				skin.mid.gotoAndStop(skinId + 1);
			case 1:
				skin.mid.gotoAndStop(skinId + 3);
			case _:
				skin.mid.gotoAndStop(skinId + 5);
				skin.mid.bar.gotoAndStop(type - 1);
				skin.mid.bar.visible = true;
		}
	}

	public function setRay(r) {
		ray = r;
		var w = (r - SIDE) + 1;
		skin.mid._xscale = w * 2;
		skin.mid._x = -w;
		skin.side0._x = -r;
		skin.side1._x = r;
	}

	public function setReactor(fl) {
		if (fl) {
			mcReactor = dm.attach("mcReactor", 0);
			mcReactor.anchor.set(0, 0);
			mcReactor.smc = mcReactor.attachMovie('mcReactorSmc');
			mcReactor.smc.anchor.set(0, 0);
			mcReactor.smc.position.set(0, 2);
			mcReactor.smc._visible = true;
			mcReactor._y = 10.5;
		} else {
			mcReactor.removeMovieClip();
			mcReactor = null;
		}
	}

	public function explode(bmc) {
		var dm = new mt.DepthManager(bmc);
		var sp = new mt.bumdum.Phys(bmc);
		sp.x = x;
		sp.y = y;
		sp.updatePos();
		sp.timer = 100;
		sp.root._rotation = root._rotation;

		var max = Std.int(2 * ray / Cs.BW);
		var inc = ((2 * ray) % max) / max;

		for (i in 0...max) {
			var mc = dm.attach("partExplode", 0);
			mc.play();
			mc.removeOnFrame = 24;
			var px = -ray + i * (Cs.BW + inc);
			mc._x = px;
			mc._y = 0;
			Col.setColor(mc, 0xFCF0B0, -220);
			for (n in 0...10) {
				var p = new Phys(dm.attach("mcPart", 0));
				p.root.gotoAndStop(Std.random(p.root._totalframes));
				p.x = px + Math.random() * (Cs.BW + inc);
				p.y = Math.random() * 12;
				p.vy = 0.75 - Math.random() * 1.5;
				p.vx = (p.x / ray) * 3;
				Col.setColor(p.root, 0xFCF0B0, -(200 + Std.random(50)));
				// p.weight = 0.1+Math.random()*0.15;
				p.timer = 10 + Math.random() * 20;
				p.fadeType = 0;
				p.setScale(50 + Math.random() * 70);
				p.root._rotation = Std.random(360);
				p.updatePos();
			}
		}

		var mc = dm.attach("fxPadExplosion", 0);
		mc.anchor.set(0.5, 0.5);
		mc._y = 5;
		mc.blendMode = BlendModes.ADD;
		mc.removeOnFrame = 13;
		mc.play();
		var smc = dm.attach("fxPadExplosionSmc", 0);
		smc.anchor.set(0.5, 0.5);
		smc._y = 5;
		smc._xscale = ray * 2;
		smc.blendMode = BlendModes.ADD;
		smc.removeOnFrame = 15;
		smc.play();

		for (i in 0...4) {
			var mc = dm.attach("fxPadMiniExplosion", Game.DP_PARTS);
			mc.play();
			mc.removeOnFrame = 14;
			mc._x = (Math.random() * 2 - 1) * ray * 0.8;
			mc._y = HEIGHT * 0.5 + (Math.random() * 2 - 1) * 2;
			mc._xscale = mc._yscale = 100 + Math.random() * 100;
			mc.gotoAndPlay(Std.random(4) + 1);
			mc.blendMode = BlendModes.ADD;
		}

		//
		kill();
	}

	// {
}
