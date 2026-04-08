@tool
extends EditorPlugin

var shift_move_space: bool:
	get:
		return ProjectSettings.get_setting(SCRIPT_SHIFT_USAGE, false)

## Editor setting path
const SCRIPT_SHIFT_USAGE: StringName = &"plugin/gdscript_block_jumper/shift_move_to_space_behavior"


func _enter_tree() -> void:
	if ProjectSettings.has_setting(SCRIPT_SHIFT_USAGE):
		shift_move_space = ProjectSettings.get_setting(SCRIPT_SHIFT_USAGE, shift_move_space)
	else:
		ProjectSettings.set_setting(SCRIPT_SHIFT_USAGE, shift_move_space)
		ProjectSettings.set_initial_value(SCRIPT_SHIFT_USAGE, shift_move_space)
		ProjectSettings.set_as_basic(SCRIPT_SHIFT_USAGE, true)

	ProjectSettings.settings_changed.connect(sync_settings)


func _exit_tree() -> void:
	ProjectSettings.settings_changed.disconnect(sync_settings)


func sync_settings() -> void:
	shift_move_space = ProjectSettings.get_setting(SCRIPT_SHIFT_USAGE, shift_move_space)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		# Page Up
		if event.keycode == KEY_PAGEUP and event.pressed:
			var code_edit: CodeEdit = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
			if code_edit.has_focus():
				if event.shift_pressed:
					var shift_action := move_prev_empty_line if shift_move_space else move_prev_function
					shift_action.call(code_edit)
				else:
					var normal_action := move_prev_function if shift_move_space else move_prev_empty_line
					normal_action.call(code_edit)
				get_viewport().set_input_as_handled()

		# Page down
		if event.keycode == KEY_PAGEDOWN and event.pressed:
			var code_edit: CodeEdit = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
			if code_edit.has_focus():
				if event.shift_pressed:
					var shift_action := move_next_empty_line if shift_move_space else move_next_function
					shift_action.call(code_edit)
				else:
					var normal_action := move_next_function if shift_move_space else move_next_empty_line
					normal_action.call(code_edit)
				get_viewport().set_input_as_handled()

		# Fixes the removal of autocomplete on new blank lines
		if event.is_action_pressed("ui_text_newline_blank", true):
			var code_edit: CodeEdit = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
			code_edit.cancel_code_completion()
			code_edit.set_code_hint("")

		# Add colon endline and create newline
		if event.keycode == KEY_ENTER and event.pressed:
			var code_edit: CodeEdit = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
			if code_edit.has_focus():
				var this_ev : InputEventKey = InputEventKey.new()
				this_ev.keycode = KEY_ENTER
				this_ev.ctrl_pressed = true
				#this_ev.alt_pressed = true
				# Enter + Ctrl + Alt (not shift)
				if event.is_match(this_ev):
					add_colon_jump_line(code_edit)

					var blank_line_ev := InputMap.action_get_events("ui_text_newline_blank")[0]
					if not this_ev.is_match(blank_line_ev):
						execute_new_blank_line_shortcut()
						# Consume this input, since calling input key for newline
						get_viewport().set_input_as_handled()


#  Manually trigger the 'newline_blank' action
# # Did not work with InputAction #ev.action = "ui_text_newline_blank"
# # Needs manual InputEventKey
func execute_new_blank_line_shortcut() -> void:
	var ev = InputEventKey.new()
	ev = InputMap.action_get_events("ui_text_newline_blank")[0].duplicate()
	ev.pressed = true

	Input.parse_input_event(ev)
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)

func add_colon_jump_line(code_edit: CodeEdit) -> void:
	var caret_line = code_edit.get_caret_line()
	var column = code_edit.get_caret_column()

	var line_text = code_edit.get_line(caret_line)

	# Check if not empty and if it has colon
	if not line_text.strip_edges().ends_with(":"):
		var updated_text = line_text + ":"
		code_edit.set_line(caret_line, updated_text)
		# Set cursor to the end, so newline action can do its job
		code_edit.set_caret_column(updated_text.length())
	return


func move_prev_function(code_edit: CodeEdit) -> void:
	var caret_line = code_edit.get_caret_line()
	var text_lines = code_edit.text.split("\n")

	# Search backward for the function definition
	for i in range(caret_line-1, -1, -1):
		var line = text_lines[i].strip_edges()
		if line.begins_with("func "):
			code_edit.set_caret_line(i)
			code_edit.set_caret_column(line.length())
			return


func move_next_function(code_edit: CodeEdit) -> void:
	var caret_line = code_edit.get_caret_line()
	var text_lines = code_edit.text.split("\n")

	# Search fowards for the function definition
	for i in range(caret_line+1, text_lines.size()):
		var line = text_lines[i].strip_edges()
		if line.begins_with("func "):
			code_edit.set_caret_line(i)
			code_edit.set_caret_column(line.length())
			return


func move_next_empty_line(code_edit: CodeEdit) -> void:
	var caret_line = code_edit.get_caret_line()
	var text_lines = code_edit.text.split("\n")
	var skip_next_empty = text_lines[caret_line].is_empty()

	# Search fowards for the function definition
	for i in range(caret_line+1, text_lines.size()):
		var line = text_lines[i].strip_edges()
		if skip_next_empty:
			if line.is_empty():
				continue
			else:
				skip_next_empty = false
				continue
		if line.is_empty():
			code_edit.set_caret_line(i)
			code_edit.set_caret_column(line.length())
			return


func move_prev_empty_line(code_edit: CodeEdit) -> void:
	var caret_line = code_edit.get_caret_line()
	var text_lines = code_edit.text.split("\n")
	var skip_next_empty = text_lines[caret_line].is_empty()

	# Search backward for the function definition
	for i in range(caret_line-1, -1, -1):
		var line = text_lines[i].strip_edges()
		if skip_next_empty:
			if line.is_empty():
				continue
			else:
				skip_next_empty = false
				continue
		if line.is_empty():
			code_edit.set_caret_line(i)
			code_edit.set_caret_column(line.length())
			return
