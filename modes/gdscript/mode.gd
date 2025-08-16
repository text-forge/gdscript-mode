extends TextForgeMode

var keyword_colors: Dictionary[Color, Array] = {
	Color(1, 0.44, 0.52, 1): ["await", "var", "in", "func", "false", "true", "const", "extends", "class", "class_name", "is", "not", "and", "or"],
	Color(1, 0.55, 0.8, 1): ["for", "while", "if", "return", "break", "continue", "else", "elif", "pass"],
	Color(1, 0.69, 0.45, 1): ["@", "export", "export_category", "export_color_no_alpha", "export_custom", "export_dir", "export_enum", "export_exp_easing", "export_file", "export_flags", "export_flags_2d_navigation", "export_flags_2d_physics", "export_flags_2d_render", "export_flags_3d_navigation", "export_flags_3d_physics", "export_flags_3d_render", "export_flags_avoidance", "export_global_dir", "export_global_file", "export_group", "export_multiline", "export_node_path", "export_placeholder", "export_range", "export_storage", "export_subgroup", "export_tool_button", "icon", "onready", "rpc", "static_unload", "tool", "warning_ignore", "warning_ignore_restore", "warning_ignore_start"]
}
var code_regions: Array[Array] = [
	[Color(1, 0.92, 0.64, 1), '"', '"', false],
	[Color(1, 0.92, 0.65, 1), "'", "'", false],
	[Color(0.38, 0.76, 0.36, 1), "$", "", true],
	[Color(0.38, 0.76, 0.35, 1), '$"', '"', false],
	[Color(0.38, 0.76, 0.34, 1), "$'", "'", false],
	[Color(0.8, 0.81, 0.82, 0.5), "#", "", true],
	[Color(0.6, 0.7, 0.8, 0.8), "##", "", true], 
]

func _initialize_mode() -> Error:
	_initialize_highlighter()
	comment_delimiters.append({
		"start_key": "#",
		"end_key": "",
		"line_only": true,
	})
	comment_delimiters.append({
		"start_key": "##",
		"end_key": "",
		"line_only": true,
	})
	string_delimiters.append({
		"start_key": '"',
		"end_key": '"',
		"line_only": false,
	})
	string_delimiters.append({
		"start_key": "'",
		"end_key": "'",
		"line_only": false,
	})
	return OK


func _update_code_completion_options(text: String) -> void:
	for color in keyword_colors:
		for keyword in keyword_colors[color]:
			Global.get_editor().add_code_completion_option(CodeEdit.KIND_CLASS, keyword, keyword, color)


func _generate_outline(text: String) -> Array:
	var outline := Array()
	for l in text.split("\n").size():
		var line := text.split("\n")[l]
		if line.begins_with("func "):
			outline.append([line.substr(5, line.find("(") - 5),l])
	return outline


# TODO
func _lint_file(text: String) -> Array[Dictionary]:
	return Array([], TYPE_DICTIONARY, "", null)


func _initialize_highlighter() -> void:
	syntax_highlighter = CodeHighlighter.new()
	syntax_highlighter.number_color = Color(0.63, 1, 0.88, 1)
	syntax_highlighter.symbol_color = Color(0.67, 0.79, 1, 1)
	syntax_highlighter.function_color = Color(0.35, 0.7, 1, 1)
	syntax_highlighter.member_variable_color = Color(0.73, 0.87, 1, 1)
	for color in keyword_colors:
		for keyword in keyword_colors[color]:
			syntax_highlighter.add_keyword_color(keyword, color)
	
	for region in code_regions:
		syntax_highlighter.add_color_region(region[1], region[2], region[0], region[3])
