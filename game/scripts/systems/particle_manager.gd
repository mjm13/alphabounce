extends Node
class_name ParticleManager

# [R13] 粒子特效系统：在事件位置生成一次性爆发粒子（方块击碎 / 球发射 / 导弹命中）。
# 采用 Godot GPUParticles2D 程序化实现：用 Image 生成的小圆点贴图 + ParticleProcessMaterial，
# 后续 R18 可替换为原版特效贴图，但接口（spawn_burst）保持不变。

const LIFETIME := 0.55

# 在 world 空间 position 处生成一次爆发；color 决定粒子色调
func spawn_burst(position: Vector2, color: Color = Color.WHITE, count: int = 16) -> void:
	var particles := GPUParticles2D.new()
	particles.position = position

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 50.0
	mat.initial_velocity_max = 150.0
	mat.gravity = Vector3(0, 0, 0)
	mat.lifetime_randomness = 0.4
	mat.scale_min = 0.5
	mat.scale_max = 1.6
	mat.color = color
	particles.process_material = mat

	particles.texture = _make_dot_texture()
	particles.amount = count
	particles.lifetime = LIFETIME
	particles.explosiveness = 1.0
	particles.one_shot = true
	particles.emitting = true

	add_child(particles)
	# one_shot 结束后自动清理
	particles.finished.connect(
		func():
			if is_instance_valid(particles):
				particles.queue_free()
	)

# 生成 8x8 白色圆点贴图（颜色由 material.color 着色）
func _make_dot_texture() -> Texture2D:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(8):
		for y in range(8):
			var d := Vector2(x - 3.5, y - 3.5).length()
			if d <= 3.5:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)
