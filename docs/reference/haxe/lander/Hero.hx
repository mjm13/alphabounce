package lander;

import mt.bumdum.Phys;
import mt.bumdum.Lib;
import lander.Game;

private enum Step {
	Fly;
	Land;
}

class Hero extends lander.pix.Phys { // }
	public static var WEIGHT = 0.5;
	public static var WALK_SPEED = 2;

	public var flWalk:Bool;
	public var flJump:Bool;
	public var flLandingReady:Bool;
	public var flControl:Bool;

	public var skinId:Int;
	public var run:Float;
	public var frame:Float;
	public var acc:Float;
	public var fuel:Float;

	public var min:Int;
	public var step:Step;

	public var currentHouse:House;

	var icon:Phys;

	public function new(id) {
		var mc = lander.Game.me.bdm.empty(lander.Game.DP_HERO);

		flControl = true;

		acc = 0.7;
		super(mc);
		initFly();
		colFrict = 0.5;
		min = 0;
		flLandingReady = false;

		skinId = id;
		playAnim("Fly");
	}

	public function update() {
		switch (step) {
			case Fly:
				updateFly();
			case Land:
				updateLanding();
		}

		if (currentHouse != null)
			currentHouse.update();

		checkMinCol(); // Minerals
		updateHouse(); // House interior visible or not
		updateIcon(); // ? Maybe talk to NPC or something

		var margin = 10;
		if (x < margin || x > lander.Game.WIDTH - margin) {
			x = Std.int(Num.mm(margin, x, lander.Game.WIDTH - margin));
		} else {
			if (!Pix.isFree(x, y)) {
				recalY();
			}
		}
	}

	// ANIM
	function playAnim(label) {
		var spriteName = "mcHero" + label;
		if (skinId == 2)
			spriteName += "_2";

		if (root.smc != null)
			root.smc.removeMovieClip();

		root.smc = root.attachMovie(spriteName);
		root.smc.anchor.set(0.5, 1);
		root.smc.play();
	}

	// FLY
	function initFly() {
		step = Fly;
		weight = WEIGHT * lander.Game.me.currentPlanet.g;
		root._xscale = 100;
		ox = 0.5;
		oy = 0.5;
	}

	public function updateFly() {
		var flThrust = false;
		var sens = 1.0;

		if (flJump) {
			if (lander.Game.me.flClick && skinId == 0 && flControl) {
				flJump = false;
				playAnim("Fly");
			}

			if (vx != 0)
				sens = Math.abs(vx) / vx;
		} else {
			var ta = Math.atan2(vy, vx);

			// THRUST

			if (lander.Game.me.flPress && flControl) {
				if (fuel > 0) {
					weight = WEIGHT;
					fuel -= mt.Timer.tmod;
					ta = getMouseAngle();
					vx += Math.cos(ta) * acc;
					vy += Math.sin(ta) * acc;
					flThrust = true;
				}
			}
			if (!flThrust)
				weight = WEIGHT * lander.Game.me.currentPlanet.g;

			// TOURNE DANS LE BON SENS
			var ca = Math.cos(ta);
			sens = ca / Math.abs(ca);
			if (ca == 0)
				sens = 1;

			ta = ta + 1.57 - 1.57 * sens;
			var da = Num.hMod((ta / 0.0174) - root._rotation, 180);

			var c = 0.04;
			if (flThrust)
				c = 0.3;
			root._rotation += Num.hMod(da * c, 180);
		}

		root._xscale = sens * 100;

		// PARTS
		if (flThrust) {
			// PARTS
			var ba = root._rotation * 0.0174 + 1.57 - 1.57 * sens;

			var ca = Math.cos(ba);
			var sa = Math.sin(ba);
			var ec = 16;
			var sp = 1 + Math.random() * 4;
			var p = new Phys(lander.Game.me.bdm.attach("partReactorSpark", lander.Game.DP_UNDERPARTS));
			var a = Math.random() * 6.28;
			var d = 2 + Math.random() * 18;
			p.x = (x - ca * ec) - Math.cos(a) * d;
			p.y = (y - sa * ec) - Math.sin(a) * d;
			p.vx = vx - ca * sp;
			p.vy = vy - sa * sp;
			// p.root.smc._x = d;
			p.root._rotation = a / 0.0174;
			p.vr = (Math.random() * 2 - 1) * 10;
			p.fr = 0.95;
			p.fadeType = 0;
			p.timer = 10 + Math.random() * 10;
			p.setScale(50 + Math.random() * 80);
		}

		// FLY
		fly();
		updatePos();

		// LIMIT
		var lim = 200;
		if (y < lim) {
			var c = y / lim;
			vy += (1 - c) * 3;
			vy *= c;
		}

		// CHECK LAND IN
		if (vy > 0) {
			if (flLandingReady) {
				var rx = (x + lander.Game.me.base._x).int();
				var ry = (y + lander.Game.me.base._y).int();

				// trace('Hit test $x $y (-lim=${y - 580}) : ' + lander.Game.me.isFree(x, y));
				if (lander.Game.me.pad.root.hitTest(rx, ry, true)) {
					lander.Game.me.pad.receiveHero();
				}
			}
		} else {
			flLandingReady = true;
		}
	}

	function recalY() {
		while (Pix.isFree(x, y + 1))
			y++;
		while (!Pix.isFree(x, y))
			y--;
	}

	override function onBounce(sx, sy) {
		super.onBounce(sx, sy);
		var vit = Math.sqrt(vx * vx + vy * vy);
		vx *= 0.5;
		vy *= 0.5;
		if (checkBalance()) {
			if (vit < 6 || flJump)
				initLanding();
		} else {
			trace('Bounce! But not balance.');
			var eq = Num.hMod((-1.57 - getNormal()), 3.14);
			trace(Math.abs(eq));
		}
	}

	public function checkBalance() {
		return true; // Hack

		var eq = Num.hMod((-1.57 - getNormal()), 3.14);
		return Math.abs(eq) <= 1.57;
	}

	// LAND
	function initLanding() {
		root._yscale = 100;

		step = Land;
		root._rotation = 0;

		vx = 0;
		vy = 0;
		weight = 0;
		parc = 0;

		run = 0;
		frame = 0;
		flWalk = false;
		fuel = 100;

		recalY();
		playAnim("Stand");
		updatePos();

		if (!flControl)
			lander.Game.me.initOutro();
	}

	function updateLanding() {
		if (lander.Game.me.flPress && flControl) {
			updateWalk();
		} else {
			if (flWalk) {
				var fr = root.smc._currentframe;
				if (fr < 5 || (fr >= 17 && fr < 22)) {
					root.smc.gotoAndStop(1);
				} else {
					root.smc.play();
				}
				flWalk = false;
			}
		}
		checkJump();
	}

	function updateWalk() {
		var dx = lander.Game.me.base._xmouse - (lander.Game.me.base.x + x);
		var sens = 1.0;
		if (dx != 0)
			sens = dx / Math.abs(dx);
		if (Math.abs(dx) < 30)
			dx = 0;
		var c = Num.mm(-2, dx / 60, 2);

		if (flWalk && c == 0) {
			flWalk = false;
			frame = 0;
			playAnim("Stand");
		}
		if (!flWalk && c != 0) {
			flWalk = true;
			playAnim("Run");
		}

		run += c * WALK_SPEED;

		frame = Num.sMod(frame + c * WALK_SPEED * 0.5, 33);
		root.smc.gotoAndStop(Std.int(frame) + 1);

		root._xscale = 100 * sens;

		while (run > 1) {
			run--;
			walk(1);
		}
		while (run < -1) {
			run++;
			walk(-1);
		}

		updatePos();
	}

	function walk(sens) {
		Pix.movePoint(this, sens);

		if (!checkBalance()) {
			Pix.movePoint(this, -sens);

			var a = getNormal();
			var speed = 1;
			vx = Math.cos(a) * speed;
			vy = Math.sin(a) * speed;
			initFly();
		}
	}

	function checkJump() {
		var a = getMouseAngle();
		var da = Num.hMod(a + 1.57, 3.14);
		var speed = 8;
		if (Math.abs(da) < 0.77 && lander.Game.me.flClick && flControl) {
			vx = Math.cos(a) * speed;
			vy = Math.sin(a) * speed;
			flJump = true;
			initFly();
			playAnim("Jump");
		}
	}

	// ICON
	public function setIcon(label) {
		if (icon == null) {
			var mc = lander.Game.me.bdm.attach("mcThink", lander.Game.DP_FOREGROUND);
			mc.stopOnFrame = [11];
			mc.anchor.set(1, 1);
			icon = new Phys(mc);
			icon.fadeType = 0;
		}
		icon.timer = 60;
		icon.setScale(100);
		// icon.root.smc.gotoAndStop(label);
	}

	function updateIcon() {
		// var b = root.getBounds(root);
		if (icon != null) {
			icon.x = x;
			icon.y = y - 15;
			icon.updatePos();

			if (icon.timer <= 0)
				icon = null;
		}

		// if(step==Land)mcIcon._y -= 20;
	}

	// HOUSES
	function updateHouse() {
		var ray = 75;

		if (currentHouse == null) {
			for (h in lander.Game.me.houses) {
				var dx = x - h.x;
				var dy = y - h.y;
				if (Math.abs(dx) + Math.abs(dy) < ray && Math.sqrt(dx * dx + dy * dy) < ray) {
					currentHouse = h;
					h.active();
				}
			}
		} else {
			var h = currentHouse;
			var dx = x - h.x;
			var dy = y - h.y;
			if (Math.sqrt(dx * dx + dy * dy) > ray + 10) {
				currentHouse = null;
				h.unactive();
			}
		}
	}

	// TOOLS
	function getPos() {
		return {x: x + ox, y: y + oy};
	}

	// MIN
	function checkMinCol() {
		for (min in lander.Game.me.minerals) {
			var dx = x - min.root._x;
			var dy = y - min.root._y;
			var c = 0.5;
			if (Math.abs(dx) < min.root._width * c && Math.abs(dy) < min.root._height * c) {
				min.collect();
				// lander.Game.me.incMinerai(min.val);
				this.min += min.val;
			}
		}
	}

	// TOOLS
	function getMouseAngle() {
		var dx = lander.Game.me.base._xmouse - (lander.Game.me.base.x + x);
		var dy = lander.Game.me.base._ymouse - (lander.Game.me.base.y + y);
		return Math.atan2(dy, dx);
	}

	override public function kill() {
		lander.Game.me.hero = null;
		super.kill();
	}

	// {
}
