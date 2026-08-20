package ev;

import mt.bumdum.Lib;
import mt.bumdum.Phys;

class PartBlock extends Phys {
	public var a:Float;
	public var c:Float;
	public var cs:Float;
	public var speed:Float;
	public var acc:Float;
	public var flBlock:Bool;
}

class Quasar extends Event { // }
	public static var RAY = 100;

	var mcCenter:display.ASprite;
	var list:Array<PartBlock>;
	var timer:Float;

	public function new() {
		super();

		mcCenter = Game.me.dm.attach("mcQuasar", Game.DP_UNDERPARTS);
		mcCenter.anchor.set(0.5, 0.5);
		mcCenter._x = Cs.mcw * 0.5;
		mcCenter._y = 100;
		mcCenter._xscale = mcCenter._yscale = 0;
		Filt.blur(mcCenter, 10, 10);

		timer = 60;

		list = [];
		// score = Cs.SCORE_0;
		for (x in 0...Cs.XMAX) {
			for (y in 0...Cs.YMAX) {
				Game.me.killZone(x, y);
				var bl = Game.me.grid.get('${x},${y}');
				if (bl != null) {
					var blx = Cs.getX(x + 0.5);
					var bly = Cs.getY(y + 0.5);
					var dx = blx - mcCenter._x;
					var dy = bly - mcCenter._y;
					var dist = Math.sqrt(dx * dx + dy * dy);
					var a = Math.atan2(dy, dx);
					if (dist < RAY) {
						// SCORE
						// KKApi.addScore(bl.score);
						// score = KKApi.cadd(score,bl.score);
						// score += KKApi.val(bl.score);

						// PARTS
						var mc = Game.me.dm.empty(Game.DP_UNDERPARTS);
						if (bl.type < 10) {
							var mcb = mc.attachMovie("mcBlockSmc", "base", 0);
							mcb.gotoAndStop(Std.int(bl.life) + 1);
							if (bl.color != null)
								Col.setColor(mcb, bl.color[0]);
						} else {
							if (bl.type == Block.INSECT || bl.type == Block.MINE) {
								var mcb = mc.attachMovie("mcBlockSmc", "base", 0);
								if (bl.color != null)
									Col.setColor(mcb, bl.color[0]);
							}
							var mcm = mc.attachMovie("mcBlock", "main", 1);
							mcm._x = mcm._y = -1;
							mcm.gotoAndStop(bl.type - 8);

							switch (bl.type) {
								case Block.PUSHER:
									var mce = mc.attachMovie("mcPusher", "extra", 2);
									mce.gotoAndStop(Std.int(bl.life) + 1);
								case Block.JUMPER:
									var mce = mc.attachMovie("mcJumperBlock", "extra", 2);
									mce.gotoAndStop(Std.int(bl.life) + 1);
								case Block.INSECT:
									for (i in 0...bl.extras.length) {
										var mce = mc.attachMovie("mcInsectBlock", "extra$i", 2);
										mce._x = bl.extras[i]._x;
										mce._y = bl.extras[i]._y;
										mce.anchor.set(0.5, 0.5);
									}
								case Block.NUT:
									var mce = mc.attachMovie("mcNutBlock", "extra", 2);
									mce.gotoAndStop(Std.int(bl.life) + 1);
								case Block.MINE:
									var mce = mc.attachMovie("mcMine", "extra", 2);
									mce._y = -1;
									mce.loop = true;
									mce.gotoAndPlay(bl.extras[0]._currentframe);
							}
						}
						mc._x = -Cs.BW * 0.5;
						mc._y = -Cs.BH * 0.5;

						var p = newPart(mc, blx, bly);
						p.flBlock = true;
						bl.kill();
					}
				}
			}
		}
	}

	override public function update() {
		super.update();
		mcCenter._rotation += 1;

		timer -= mt.Timer.tmod;
		var c = timer / 10;

		var lst = list.copy();
		for (p in lst) {
			var dx = mcCenter._x - p.x;
			var dy = mcCenter._y - p.y;
			var dist = Math.sqrt(dx * dx + dy * dy);
			var ta = Math.atan2(dy, dx);

			p.c = Math.min(p.c + p.cs * mt.Timer.tmod, 1);
			p.speed = Math.min(p.speed + p.acc * mt.Timer.tmod, 5);

			var da = Num.hMod(ta - p.a, 3.14);
			p.a += da * p.c * mt.Timer.tmod;

			p.vx = Math.cos(p.a) * p.speed;
			p.vy = Math.sin(p.a) * p.speed;

			var ds = Math.min(dist, p.scale) - p.scale;
			p.setScale(p.scale + ds * 0.1 * mt.Timer.tmod);

			if (c < 1 && p.flBlock)
				Col.setPercentColor(p.root, (1 - c) * 100, 0);

			if ((!p.flBlock || c < 0.5) && dist < 30 * (1 - c)) {
				p.kill();
				list.remove(p);
			}
		}

		// PARTS
		for (i in 0...Std.int(timer / 20)) {
			var a = Math.random() * 6.28;
			var r = Math.random() * 150;
			var x = mcCenter._x + Math.cos(a) * r;
			var y = mcCenter._y + Math.sin(a) * r;
			var p:PartBlock = newPart(Game.me.dm.attach("partLight", Game.DP_PARTS), x, y);
			p.acc = 0.4;
			p.cs = 0.001;
			// p.speed = 1;
			// p.timer = 10+Math.random()*10;
		}

		// FADE
		if (timer > 50)
			c = 1 - (timer - 50) / 10;
		if (c < 1) {
			mcCenter._xscale = mcCenter._yscale = c * 100;
		}

		if (timer < 0)
			kill();
	}

	function newPart(mc, x:Float, y:Float) {
		mc.anchor.set(0.5, 0.5);
		var dx = x - mcCenter._x;
		var dy = y - mcCenter._y;
		var a = Math.atan2(dy, dx);
		var p:PartBlock = cast new Phys(mc);
		p.x = x;
		p.y = y;
		p.fadeType = 0;
		p.a = a + 1.57;
		p.c = 0.05;
		p.cs = 0.003;
		p.speed = 0;
		p.acc = 0.2;
		p.flBlock = false;

		p.updatePos();
		list.push(p);
		return p;
	}

	override public function kill() {
		while (list.length > 0) {
			var p = list.pop();
			if (p.flBlock) {
				p.kill();
			} else {
				p.timer = 10 + Math.random() * 10;
			}
		}
		mcCenter.removeMovieClip();
		super.kill();
	}

	// {
}
