package el.shot;

import pixi.core.graphics.Graphics;
import mt.bumdum.Lib;

class Laser extends el.Shot { // }
	var flHit:Bool;
	var height:Float;
	var vit:Float;
	var mask:Graphics;

	public function new(mc) {
		super(mc);
		mc.anchor.set(0.5, 0);

		this.mask = new Graphics();
		mask.beginFill(0xFF0000);
		mask.drawRect(-3, 0, 6, 183);
		mc.mask = mask;
		mc.addChild(mask);

		height = 44;
		this.mask.scale.y = 0;
		flHit = false;
	}

	override public function update() {
		super.update();
		var sens = 1;
		if (flHit)
			sens = -1;
		this.mask.scale.y = Num.mm(0, this.mask.scale.y + vit * mt.Timer.tmod * sens, height);
		if (flHit && this.mask.scale.y == 0)
			kill();
		Game.me.plasmaDraw(root);
	}

	public function setVit(n) {
		vit = n;
		vy = -n;
	}

	override public function hit() {
		flHit = true;
		vy = 0;
	}

	// {
}
