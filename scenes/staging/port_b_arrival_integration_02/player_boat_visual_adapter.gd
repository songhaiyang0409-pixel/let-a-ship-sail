extends Node

## Reversible visual-only seam around the existing controlled boat root.
## Navigation, wave pose, camera and wake continue to target that outer root.

var motion_root: Node3D
var visual_mount: Node3D


func configure(controlled_root: Node3D, replacement_scene_path: String = "") -> void:
	motion_root = controlled_root
	visual_mount = motion_root.get_node_or_null("VisualModelMount_REPLACE_CONTENTS_ONLY") as Node3D
	if visual_mount == null:
		var visual_children: Array[Node] = motion_root.get_children()
		visual_mount = Node3D.new()
		visual_mount.name = "VisualModelMount_REPLACE_CONTENTS_ONLY"
		motion_root.add_child(visual_mount)
		for child in visual_children:
			if child is Node3D:
				child.reparent(visual_mount, true)
	visual_mount.set_meta("forward_axis", "-Z")
	visual_mount.set_meta("up_axis", "+Y")
	visual_mount.set_meta("units", "1 Godot unit = 1 meter")
	visual_mount.set_meta("expected_hull_length_m", 6.0)
	if replacement_scene_path.is_empty():
		print("PLAYER_BOAT_VISUAL_ADAPTER_READY|model=current|motion_root_untouched=true")
		return
	var packed := load(replacement_scene_path) as PackedScene
	if packed == null:
		push_error("Player boat replacement must be a loadable PackedScene: %s" % replacement_scene_path)
		return
	for child in visual_mount.get_children():
		child.queue_free()
	var replacement := packed.instantiate() as Node3D
	if replacement == null:
		push_error("Player boat replacement root must inherit Node3D.")
		return
	replacement.name = "FinalPlayerBoatVisual"
	visual_mount.add_child(replacement)
	print("PLAYER_BOAT_VISUAL_ADAPTER_READY|model=%s|motion_root_untouched=true" % replacement_scene_path)
