@tool
extends EditorPlugin

var safe_colon : bool = true
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

				if event.ctrl_pressed:
					_navigate_block_boundary_start(code_edit)
					get_viewport().set_input_as_handled()
					return
				elif event.alt_pressed:
					navigate_prev_block_start(code_edit)
					get_viewport().set_input_as_handled()
					return

				elif event.shift_pressed:
					var shift_action := move_prev_empty_line if shift_move_space else move_prev_function
					shift_action.call(code_edit)
				else: # No modifier
					var normal_action := move_prev_function if shift_move_space else move_prev_empty_line
					normal_action.call(code_edit)
				get_viewport().set_input_as_handled()

		# Page down
		if event.keycode == KEY_PAGEDOWN and event.pressed:
			var code_edit: CodeEdit = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
			if code_edit.has_focus():

				if event.ctrl_pressed:
					_navigate_block_boundary_end(code_edit)
					get_viewport().set_input_as_handled()
					return
				elif event.alt_pressed:
					navigate_next_block_start(code_edit)
					get_viewport().set_input_as_handled()
					return

				elif event.shift_pressed:
					var shift_action := move_next_empty_line if shift_move_space else move_next_function
					shift_action.call(code_edit)
				else: # No modifier
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
				# Enter + Ctrl
				if event.is_match(this_ev):
					var text = code_edit.get_line(code_edit.get_caret_line())
					if not safe_colon or _is_safe_colon(text):
						add_colon_jump_line(code_edit)

					var blank_line_ev := InputMap.action_get_events("ui_text_newline_blank")[0]
					if not this_ev.is_match(blank_line_ev):
						execute_new_blank_line_shortcut()
						# Consume this input, since calling input key for newline
						get_viewport().set_input_as_handled()

#region /// Blank Colon Line (Ctrl + Enter)
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
#endregion

#region /// Jump Empty Lines (no modifier) and Funcs (Shift)
func move_prev_function(code_edit: CodeEdit) -> void:
	var caret_line = code_edit.get_caret_line()
	var text_lines = code_edit.text.split("\n")

	# Search backward for the function definition
	for i in range(caret_line-1, -1, -1):
		var line = text_lines[i].strip_edges()
		if line.begins_with("func "):
			code_edit.set_caret_line(i)
			code_edit.set_caret_column(line.length())
			code_edit.unfold_line(i)
			return


func move_next_function(code_edit: CodeEdit) -> void:
	var caret_line = code_edit.get_caret_line()
	var text_lines = code_edit.text.split("\n")

	# Search fowards for the function definition
	for i in range(caret_line+1, text_lines.size()):
		var line = text_lines[i].strip_edges()
		if line.begins_with("func "):
			code_edit.set_caret_line(i)
			code_edit.unfold_line(i)
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
			code_edit.unfold_line(i)
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
			code_edit.unfold_line(i)
			code_edit.set_caret_column(line.length())
			return
#endregion

#region /// Indented Block Boundary (Ctrl)
func _navigate_block_boundary_start(code_edit: CodeEdit) -> void:
	var reference_line = code_edit.get_caret_line()
	while reference_line >= 0 and code_edit.get_line(reference_line).strip_edges() == "":
		reference_line -= 1

	# If the file is empty above the cursor, stop
	if reference_line < 0: return

	#var target_line = current_line - 1
	var target_line = reference_line
	var current_indent = _get_indent_level(code_edit.get_line(target_line))

	while target_line >= 0:
		var prev_text = code_edit.get_line(target_line)

		if _is_func_start(prev_text):
			if reference_line == target_line:
				navigate_prev_block_start(code_edit)
				return
			code_edit.set_caret_line(target_line)
			code_edit.unfold_line(target_line)
			return

		if _is_block_start(prev_text) and _get_indent_level(prev_text) < current_indent:
			code_edit.set_caret_line(target_line)
			code_edit.unfold_line(target_line)
			return

		target_line -= 1
	pass


func _navigate_block_boundary_end(code_edit: CodeEdit) -> void:
	var current_line = code_edit.get_caret_line()
	var total_lines = code_edit.get_line_count()

	# Get "Reference Line" (first non-empty line at or above cursor)
	var reference_line = current_line
	while reference_line >= 0 and code_edit.get_line(reference_line).strip_edges() == "":
		reference_line -= 1

	if reference_line < 0: return

	# Find the actual start of the current block to get the base indentation
	var start_line = reference_line
	var line_text = code_edit.get_line(start_line)
	var base_indent = _get_indent_level(line_text)
	# If not start, than remove indent to equal start block
	if not _is_block_start(line_text):
		base_indent -= 1
	var last_valid_line = start_line

	# Scan down to find the last line that is still indented further than base_indent
	for i in range(start_line + 1, total_lines):
		var check_text = code_edit.get_line(i)

		# Skip trimmed empty lines
		if check_text.strip_edges() == "":
			continue
		# Skip comments
		if check_text.strip_edges().begins_with("#"):
			continue

		var check_indent = _get_indent_level(check_text)

		if check_indent > base_indent:
			last_valid_line = i
		else:
			# Line with same or less indent (end of block)
			break

	## Go to next valid code line if last line of block
	if last_valid_line == current_line:
		navigate_next_block_start(code_edit)
		return
		#for i in range(start_line + 1, total_lines):
			#last_valid_line += 1
			#if not code_edit.get_line(i).strip_edges() == "":
				#break

	code_edit.set_caret_line(last_valid_line)
	code_edit.unfold_line(last_valid_line)
	code_edit.set_caret_column(code_edit.get_line(last_valid_line).length())

#endregion

#region /// Unindented Block Movement (Alt)
## Increment +1 for next(down) and -1 for previous(up)
func _navigate_to_block(code_edit : CodeEdit, increment : int = 1):
	var current_line = code_edit.get_caret_line()
	var line_text = code_edit.get_line(current_line)
	var current_indent = _get_indent_level(line_text)

	var target_line = current_line + increment
	var total_lines = code_edit.get_line_count()

	while target_line < total_lines and target_line >= 0:
		var next_text = code_edit.get_line(target_line)
		if _is_block_start(next_text):
			code_edit.set_caret_line(target_line)
			code_edit.unfold_line(target_line)
			return
		target_line += increment

func navigate_next_block_start(code_edit : CodeEdit):
	_navigate_to_block(code_edit)

func navigate_prev_block_start(code_edit : CodeEdit):
	_navigate_to_block(code_edit, -1)
#endregion

#region /// Common
func _is_func_start(text: String) -> bool:
	var s = text.strip_edges()
	return s.begins_with("func ")

func _is_block_start(text: String) -> bool:
	var s = text.strip_edges()
	return s.begins_with("if ") or s.begins_with("for ") or s.begins_with("func ") or s.begins_with("while ") or s.begins_with("elif ") or s.begins_with("else:")

func _is_safe_colon(text: String) -> bool:
	var s = text.strip_edges()
	if s.ends_with(":"): return false
	if s.contains(" return") or s.contains(":return"): return false
	return s.begins_with("if ") or s.begins_with("for ") or s.begins_with("func ") or s.begins_with("while ") or s.begins_with("elif ") or s.begins_with("else")


func _get_indent_level(text: String) -> int:
	var count = 0
	for c in text:
		if c == "\t":
			count += 1
		elif c == " ":
			continue
		else:
			break
	return count
#endregion
