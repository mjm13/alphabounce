extends RefCounted
# 玩法尺寸比例：对齐 docs/reference/haxe/Cs.hx（BW=28, BH=14, 默认挡板宽约 72）。

const BW := 28.0
const BH := 14.0
const BALL_REF := 16.0
const PAD_REF := 72.0
const PAD_H_REF := 10.0


static func layout_for_viewport(vp: Vector2, cols: int) -> Dictionary:
	var field_w := vp.x * 0.40
	var gap := field_w * 0.012
	var block_w := (field_w - float(cols - 1) * gap) / float(cols)
	var block_h := block_w * (BH / BW)
	return {
		"block_w": block_w,
		"block_h": block_h,
		"gap": gap,
		"ball_d": block_w * (BALL_REF / BW),
		"pad_w": block_w * (PAD_REF / BW),
		"pad_h": maxf(block_h * (PAD_H_REF / BH), 22.0),
	}
