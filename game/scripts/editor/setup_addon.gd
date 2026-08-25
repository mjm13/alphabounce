extends EditorScript

func _run():
	print("Setting up MCP addon...")
	# The plugin enable state is stored in project.godot [addons] section
	# We need to ensure it's enabled there
	var addons_section = {
		"godot_mcp/enabled": true,
		"godot_mcp/path": "res://addons/godot_mcp/plugin.cfg"
	}
	# Also try the editor/plugins setting
	var plugins = {
		"godot_mcp": {
			"enabled": true,
			"path": "res://addons/godot_mcp/plugin.cfg",
			"version": "4.1.0"
		}
	}
	ProjectSettings.set_setting("editor/plugins", plugins)
	ProjectSettings.save()
	print("Setup complete")
	quit()
