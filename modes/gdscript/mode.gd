extends TextForgeMode

enum BlockTypes {
	TOOL,
	ICON,
	STATIC_UNLOAD,
	CLASS_NAME,
	EXTEDNS,
	COMMENT,
	SIGNAL,
	ENUM,
	CONSTANT,
	STATIC_VAR,
	EXPORT_VAR,
	VAR,
	ONREADY_VAR,
	STATIC_INIT,
	STATIC_FUNC,
	INIT,
	ENTER_TREE,
	READY,
	PROCESS,
	PHYSICS_PROCESS,
	METHOD,
	SUBCLASS,
}

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
	_enable_auto_format_feature()
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


func _auto_format(text: String) -> String:
	var auto_order: String = _auto_order(text)
	return auto_order


func _auto_order(text: String) -> String:
	var tokens := _tokenize_code(text)
	var types := _classify(tokens)
	var joined := _join(types)

	return joined


func _join(types: Dictionary[BlockTypes, Array]) -> String:
	var joined := ""
	if types[BlockTypes.TOOL].size():
		joined += "\n".join(types[BlockTypes.TOOL]) + "\n"
	if types[BlockTypes.ICON].size():
		joined += "\n".join(types[BlockTypes.ICON]) + "\n"
	if types[BlockTypes.STATIC_UNLOAD].size():
		joined += "\n".join(types[BlockTypes.STATIC_UNLOAD]) + "\n"
	if types[BlockTypes.CLASS_NAME].size():
		joined += "\n".join(types[BlockTypes.CLASS_NAME]) + "\n"
	if types[BlockTypes.EXTEDNS].size():
		joined += "\n".join(types[BlockTypes.EXTEDNS]) + "\n"
	if types[BlockTypes.COMMENT].size():
		if types[BlockTypes.COMMENT].any(func(l): return l.begins_with("##")):
			joined += "\n\n".join(types[BlockTypes.COMMENT].filter(func(l): return l.begins_with("##"))) + "\n"
		joined += "\n\n".join(types[BlockTypes.COMMENT].filter(func(l): return not l.begins_with("##"))) + "\n"

	var has_member := (
			types[BlockTypes.SIGNAL].size() + types[BlockTypes.ENUM].size() + types[BlockTypes.CONSTANT].size() +
			types[BlockTypes.STATIC_VAR].size() + types[BlockTypes.EXPORT_VAR].size() + types[BlockTypes.VAR].size() +
			types[BlockTypes.ONREADY_VAR].size() != 0
	)
	if has_member:
		joined += "\n"
		if types[BlockTypes.SIGNAL].size():
			types[BlockTypes.SIGNAL] = _sort_blocks(types[BlockTypes.SIGNAL], "signal")
			joined += "\n".join(types[BlockTypes.SIGNAL]) + "\n\n"
		if types[BlockTypes.ENUM].size():
			types[BlockTypes.ENUM] = _sort_blocks(types[BlockTypes.ENUM], "enum")
			joined += "\n".join(types[BlockTypes.ENUM]) + "\n\n"
		if types[BlockTypes.CONSTANT].size():
			types[BlockTypes.CONSTANT] = _sort_blocks(types[BlockTypes.CONSTANT], "const")
			joined += "\n".join(types[BlockTypes.CONSTANT]) + "\n\n"
		if types[BlockTypes.STATIC_VAR].size():
			types[BlockTypes.STATIC_VAR] = _sort_blocks(types[BlockTypes.STATIC_VAR], "static var")
			joined += "\n".join(types[BlockTypes.STATIC_VAR]) + "\n\n"
		if types[BlockTypes.EXPORT_VAR].size():
			types[BlockTypes.EXPORT_VAR].sort()
			joined += "\n".join(types[BlockTypes.EXPORT_VAR]) + "\n\n"
		if types[BlockTypes.VAR].size():
			types[BlockTypes.VAR] = _sort_blocks(types[BlockTypes.VAR], "var")
			joined += "\n".join(types[BlockTypes.VAR]) + "\n\n"
		if types[BlockTypes.ONREADY_VAR].size():
			types[BlockTypes.ONREADY_VAR] = _sort_blocks(types[BlockTypes.ONREADY_VAR], "@onready var")
			joined += "\n".join(types[BlockTypes.ONREADY_VAR]) + "\n\n"

	if types[BlockTypes.STATIC_INIT].size():
		joined += "\n\n\n".join(types[BlockTypes.STATIC_INIT]) + "\n\n\n"
	if types[BlockTypes.STATIC_FUNC].size():
		types[BlockTypes.STATIC_FUNC] = _sort_blocks(types[BlockTypes.STATIC_FUNC], "static func")
		joined += "\n\n\n".join(types[BlockTypes.STATIC_FUNC]) + "\n\n\n"
	if types[BlockTypes.INIT].size():
		joined += "\n\n\n".join(types[BlockTypes.INIT]) + "\n\n\n"
	if types[BlockTypes.ENTER_TREE].size():
		joined += "\n\n\n".join(types[BlockTypes.ENTER_TREE]) + "\n\n\n"
	if types[BlockTypes.READY].size():
		joined += "\n\n\n".join(types[BlockTypes.READY]) + "\n\n\n"
	if types[BlockTypes.PROCESS].size():
		joined += "\n\n\n".join(types[BlockTypes.PROCESS]) + "\n\n\n"
	if types[BlockTypes.PHYSICS_PROCESS].size():
		joined += "\n\n\n".join(types[BlockTypes.PHYSICS_PROCESS]) + "\n\n\n"
	if types[BlockTypes.METHOD].size():
		types[BlockTypes.METHOD] = _sort_blocks(types[BlockTypes.METHOD], "func")
		joined += "\n\n\n".join(types[BlockTypes.METHOD]) + "\n\n\n"
	if types[BlockTypes.SUBCLASS].size():
		types[BlockTypes.SUBCLASS] = _sort_blocks(types[BlockTypes.SUBCLASS], "class")
		joined += "\n\n\n".join(types[BlockTypes.SUBCLASS]) + "\n\n\n"

	return joined.strip_edges() + "\n"


func _sort_blocks(blocks: Array, prefix := "") -> Array:
	var sorted: Array = []
	var unsorted := blocks.duplicate()
	unsorted.sort_custom(func(a, b): return a.naturalcasecmp_to(b) < 0)
	sorted.append_array(unsorted.filter(_is_public.bind(prefix)))
	sorted.append_array(unsorted.filter(_is_public.bind(prefix, true)))
	return sorted


func _is_public(string: String, prefix := "", reverse := false) -> bool:
	if not reverse:
		return not string.begins_with(prefix + " _")
	else:
		return string.begins_with(prefix + " _")


func _classify(tokens: Array[String]) -> Dictionary[BlockTypes, Array]:
	var types: Dictionary[BlockTypes, Array]

	for i in BlockTypes:
		types[BlockTypes.get(i)] = []
	for t in tokens:
		var t_code: String = "\n".join(Array(t.split("\n")).filter(func(l): return not l.begins_with("#")))
		if t_code.begins_with("@tool"):
			types[BlockTypes.TOOL].append(t)
		elif t_code.begins_with("@icon"):
			types[BlockTypes.ICON].append(t)
		elif t_code.begins_with("@static_unload"):
			types[BlockTypes.STATIC_UNLOAD].append(t)
		elif t_code.begins_with("class_name "):
			types[BlockTypes.CLASS_NAME].append(t)
		elif t_code.begins_with("extends "):
			types[BlockTypes.EXTEDNS].append(t)
		elif Array(t.split("\n")).all(func(l): return l.begins_with("#")):
			types[BlockTypes.COMMENT].append(t)
		elif t_code.begins_with("signal "):
			types[BlockTypes.SIGNAL].append(t)
		elif t_code.begins_with("enum "):
			types[BlockTypes.ENUM].append(t)
		elif t_code.begins_with("const "):
			types[BlockTypes.CONSTANT].append(t)
		elif t_code.begins_with("static var "):
			types[BlockTypes.STATIC_VAR].append(t)
		elif t_code.begins_with("@export"):
			types[BlockTypes.EXPORT_VAR].append(t)
		elif t_code.begins_with("var "):
			types[BlockTypes.VAR].append(t)
		elif t_code.begins_with("@onready var "):
			types[BlockTypes.ONREADY_VAR].append(t)
		elif t_code.begins_with("static func _static_init("):
			types[BlockTypes.STATIC_INIT].append(t)
		elif t_code.begins_with("static func "):
			types[BlockTypes.STATIC_FUNC].append(t)
		elif t_code.begins_with("func _init("):
			types[BlockTypes.INIT].append(t)
		elif t_code.begins_with("func _enter_tree("):
			types[BlockTypes.ENTER_TREE].append(t)
		elif t_code.begins_with("func _ready("):
			types[BlockTypes.READY].append(t)
		elif t_code.begins_with("func _process("):
			types[BlockTypes.PROCESS].append(t)
		elif t_code.begins_with("func _physics_process("):
			types[BlockTypes.PHYSICS_PROCESS].append(t)
		elif t_code.begins_with("func "):
			types[BlockTypes.METHOD].append(t)
		elif t_code.begins_with("class "):
			types[BlockTypes.SUBCLASS].append(t)
		else:
			assert(false, "Invalid block type!\nCode block:\n" + t)

	return types


func _tokenize_code(text: String) -> Array[String]:
	var tokens: Array[String]
	var lines := text.split("\n")

	var t := ""
	for l in lines.size():
		lines[l] = lines[l].strip_edges(false, true)
		if lines[l].strip_edges() == "":
			if t != "":
				t += "\n"
			continue
		if (
				not lines[l].substr(0, 1) in [" ", "\t"]
				and t != ""
		):
			if lines[l].begins_with("#"):
				if t.ends_with("\n\n") or not t.split("\n")[-2].begins_with("#"):
					tokens.append(t.strip_edges())
					t = ""
			elif not t.split("\n")[-2].begins_with("#"):
				tokens.append(t.strip_edges())
				t = ""
		t += lines[l] + "\n"
	tokens.append(t.strip_edges())

	var temp_tokens := tokens.duplicate()
	tokens = []
	for token in temp_tokens:
		if tokens.is_empty():
			tokens.append(token)
			continue
		if token in ["}", ")", "]"]:
			tokens[-1] += "\n" + token
		else:
			tokens.append(token)

	return tokens


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
