extends Control

const TIMES := ["清晨", "上午", "中午", "下午", "深夜"]
const LOCATIONS := ["钟塔", "广场", "运河", "博物馆", "档案馆", "工坊"]
const CHARACTER_NAMES := ["现代人", "过去人"]
const TIMELINE_NAMES := ["现在时间线", "过去时间线"]
const CHARACTER_COLORS := [Color("#55c2ff"), Color("#f4b860")]
const LOCATION_DETAILS := {
	"钟塔": "现代组地点技能\n现代人持有「钥匙」时可以触发一次响铃，并检查全部胜利条件。\n\n过去组地点技能\n过去人至少持有 1 个「石头」和 1 份「文件」时，可以获得 1 个「铃铛」。\n\n地点技能可在抽事件卡前，或看完事件卡后、回合结束前使用；每回合只能触发一次。",
	"广场": "现代组效果\n丢弃任意 1 件物品，可以触发一次响铃并检查全部胜利条件。\n\n过去组效果\n处理事件后，若本回合没有获得物品，可以让本回合结束时过去时间不前进。",
	"运河": "现代组效果\n可以选择获得「石头」×1；若获得，过去组时间立即前进一格。\n\n过去组效果\n处理事件卡后必须触发：若持有石头，失去「石头」×1；否则获得「石头」×1。",
	"博物馆": "现代组效果\n处理事件后强制触发：获得「文件」×1；若此时拥有至少 2 份文件，必须选择失去任意物品 ×1。\n\n过去组效果\n处理事件后强制触发：若持有文件，失去「文件」×1；否则无事发生。",
	"档案馆": "现代组效果\n抽事件前必须选择：可以将「文件」×1换成「钥匙」×1；若不交换，本次事件卡的获得、失去、更换物品等效果全部无效。\n\n过去组效果\n占据后强制触发：将「石头」×1换成「文件」×1；若没有石头，过去时间立即额外前进一格。",
	"工坊": "现代组效果\n可选择一人穿越到过去，并可携带物品 ×1；若携带物品，现代时间立即额外前进一格。\n\n过去组效果\n可选择一人穿越到现在，不能携带物品；穿越者下一轮不能再次穿越。"
}
const MODERN_EVENT_CARDS: Array[Dictionary] = [
	{
		"id": "modern_01",
		"card_number": "M-001",
		"title": "访客",
		"description": "一位神秘访客来到你面前。他似乎在寻找档案中的某个名字。",
		"effect_text": "若持有至少 2 份「文件」，失去「文件」×1；否则获得「钥匙」×1。"
	},
	{
		"id": "modern_02",
		"card_number": "M-002",
		"title": "系统测试",
		"description": "钟塔控制系统进入测试模式，一段模拟钟声等待确认。",
		"effect_text": "若持有「铃铛」，可以选择触发一次响铃；触发前，现代时间先前进一格。"
	},
	{
		"id": "modern_03",
		"card_number": "M-003",
		"title": "误以为已经完成",
		"description": "两条时间线的物资清单看起来几乎一致，但最后一次核对仍未完成。",
		"effect_text": "结算时比较两条时间线的全部物品与数量：若不同，现代组必须丢弃物品 ×1；若相同，现代组获得「文件」×1。可在地点效果前或后结算。"
	}
]
const PAST_EVENT_CARDS: Array[Dictionary] = [
	{
		"id": "past_01",
		"card_number": "P-001",
		"title": "钟尚未存在",
		"description": "你在尚未建成钟塔的年代，发现了一块带有奇异回声的材料。",
		"effect_text": "获得「石头」×1；若位于钟塔，改为获得「铃铛」×1。"
	},
	{
		"id": "past_02",
		"card_number": "P-002",
		"title": "工匠的第一块石料",
		"description": "老工匠仔细检查堆放在墙边的石料，只留下最适合钟塔的一块。",
		"effect_text": "若持有至少 2 个「石头」，失去「石头」×1；否则获得「石头」×1。"
	},
	{
		"id": "past_03",
		"card_number": "P-003",
		"title": "误差",
		"description": "一块多余的石料填补了眼前的误差，却让下一次时间穿越变得极不稳定。",
		"effect_text": "获得「石头」×1。下一次任何角色真正穿越时都不能携带物品；穿越完成后此限制解除。"
	}
]

var active_character := 0
var time_indices := [0, 0]
var occupied_locations := ["", ""]
var event_decks: Array[Array] = [[], []]
var selected_location := ""
var location_buttons: Dictionary = {}
var turn_label: Label
var instruction_label: Label
var timeline_rows: Array[HBoxContainer] = []
var character_panels: Array[PanelContainer] = []
var inventory_labels: Array[Label] = []
var people_labels: Array[Label] = []
var draw_button: Button
var review_event_button: Button
var event_overlay: ColorRect
var event_title: Label
var event_body: Label
var event_card_panel: PanelContainer
var event_card_tween: Tween
var current_event_card: Dictionary = {}
var current_event_result := ""
var event_drawn_this_turn := false
var event_effect_resolved := false
var settlement_in_progress := false
var event_choice_pending := false
var mandatory_action_pending := false
var mandatory_action_source := ""
var deferred_event_pending := false
var travel_carry_blocked_once := false
var location_overlay: ColorRect
var location_title: Label
var location_body: Label
var location_choose_button: Button
var location_card_panel: PanelContainer
var location_card_tween: Tween
var location_effects_row: HBoxContainer
var location_modern_panel: PanelContainer
var location_past_panel: PanelContainer
var location_modern_title: Label
var location_past_title: Label
var location_modern_body: Label
var location_past_body: Label
var location_timing_label: Label
var location_being_viewed := ""
var location_action_button: Button
var end_turn_button: Button
var inventories: Array[Array] = [[], []]
var event_resolved := false
var tower_attempted_this_turn := false
var location_skill_used_this_turn := false
var items_gained_this_turn := 0
var items_lost_this_turn := 0
var prevent_time_advance := false
var event_item_effects_enabled := true
var archive_choice_made := false
var person_timelines := [0, 1]
var travel_cooldowns := [0, 0]
var empty_turn_in_progress := false
var item_choice_overlay: ColorRect
var item_choice_list: VBoxContainer
var effect_feedback_layer: Control
var effect_feedback_list: VBoxContainer
var game_mode := "single"
var player_character := 0
var ai_turn_in_progress := false
var game_over := false


func _ready() -> void:
	setup_chinese_font()
	show_home()


func setup_chinese_font() -> void:
	var chinese_font := FontFile.new()
	var load_error := chinese_font.load_dynamic_font("res://assets/fonts/NotoSansCJKsc-Regular.otf")
	if load_error != OK:
		push_error("无法加载中文字体：%s" % error_string(load_error))
		return
	var interface_theme := Theme.new()
	interface_theme.default_font = chinese_font
	theme = interface_theme


func clear_screen() -> void:
	for child in get_children():
		child.queue_free()
	location_buttons.clear()
	timeline_rows.clear()
	character_panels.clear()
	inventory_labels.clear()
	people_labels.clear()


func make_background() -> void:
	var background := ColorRect.new()
	background.color = Color("#101827")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var glow := ColorRect.new()
	glow.color = Color("#17243a")
	glow.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	glow.position = Vector2(0, -230)
	glow.size = Vector2(520, 460)
	background.add_child(glow)
	var gold_line := ColorRect.new()
	gold_line.color = Color("#d39b4a")
	gold_line.position = Vector2(0, 0)
	gold_line.size = Vector2(7, 460)
	glow.add_child(gold_line)


func make_label(text: String, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func make_button(text: String, min_size := Vector2(220, 54)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 24)
	apply_button_style(button, Color("#55c2ff"), false)
	return button


func apply_button_style(button: Button, accent: Color, filled: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = accent if filled else Color("#1b2940")
	normal.border_color = accent if filled else Color("#52627a")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	normal.content_margin_left = 24
	normal.content_margin_right = 24
	var hover := normal.duplicate()
	hover.bg_color = accent.lightened(0.12) if filled else Color("#263a57")
	hover.border_color = accent.lightened(0.18)
	hover.shadow_color = Color(0, 0, 0, 0.35)
	hover.shadow_size = 7
	var pressed := normal.duplicate()
	pressed.bg_color = accent.darkened(0.14) if filled else Color("#111c2d")
	var disabled := normal.duplicate()
	disabled.bg_color = Color("#17202f")
	disabled.border_color = Color("#334157")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color("#101827") if filled else Color("#f6f0df"))
	button.add_theme_color_override("font_hover_color", Color("#101827") if filled else Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("#101827") if filled else Color("#d8e1ee"))
	button.add_theme_color_override("font_disabled_color", Color("#66758b"))


func show_home() -> void:
	clear_screen()
	make_background()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 76)
	margin.add_theme_constant_override("margin_right", 76)
	margin.add_theme_constant_override("margin_top", 62)
	margin.add_theme_constant_override("margin_bottom", 54)
	add_child(margin)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 64)
	margin.add_child(layout)
	var hero := VBoxContainer.new()
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	hero.add_theme_constant_override("separation", 18)
	layout.add_child(hero)
	var eyebrow := make_label("A TIME-BENDING COOPERATIVE GAME", 18, Color("#f4b860"))
	hero.add_child(eyebrow)
	var title := make_label("DOM\nTOWER", 74, Color("#f6f0df"))
	title.add_theme_constant_override("line_spacing", -8)
	hero.add_child(title)
	var title_line := ColorRect.new()
	title_line.color = Color("#d39b4a")
	title_line.custom_minimum_size = Vector2(180, 4)
	title_line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hero.add_child(title_line)
	var goal := make_label("让跨越时空的钟声\n再次响起", 30, Color("#b9c7db"))
	hero.add_child(goal)
	var lore := make_label("两条时间线，一座沉默的钟塔。\n交换线索、穿越时代，并肩找回失落的钟声。", 18, Color("#8190a8"))
	hero.add_child(lore)
	var menu_panel := PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(430, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#172337")
	panel_style.border_color = Color("#344967")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(20)
	panel_style.shadow_color = Color(0, 0, 0, 0.42)
	panel_style.shadow_size = 18
	panel_style.content_margin_left = 42
	panel_style.content_margin_right = 42
	panel_style.content_margin_top = 46
	panel_style.content_margin_bottom = 40
	menu_panel.add_theme_stylebox_override("panel", panel_style)
	layout.add_child(menu_panel)
	var menu := VBoxContainer.new()
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_theme_constant_override("separation", 20)
	menu_panel.add_child(menu)
	var clock_mark := make_label("—  时 间 档 案  —", 18, Color("#f4b860"))
	clock_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(clock_mark)
	var menu_title := make_label("准备好了吗？", 32, Color("#f6f0df"))
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(menu_title)
	var menu_detail := make_label("选择单人轮流操作，\n或与 AI 跨越时空合作。", 20, Color("#93a4bd"))
	menu_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(menu_detail)
	menu.add_child(HSeparator.new())
	var start_button := make_button("开始游戏", Vector2(330, 68))
	apply_button_style(start_button, Color("#f4b860"), true)
	start_button.pressed.connect(show_mode_select)
	menu.add_child(start_button)
	var quit_button := make_button("退出游戏", Vector2(330, 58))
	quit_button.pressed.connect(quit_game)
	menu.add_child(quit_button)
	var hint := make_label("DOM TOWER · 时间线原型", 15, Color("#52627a"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(hint)


func quit_game() -> void:
	get_tree().quit()


func make_centered_menu(title_text: String, detail_text: String) -> VBoxContainer:
	clear_screen()
	make_background()
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-340, -260)
	center.size = Vector2(680, 520)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 24)
	add_child(center)
	var title := make_label(title_text, 44, Color("#f6f0df"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	var detail := make_label(detail_text, 22, Color("#b9c7db"))
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(detail)
	return center


func show_mode_select(selected_mode: String = "single") -> void:
	var center := make_centered_menu("选择游戏模式", "单人模式：一人轮流操作现代人与过去人\n角色模式：选择一名角色，另一名角色由 AI 操作")
	var single_text := "✓ 单人模式 · 操作两名角色" if selected_mode == "single" else "单人模式 · 操作两名角色"
	var single_button := make_button(single_text, Vector2(420, 64))
	single_button.pressed.connect(show_mode_select.bind("single"))
	center.add_child(single_button)
	var character_text := "✓ 角色模式 · 与 AI 合作" if selected_mode == "character" else "角色模式 · 与 AI 合作"
	var character_button := make_button(character_text, Vector2(420, 64))
	character_button.pressed.connect(show_mode_select.bind("character"))
	center.add_child(character_button)
	var continue_text := "下一步：选择角色" if selected_mode == "character" else "开始游戏"
	var continue_button := make_button(continue_text, Vector2(360, 64))
	continue_button.pressed.connect(proceed_from_mode.bind(selected_mode))
	center.add_child(continue_button)
	var back_button := make_button("返回首页", Vector2(260, 56))
	back_button.pressed.connect(show_home)
	center.add_child(back_button)


func proceed_from_mode(selected_mode: String) -> void:
	if selected_mode == "character":
		show_role_select()
	else:
		start_game("single", 0)


func show_role_select(selected_character: int = 0) -> void:
	var center := make_centered_menu("选择你的角色", "你操作选中的角色，另一名角色会由 AI 自动行动")
	var modern_text := "✓ 现代人" if selected_character == 0 else "现代人"
	var modern_button := make_button(modern_text, Vector2(360, 64))
	modern_button.pressed.connect(show_role_select.bind(0))
	center.add_child(modern_button)
	var past_text := "✓ 过去人" if selected_character == 1 else "过去人"
	var past_button := make_button(past_text, Vector2(360, 64))
	past_button.pressed.connect(show_role_select.bind(1))
	center.add_child(past_button)
	var start_button := make_button("开始游戏", Vector2(360, 64))
	start_button.pressed.connect(start_game.bind("character", selected_character))
	center.add_child(start_button)
	var back_button := make_button("返回模式选择", Vector2(280, 56))
	back_button.pressed.connect(show_mode_select)
	center.add_child(back_button)


func start_game(mode: String = "single", selected_character: int = 0) -> void:
	game_mode = mode
	player_character = selected_character
	ai_turn_in_progress = false
	game_over = false
	active_character = 0
	time_indices = [0, 0]
	occupied_locations = ["", ""]
	inventories = [[], []]
	selected_location = ""
	event_resolved = false
	tower_attempted_this_turn = false
	location_skill_used_this_turn = false
	items_gained_this_turn = 0
	items_lost_this_turn = 0
	prevent_time_advance = false
	event_item_effects_enabled = true
	archive_choice_made = false
	current_event_card = {}
	current_event_result = ""
	event_drawn_this_turn = false
	event_effect_resolved = false
	settlement_in_progress = false
	event_choice_pending = false
	mandatory_action_pending = false
	mandatory_action_source = ""
	deferred_event_pending = false
	travel_carry_blocked_once = false
	person_timelines = [0, 1]
	travel_cooldowns = [0, 0]
	empty_turn_in_progress = false
	event_decks = [MODERN_EVENT_CARDS.duplicate(true), PAST_EVENT_CARDS.duplicate(true)]
	event_decks[0].shuffle()
	event_decks[1].shuffle()
	build_game_screen()
	update_turn_ui()


func build_game_screen() -> void:
	clear_screen()
	make_background()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	margin.add_child(page)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	page.add_child(header)
	var brand := make_label("DOM TOWER", 28, Color("#f6f0df"))
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	var phase_badge := Label.new()
	phase_badge.text = "  时间线行动  "
	phase_badge.add_theme_font_size_override("font_size", 15)
	phase_badge.add_theme_color_override("font_color", Color("#f4b860"))
	phase_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(phase_badge)
	var exit_button := make_button("退出游戏", Vector2(120, 36))
	exit_button.add_theme_font_size_override("font_size", 16)
	exit_button.pressed.connect(show_home)
	header.add_child(exit_button)
	page.add_child(HSeparator.new())
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 16)
	page.add_child(status)
	for index in range(2):
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.custom_minimum_size.y = 108
		var timeline_style := make_panel_style(Color(CHARACTER_COLORS[index], 0.075), Color(CHARACTER_COLORS[index], 0.72), 14, 2)
		timeline_style.content_margin_left = 14
		timeline_style.content_margin_right = 14
		timeline_style.content_margin_top = 7
		timeline_style.content_margin_bottom = 7
		panel.add_theme_stylebox_override("panel", timeline_style)
		status.add_child(panel)
		character_panels.append(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 3)
		panel.add_child(box)
		box.add_child(make_label(TIMELINE_NAMES[index], 21, CHARACTER_COLORS[index]))
		var people_label := make_label("人员：%s" % CHARACTER_NAMES[index], 15, Color("#d8e1ee"))
		box.add_child(people_label)
		people_labels.append(people_label)
		var inventory_label := make_label("道具：暂无", 15, Color("#d8e1ee"))
		box.add_child(inventory_label)
		inventory_labels.append(inventory_label)
		var timeline := HBoxContainer.new()
		timeline.add_theme_constant_override("separation", 6)
		box.add_child(timeline)
		timeline_rows.append(timeline)
	var turn_panel := PanelContainer.new()
	var turn_style := make_panel_style(Color("#151f31"), Color("#344967"), 12, 1)
	turn_style.content_margin_top = 7
	turn_style.content_margin_bottom = 7
	turn_panel.add_theme_stylebox_override("panel", turn_style)
	page.add_child(turn_panel)
	var turn_box := VBoxContainer.new()
	turn_box.add_theme_constant_override("separation", 4)
	turn_panel.add_child(turn_box)
	turn_label = make_label("", 28, Color("#f6f0df"))
	turn_box.add_child(turn_label)
	instruction_label = make_label("", 17, Color("#b9c7db"))
	turn_box.add_child(instruction_label)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	page.add_child(grid)
	for location_index in range(LOCATIONS.size()):
		var location: String = LOCATIONS[location_index]
		var button := make_button(format_location_card_text(location), Vector2(0, 74))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		apply_location_card_style(button, location_index)
		button.pressed.connect(open_location_card.bind(location))
		grid.add_child(button)
		location_buttons[location] = button
	var action_panel := PanelContainer.new()
	var action_style := make_panel_style(Color("#111a2a"), Color("#2c3d57"), 12, 1)
	action_style.content_margin_top = 6
	action_style.content_margin_bottom = 6
	action_panel.add_theme_stylebox_override("panel", action_style)
	page.add_child(action_panel)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 14)
	action_panel.add_child(action_row)
	draw_button = make_button("请先选择地点", Vector2(250, 48))
	draw_button.add_theme_font_size_override("font_size", 18)
	draw_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	draw_button.disabled = true
	draw_button.pressed.connect(draw_event_card)
	action_row.add_child(draw_button)
	location_action_button = make_button("地点技能", Vector2(250, 48))
	location_action_button.add_theme_font_size_override("font_size", 18)
	location_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	location_action_button.visible = false
	location_action_button.pressed.connect(activate_location_skill)
	action_row.add_child(location_action_button)
	review_event_button = make_button("再次查看事件卡", Vector2(195, 48))
	review_event_button.add_theme_font_size_override("font_size", 18)
	review_event_button.visible = false
	review_event_button.pressed.connect(handle_event_secondary_action)
	action_row.add_child(review_event_button)
	end_turn_button = make_button("结束回合", Vector2(190, 48))
	end_turn_button.add_theme_font_size_override("font_size", 18)
	end_turn_button.disabled = true
	end_turn_button.pressed.connect(finish_turn)
	action_row.add_child(end_turn_button)
	build_location_overlay()
	build_event_overlay()
	build_item_choice_overlay()
	build_effect_feedback_layer()


func build_location_overlay() -> void:
	location_overlay = ColorRect.new()
	location_overlay.color = Color(0.01, 0.02, 0.04, 0.58)
	location_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	location_overlay.visible = false
	add_child(location_overlay)
	location_card_panel = PanelContainer.new()
	location_card_panel.set_anchors_preset(Control.PRESET_CENTER)
	location_card_panel.position = Vector2(-360, -250)
	location_card_panel.size = Vector2(720, 500)
	location_card_panel.pivot_offset = location_card_panel.size / 2.0
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#172337")
	card_style.border_color = Color("#d39b4a")
	card_style.set_border_width_all(4)
	card_style.set_corner_radius_all(18)
	card_style.shadow_color = Color(0, 0, 0, 0.65)
	card_style.shadow_size = 18
	card_style.content_margin_left = 38
	card_style.content_margin_right = 38
	card_style.content_margin_top = 22
	card_style.content_margin_bottom = 22
	location_card_panel.add_theme_stylebox_override("panel", card_style)
	location_overlay.add_child(location_card_panel)
	var card := VBoxContainer.new()
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_theme_constant_override("separation", 12)
	location_card_panel.add_child(card)
	var card_type := make_label("地 点 卡", 16, Color("#d39b4a"))
	card_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(card_type)
	card.add_child(HSeparator.new())
	location_title = make_label("", 36, Color("#f4b860"))
	location_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(location_title)
	location_effects_row = HBoxContainer.new()
	location_effects_row.add_theme_constant_override("separation", 14)
	location_effects_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(location_effects_row)
	location_modern_panel = make_location_effect_panel()
	location_effects_row.add_child(location_modern_panel)
	var modern_box := VBoxContainer.new()
	modern_box.add_theme_constant_override("separation", 8)
	location_modern_panel.add_child(modern_box)
	location_modern_title = make_label("现代组效果", 23, CHARACTER_COLORS[0])
	modern_box.add_child(location_modern_title)
	location_modern_body = make_label("持有「钥匙」：可以尝试敲钟。\n同时持有「铃铛」：立即获得胜利。", 18, Color("#d8e1ee"))
	location_modern_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modern_box.add_child(location_modern_body)
	location_past_panel = make_location_effect_panel()
	location_effects_row.add_child(location_past_panel)
	var past_box := VBoxContainer.new()
	past_box.add_theme_constant_override("separation", 8)
	location_past_panel.add_child(past_box)
	location_past_title = make_label("过去组效果", 23, CHARACTER_COLORS[1])
	past_box.add_child(location_past_title)
	location_past_body = make_label("持有「石头」×1 与「文件」×1：\n获得「铃铛」×1，材料不会消耗。", 18, Color("#d8e1ee"))
	location_past_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	past_box.add_child(location_past_body)
	location_body = make_label("", 20, Color("#d8e1ee"))
	location_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	location_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(location_body)
	location_timing_label = make_label("可在抽事件前，或事件后、回合结束前触发 · 每回合一次", 16, Color("#93a4bd"))
	location_timing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(location_timing_label)
	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 14)
	card.add_child(button_row)
	location_choose_button = make_button("选择此地点", Vector2(320, 64))
	location_choose_button.pressed.connect(confirm_location_choice)
	button_row.add_child(location_choose_button)
	var close_button := make_button("查看其他地点", Vector2(260, 64))
	close_button.pressed.connect(close_location_card)
	button_row.add_child(close_button)


func make_location_effect_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#101827")
	style.border_color = Color("#52627a")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	return panel


func make_panel_style(background: Color, border: Color, radius: int = 14, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func apply_location_card_style(button: Button, location_index: int) -> void:
	var accents := [Color("#d39b4a"), Color("#d47d6d"), Color("#55a9c9"), Color("#b48bd2"), Color("#83a86f"), Color("#cc8c55")]
	var accent: Color = accents[location_index]
	var normal := make_panel_style(Color("#172337"), Color(accent, 0.62), 14, 2)
	var hover := make_panel_style(Color(accent, 0.16), accent, 14, 3)
	hover.shadow_color = Color(0, 0, 0, 0.45)
	hover.shadow_size = 9
	var pressed := make_panel_style(Color(accent, 0.25), accent.darkened(0.08), 14, 3)
	var disabled := make_panel_style(Color("#111925"), Color("#334157"), 14, 1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color("#f6f0df"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#66758b"))
	button.add_theme_font_size_override("font_size", 18)


func format_location_card_text(location: String, state_text: String = "点击翻看地点卡") -> String:
	var number := LOCATIONS.find(location) + 1
	return "%02d  ·  %s\n%s" % [number, location, state_text]


func build_event_overlay() -> void:
	event_overlay = ColorRect.new()
	event_overlay.color = Color(0.02, 0.02, 0.07, 0.72)
	event_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	event_overlay.visible = false
	add_child(event_overlay)
	event_card_panel = PanelContainer.new()
	event_card_panel.set_anchors_preset(Control.PRESET_CENTER)
	event_card_panel.position = Vector2(-330, -245)
	event_card_panel.size = Vector2(660, 490)
	event_card_panel.pivot_offset = event_card_panel.size / 2.0
	var event_style := StyleBoxFlat.new()
	event_style.bg_color = Color("#211a35")
	event_style.border_color = Color("#a879d8")
	event_style.set_border_width_all(3)
	event_style.set_corner_radius_all(22)
	event_style.shadow_color = Color(0, 0, 0, 0.65)
	event_style.shadow_size = 22
	event_style.content_margin_left = 42
	event_style.content_margin_right = 42
	event_style.content_margin_top = 28
	event_style.content_margin_bottom = 28
	event_card_panel.add_theme_stylebox_override("panel", event_style)
	event_overlay.add_child(event_card_panel)
	var card := VBoxContainer.new()
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_theme_constant_override("separation", 18)
	event_card_panel.add_child(card)
	var card_type := make_label("事 件 档 案", 17, Color("#c7a6ea"))
	card_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(card_type)
	card.add_child(HSeparator.new())
	event_title = make_label("", 34, Color("#e5d4f6"))
	event_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(event_title)
	event_body = make_label("", 20, Color("#d8e1ee"))
	event_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(event_body)
	var continue_button := make_button("收起事件卡 · 返回行动", Vector2(360, 62))
	apply_button_style(continue_button, Color("#a879d8"), true)
	continue_button.pressed.connect(complete_event_review)
	card.add_child(continue_button)


func build_item_choice_overlay() -> void:
	item_choice_overlay = ColorRect.new()
	item_choice_overlay.color = Color(0.01, 0.02, 0.04, 0.72)
	item_choice_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	item_choice_overlay.visible = false
	add_child(item_choice_overlay)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-270, -260)
	panel.size = Vector2(540, 520)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#172337")
	style.border_color = CHARACTER_COLORS[0]
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 26
	style.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", style)
	item_choice_overlay.add_child(panel)
	item_choice_list = VBoxContainer.new()
	item_choice_list.alignment = BoxContainer.ALIGNMENT_CENTER
	item_choice_list.add_theme_constant_override("separation", 14)
	panel.add_child(item_choice_list)


func build_effect_feedback_layer() -> void:
	effect_feedback_layer = Control.new()
	effect_feedback_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_feedback_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(effect_feedback_layer)
	effect_feedback_list = VBoxContainer.new()
	effect_feedback_list.set_anchors_preset(Control.PRESET_CENTER_TOP)
	effect_feedback_list.position = Vector2(-240, 34)
	effect_feedback_list.size = Vector2(480, 0)
	effect_feedback_list.add_theme_constant_override("separation", 10)
	effect_feedback_layer.add_child(effect_feedback_list)


func show_effect_feedback(text: String, accent: Color, category: String = "效果") -> void:
	if not is_instance_valid(effect_feedback_list):
		return
	if category == "地点效果" and not selected_location.is_empty():
		animate_location_highlight(selected_location, accent)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 58)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#172337")
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 9
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var category_label := make_label(category, 16, accent)
	category_label.custom_minimum_size.x = 82
	row.add_child(category_label)
	var message := make_label(text, 20, Color("#f6f0df"))
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(message)
	effect_feedback_list.add_child(panel)
	panel.modulate = Color(1, 1, 1, 0)
	panel.position.x = 90
	panel.scale = Vector2(0.92, 0.92)
	panel.pivot_offset = Vector2(240, 29)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate", Color.WHITE, 0.22)
	tween.tween_property(panel, "position:x", 0.0, 0.32)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.28)
	tween.chain().tween_interval(2.4)
	tween.chain().set_parallel(true)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_property(panel, "position:x", -70.0, 0.3)
	tween.chain().tween_callback(panel.queue_free)


func animate_location_highlight(location: String, accent: Color) -> void:
	if not location_buttons.has(location):
		return
	var button: Button = location_buttons[location]
	button.pivot_offset = button.size / 2.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "modulate", accent.lightened(0.35), 0.45)
	tween.tween_property(button, "scale", Vector2(1.045, 1.045), 0.45)
	tween.chain().set_parallel(true)
	tween.tween_property(button, "modulate", Color.WHITE, 0.7)
	tween.tween_property(button, "scale", Vector2.ONE, 0.7)


func animate_inventory_highlight(timeline_index: int, accent: Color) -> void:
	if timeline_index >= inventory_labels.size():
		return
	var label := inventory_labels[timeline_index]
	label.pivot_offset = label.size / 2.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate", accent.lightened(0.25), 0.4)
	tween.tween_property(label, "scale", Vector2(1.12, 1.12), 0.4)
	tween.chain().set_parallel(true)
	tween.tween_property(label, "modulate", Color.WHITE, 0.85)
	tween.tween_property(label, "scale", Vector2.ONE, 0.85)


func animate_time_highlight(timeline_index: int) -> void:
	if timeline_index >= character_panels.size():
		return
	var panel := character_panels[timeline_index]
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(panel, "modulate", Color("#c7a6ea"), 0.45)
	tween.tween_interval(0.35)
	tween.tween_property(panel, "modulate", Color.WHITE, 0.7)
	tween.tween_callback(func() -> void:
		panel.modulate = Color.WHITE if timeline_index == active_character else Color(0.55, 0.6, 0.7, 0.7)
	)


func open_location_card(location: String) -> void:
	if is_ai_turn():
		return
	location_being_viewed = location
	location_title.text = location
	var has_group_effects := location in ["钟塔", "广场", "运河", "博物馆", "档案馆", "工坊"]
	location_effects_row.visible = has_group_effects
	location_timing_label.visible = has_group_effects
	location_body.visible = not has_group_effects
	location_body.text = LOCATION_DETAILS[location]
	if location == "钟塔":
		location_modern_body.text = "持有「钥匙」：可以触发一次响铃。\n响铃后检查钟塔、铃铛、人员与时间同步条件。"
		location_past_body.text = "持有「石头」×1 与「文件」×1：\n获得「铃铛」×1，材料不会消耗。"
		location_timing_label.text = "可在抽事件前，或事件后、回合结束前触发 · 每回合一次"
	elif location == "广场":
		location_modern_body.text = "选择丢弃任意 1 件物品，触发一次响铃。\n响铃后检查全部胜利条件。"
		location_past_body.text = "处理事件后，本回合未获得物品：\n可使本回合结束时过去时间不前进。"
		location_timing_label.text = "现代组可主动丢弃 · 过去组需在处理事件后判断 · 每回合一次"
	elif location == "运河":
		location_modern_body.text = "可以选择获得「石头」×1。\n若获得，过去组时间立即前进一格。"
		location_past_body.text = "处理事件后必须触发：\n有石头则失去 1 个；否则获得 1 个。"
		location_timing_label.text = "现代组可主动选择 · 过去组在处理事件后自动结算"
	elif location == "博物馆":
		location_modern_body.text = "处理事件后：获得「文件」×1。\n若文件达到 2 份，必须选择失去任意物品 ×1。"
		location_past_body.text = "处理事件后：\n若持有文件，必须失去「文件」×1；否则无事发生。"
		location_timing_label.text = "现代组与过去组均在处理事件后强制结算"
	elif location == "档案馆":
		location_modern_body.text = "抽事件前选择：文件 ×1 → 钥匙 ×1。\n若不交换，本次事件卡的物品效果全部无效。"
		location_past_body.text = "占据后强制触发：石头 ×1 → 文件 ×1。\n没有石头：过去时间立即额外 +1。"
		location_timing_label.text = "现代组必须在抽卡前决定 · 过去组占据后立即强制结算"
	elif location == "工坊":
		location_modern_body.text = "选择一人穿越到过去，可携带物品 ×1。\n若携带物品：现代时间立即额外 +1。"
		location_past_body.text = "选择一人穿越到现在，不能携带物品。\n穿越者下一轮不能再次穿越。"
		location_timing_label.text = "可在抽事件前，或事件后、回合结束前选择触发"
	if has_group_effects:
		set_location_effect_highlight(location_modern_panel, location_modern_title, location_modern_body, CHARACTER_COLORS[0], active_character == 0)
		set_location_effect_highlight(location_past_panel, location_past_title, location_past_body, CHARACTER_COLORS[1], active_character == 1)
	location_choose_button.text = "已选择此地点" if selected_location == location else "选择此地点"
	location_choose_button.disabled = selected_location == location or event_resolved
	location_overlay.visible = true
	if location_card_tween and location_card_tween.is_valid():
		location_card_tween.kill()
	location_card_panel.scale = Vector2(0.06, 1.0)
	location_card_panel.modulate = Color(1, 1, 1, 0.35)
	location_card_tween = create_tween().set_parallel(true)
	location_card_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	location_card_tween.tween_property(location_card_panel, "scale", Vector2.ONE, 0.38)
	location_card_tween.tween_property(location_card_panel, "modulate", Color.WHITE, 0.22)


func set_location_effect_highlight(panel: PanelContainer, title_label: Label, body_label: Label, accent: Color, highlighted: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent, 0.13) if highlighted else Color("#101827")
	style.border_color = accent if highlighted else Color("#52627a")
	style.set_border_width_all(3 if highlighted else 1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	title_label.add_theme_font_size_override("font_size", 25 if highlighted else 20)
	title_label.add_theme_color_override("font_color", accent if highlighted else Color("#8190a8"))
	body_label.add_theme_color_override("font_color", Color("#f6f0df") if highlighted else Color("#8190a8"))
	panel.modulate = Color.WHITE if highlighted else Color(0.78, 0.82, 0.88, 0.82)


func close_location_card() -> void:
	if location_card_tween and location_card_tween.is_valid():
		location_card_tween.kill()
	location_card_tween = create_tween().set_parallel(true)
	location_card_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	location_card_tween.tween_property(location_card_panel, "scale", Vector2(0.06, 1.0), 0.22)
	location_card_tween.tween_property(location_card_panel, "modulate", Color(1, 1, 1, 0), 0.18)
	location_card_tween.chain().tween_callback(func() -> void: location_overlay.visible = false)


func confirm_location_choice() -> void:
	location_overlay.visible = false
	select_location(location_being_viewed)


func select_location(location: String) -> void:
	selected_location = location
	occupied_locations[active_character] = location
	draw_button.disabled = false
	draw_button.text = "抽取事件卡（剩余 %d）" % event_decks[active_character].size()
	instruction_label.text = "已选择「%s」。现在抽取一张事件卡。" % location
	refresh_locations()
	refresh_turn_actions()
	if location == "运河" and active_character == 0:
		show_canal_modern_choice()
	elif location == "档案馆":
		if active_character == 0:
			draw_button.disabled = true
			draw_button.text = "请先决定档案馆效果"
			show_archive_modern_choice()
		else:
			activate_archive_past_effect()


func draw_event_card() -> void:
	if is_ai_turn():
		return
	show_event_card()


func show_event_card() -> void:
	if not event_drawn_this_turn:
		current_event_card = take_next_event_card(active_character)
		event_drawn_this_turn = true
		review_event_button.visible = true
	render_current_event_card()
	event_overlay.visible = true
	animate_event_card_open()


func render_current_event_card() -> void:
	if current_event_card.is_empty():
		event_title.text = "%s事件牌堆已空" % ("现在" if active_character == 0 else "过去")
		event_body.text = "这条时间线已经没有尚未抽取的事件卡。\n\n事件卡抽取后不会放回牌堆。"
	else:
		event_title.text = "%s · %s" % [current_event_card["card_number"], current_event_card["title"]]
		var result_text := current_event_result if event_effect_resolved else "关闭事件卡后开始结算"
		event_body.text = "%s\n\n效果：%s\n\n%s" % [current_event_card["description"], current_event_card["effect_text"], result_text]


func reopen_current_event_card() -> void:
	if not event_drawn_this_turn:
		return
	render_current_event_card()
	event_overlay.visible = true
	animate_event_card_open()


func handle_event_secondary_action() -> void:
	if deferred_event_pending:
		resolve_modern_03_effect()
	else:
		reopen_current_event_card()


func animate_event_card_open() -> void:
	if event_card_tween and event_card_tween.is_valid():
		event_card_tween.kill()
	event_card_panel.scale = Vector2(0.82, 0.82)
	event_card_panel.rotation_degrees = -4.0
	event_card_panel.modulate = Color(1, 1, 1, 0)
	event_card_tween = create_tween().set_parallel(true)
	event_card_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	event_card_tween.tween_property(event_card_panel, "scale", Vector2.ONE, 0.42)
	event_card_tween.tween_property(event_card_panel, "rotation_degrees", 0.0, 0.38)
	event_card_tween.tween_property(event_card_panel, "modulate", Color.WHITE, 0.22)


func take_next_event_card(timeline_index: int) -> Dictionary:
	if event_decks[timeline_index].is_empty():
		return {}
	return event_decks[timeline_index].pop_front()


func resolve_event_card(card: Dictionary, timeline_index: int) -> String:
	match card.get("id", ""):
		"modern_01":
			if inventories[timeline_index].count("文件") >= 2:
				var lost_amount := lose_event_item(timeline_index, "文件")
				if lost_amount > 0:
					return "事件结算：现代时间线失去了「文件」×1。"
				return "事件结算：物品效果被档案馆屏蔽，没有失去文件。"
			gain_event_item(timeline_index, "钥匙")
			if event_item_effects_enabled:
				return "事件结算：文件不足 2 份，现代时间线获得了「钥匙」×1。"
			return "事件结算：物品效果被档案馆屏蔽，没有获得钥匙。"
		"modern_02":
			if not inventories[0].has("铃铛"):
				return "事件结算：现代时间线没有铃铛，无法进行响铃测试。"
			if is_ai_turn():
				advance_time(0, 1, "系统测试")
				var ai_success := check_ringing_success("事件卡《系统测试》")
				return "事件结算：AI 触发了系统测试响铃%s。" % ("并成功连接时间线" if ai_success else "，但胜利条件不足")
			event_choice_pending = true
			show_system_test_choice()
			return "等待选择是否触发系统测试响铃。"
		"modern_03":
			if not event_item_effects_enabled:
				return "事件结算：物品效果被档案馆屏蔽，没有获得或丢弃物品。"
			if is_ai_turn():
				return resolve_modern_03_effect()
			event_choice_pending = true
			show_modern_03_timing_choice()
			return "等待选择在地点效果前或后结算。"
		"past_01":
			var gained_item := "铃铛" if selected_location == "钟塔" else "石头"
			gain_event_item(timeline_index, gained_item)
			if event_item_effects_enabled:
				return "事件结算：%s时间线获得了「%s」×1。" % ["过去" if timeline_index == 1 else "现在", gained_item]
			return "事件结算：物品效果被档案馆屏蔽，没有获得物品。"
		"past_02":
			if inventories[timeline_index].count("石头") >= 2:
				var lost_amount := lose_event_item(timeline_index, "石头")
				if lost_amount > 0:
					return "事件结算：过去时间线失去了「石头」×1。"
				return "事件结算：物品效果无效，没有失去石头。"
			gain_event_item(timeline_index, "石头")
			if event_item_effects_enabled:
				return "事件结算：石头不足 2 个，过去时间线获得了「石头」×1。"
			return "事件结算：物品效果无效，没有获得石头。"
		"past_03":
			gain_event_item(timeline_index, "石头")
			travel_carry_blocked_once = true
			show_effect_feedback("下一次穿越禁止携带物品", Color("#a879d8"), "穿越限制")
			return "事件结算：过去时间线获得了「石头」×1；下一次实际穿越不能携带物品。"
	return "事件效果已结算。"


func show_system_test_choice() -> void:
	for child in item_choice_list.get_children():
		child.queue_free()
	var title := make_label("启动系统测试？", 31, Color("#a879d8"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(title)
	var detail := make_label("触发前，现代时间会先前进一格；随后立即检查全部响铃胜利条件。", 19, Color("#d8e1ee"))
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_choice_list.add_child(detail)
	var trigger_button := make_button("时间 +1，并触发响铃", Vector2(380, 58))
	apply_button_style(trigger_button, Color("#a879d8"), true)
	trigger_button.pressed.connect(trigger_system_test_bell)
	item_choice_list.add_child(trigger_button)
	var skip_button := make_button("不触发", Vector2(280, 54))
	skip_button.pressed.connect(skip_system_test_bell)
	item_choice_list.add_child(skip_button)
	item_choice_overlay.visible = true


func trigger_system_test_bell() -> void:
	if not event_choice_pending:
		return
	event_choice_pending = false
	item_choice_overlay.visible = false
	advance_time(0, 1, "系统测试")
	var success := check_ringing_success("事件卡《系统测试》")
	current_event_result = "事件结算：现代时间前进一格，并触发了响铃%s。" % ("，成功连接时间线" if success else "，但胜利条件不足")


func skip_system_test_bell() -> void:
	if not event_choice_pending:
		return
	event_choice_pending = false
	item_choice_overlay.visible = false
	current_event_result = "事件结算：你选择不触发系统测试响铃。"
	instruction_label.text = "你选择不触发《系统测试》的响铃，事件结算继续。"


func show_modern_03_timing_choice() -> void:
	for child in item_choice_list.get_children():
		child.queue_free()
	var title := make_label("何时核对物资？", 31, Color("#a879d8"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(title)
	var detail := make_label("物品是否一致会在真正结算的瞬间判断。你可以先发动地点效果，再回来结算。", 19, Color("#d8e1ee"))
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_choice_list.add_child(detail)
	var now_button := make_button("现在结算", Vector2(340, 56))
	now_button.pressed.connect(resolve_modern_03_now)
	item_choice_list.add_child(now_button)
	var later_button := make_button("延后 · 先处理地点效果", Vector2(360, 56))
	later_button.pressed.connect(defer_modern_03_effect)
	item_choice_list.add_child(later_button)
	item_choice_overlay.visible = true


func resolve_modern_03_now() -> void:
	if not event_choice_pending:
		return
	event_choice_pending = false
	item_choice_overlay.visible = false
	current_event_result = resolve_modern_03_effect()


func defer_modern_03_effect() -> void:
	if not event_choice_pending:
		return
	event_choice_pending = false
	deferred_event_pending = true
	item_choice_overlay.visible = false
	current_event_result = "事件效果已延后：必须在结束回合前完成结算。"
	review_event_button.text = "结算事件效果"
	instruction_label.text = "《误以为已经完成》已延后。你可以先使用地点技能，再结算事件效果。"


func inventory_contents_match() -> bool:
	var modern_counts: Dictionary = {}
	var past_counts: Dictionary = {}
	for item in inventories[0]:
		modern_counts[item] = modern_counts.get(item, 0) + 1
	for item in inventories[1]:
		past_counts[item] = past_counts.get(item, 0) + 1
	return modern_counts == past_counts


func resolve_modern_03_effect() -> String:
	deferred_event_pending = false
	review_event_button.text = "再次查看事件卡"
	if inventory_contents_match():
		gain_event_item(0, "文件")
		var result := "事件结算：两条时间线的物品完全一致，现代时间线获得了「文件」×1。"
		current_event_result = result
		instruction_label.text = result
		end_turn_button.disabled = settlement_in_progress
		return result
	if inventories[0].is_empty():
		var empty_result := "事件结算：两条时间线物品不同，但现代时间线没有物品可以丢弃。"
		current_event_result = empty_result
		instruction_label.text = empty_result
		end_turn_button.disabled = settlement_in_progress
		return empty_result
	if is_ai_turn():
		var ai_item := choose_ai_discard_item(0)
		lose_event_item(0, ai_item)
		var ai_result := "事件结算：物品清单不同，AI 丢弃了「%s」×1。" % ai_item
		current_event_result = ai_result
		return ai_result
	mandatory_action_pending = true
	mandatory_action_source = "modern_03"
	review_event_button.disabled = true
	end_turn_button.disabled = true
	show_modern_03_discard_choices()
	var pending_result := "事件结算：两条时间线物品不同，现代组必须丢弃一件物品。"
	current_event_result = pending_result
	return pending_result


func show_modern_03_discard_choices() -> void:
	for child in item_choice_list.get_children():
		child.queue_free()
	var title := make_label("物资清单不一致", 31, Color("#ef6f6c"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(title)
	var detail := make_label("现代组必须选择并丢弃一件物品，不能跳过。", 19, Color("#d8e1ee"))
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(detail)
	var unique_items: Array = []
	for item in inventories[0]:
		if not unique_items.has(item):
			unique_items.append(item)
	for item in unique_items:
		var item_button := make_button("丢弃 %s ×1" % item, Vector2(350, 54))
		item_button.pressed.connect(discard_item_for_modern_03.bind(item))
		item_choice_list.add_child(item_button)
	item_choice_overlay.visible = true


func discard_item_for_modern_03(item: String) -> void:
	if not mandatory_action_pending or not inventories[0].has(item):
		return
	lose_event_item(0, item)
	mandatory_action_pending = false
	mandatory_action_source = ""
	item_choice_overlay.visible = false
	review_event_button.disabled = false
	current_event_result = "事件结算：物品清单不同，现代时间线丢弃了「%s」×1。" % item
	instruction_label.text = current_event_result
	end_turn_button.disabled = settlement_in_progress


func complete_event_review() -> void:
	event_overlay.visible = false
	if event_effect_resolved:
		return
	settlement_in_progress = true
	review_event_button.disabled = true
	end_turn_button.disabled = true
	refresh_turn_actions()
	draw_button.disabled = true
	draw_button.text = "正在结算事件……"
	instruction_label.text = "正在结算事件卡，请查看道具栏变化……"
	await get_tree().create_timer(0.45).timeout
	if not current_event_card.is_empty():
		current_event_result = resolve_event_card(current_event_card, active_character)
	while event_choice_pending:
		await get_tree().create_timer(0.15).timeout
	while item_choice_overlay.visible and not game_over:
		await get_tree().create_timer(0.15).timeout
	if game_over:
		return
	event_effect_resolved = true
	event_resolved = true
	await get_tree().create_timer(1.35).timeout
	instruction_label.text = "事件效果已结算，正在检查地点效果……"
	resolve_mandatory_location_effects()
	await get_tree().create_timer(1.35).timeout
	settlement_in_progress = false
	review_event_button.disabled = false
	draw_button.text = "事件卡已处理"
	if not mandatory_action_pending and not deferred_event_pending and not item_choice_overlay.visible:
		end_turn_button.disabled = false
		instruction_label.text = "本轮结算完成。你可以再次查看事件卡、使用地点技能，或结束回合。"
	refresh_turn_actions()


func refresh_turn_actions() -> void:
	if not is_instance_valid(location_action_button):
		return
	location_action_button.visible = selected_location in ["钟塔", "广场", "运河", "博物馆", "档案馆", "工坊"]
	if settlement_in_progress:
		location_action_button.disabled = true
		location_action_button.text = "正在结算……"
		return
	if selected_location == "钟塔":
		if active_character == 0:
			var has_key := inventories[0].has("钥匙")
			location_action_button.disabled = not has_key or tower_attempted_this_turn
			if tower_attempted_this_turn:
				location_action_button.text = "本回合已经使用钟塔技能"
			elif has_key:
				location_action_button.text = "使用钥匙 · 尝试敲钟"
			else:
				location_action_button.text = "需要钥匙才能敲钟"
		else:
			var has_materials := inventories[1].count("石头") >= 1 and inventories[1].count("文件") >= 1
			location_action_button.disabled = not has_materials or tower_attempted_this_turn
			if tower_attempted_this_turn:
				location_action_button.text = "本回合已经使用钟塔技能"
			elif has_materials:
				location_action_button.text = "用石头与文件获得铃铛"
			else:
				location_action_button.text = "需要石头 ×1 与文件 ×1"
	elif selected_location == "广场":
		if active_character == 0:
			var can_trigger_bell := items_lost_this_turn > 0 or not inventories[0].is_empty()
			location_action_button.disabled = not can_trigger_bell or location_skill_used_this_turn
			if location_skill_used_this_turn:
				location_action_button.text = "本回合已经触发铃声"
			elif items_lost_this_turn > 0:
				location_action_button.text = "触发一次铃声"
			elif not inventories[0].is_empty():
				location_action_button.text = "选择丢弃一件物品"
			else:
				location_action_button.text = "本回合尚未失去物品"
		else:
			var can_pause_time := event_resolved and items_gained_this_turn == 0
			location_action_button.disabled = not can_pause_time or location_skill_used_this_turn
			if location_skill_used_this_turn:
				location_action_button.text = "过去时间将在本轮暂停"
			elif not event_resolved:
				location_action_button.text = "处理事件后才能判断"
			elif items_gained_this_turn > 0:
				location_action_button.text = "本回合获得过物品"
			else:
				location_action_button.text = "使过去时间不前进"
	elif selected_location == "运河":
		if active_character == 0:
			location_action_button.disabled = location_skill_used_this_turn
			location_action_button.text = "已经获得石头" if location_skill_used_this_turn else "获得石头 ×1（过去时间 +1）"
		else:
			location_action_button.disabled = true
			location_action_button.text = "运河效果已自动结算" if location_skill_used_this_turn else "处理事件后自动结算"
	elif selected_location == "博物馆":
		location_action_button.disabled = true
		location_action_button.text = "博物馆效果已结算" if location_skill_used_this_turn else "处理事件后自动结算"
	elif selected_location == "档案馆":
		location_action_button.disabled = true
		if active_character == 0:
			location_action_button.text = "抽卡前选择已完成" if archive_choice_made else "请先完成抽卡前选择"
		else:
			location_action_button.text = "档案馆效果已结算"
	elif selected_location == "工坊":
		var eligible_people := get_people_on_timeline(active_character).filter(func(person_index: int) -> bool:
			return travel_cooldowns[person_index] == 0
		)
		location_action_button.disabled = location_skill_used_this_turn or eligible_people.is_empty()
		if location_skill_used_this_turn:
			location_action_button.text = "本回合已经穿越"
		elif eligible_people.is_empty():
			location_action_button.text = "本轮无人可以穿越"
		else:
			var carry_warning := " · 禁止携带" if travel_carry_blocked_once else ""
			location_action_button.text = "穿越到%s%s" % ["过去" if active_character == 0 else "现在", carry_warning]


func activate_location_skill() -> void:
	if selected_location == "钟塔":
		activate_tower_skill()
	elif selected_location == "广场":
		activate_plaza_skill()
	elif selected_location == "运河":
		activate_canal_skill()
	elif selected_location == "工坊":
		show_workshop_traveler_choice()


func activate_tower_skill() -> void:
	if selected_location != "钟塔" or tower_attempted_this_turn:
		return
	if active_character == 0:
		if not inventories[0].has("钥匙"):
			return
		show_effect_feedback("现代组发动钟塔技能", Color("#d39b4a"), "地点效果")
		tower_attempted_this_turn = true
		check_ringing_success("钟塔")
	else:
		if inventories[1].count("石头") < 1 or inventories[1].count("文件") < 1:
			return
		show_effect_feedback("过去组发动钟塔技能", Color("#d39b4a"), "地点效果")
		tower_attempted_this_turn = true
		gain_item(1, "铃铛")
		instruction_label.text = "过去人利用石头与文件，获得了「铃铛」×1。"
	refresh_turn_actions()


func activate_plaza_skill() -> void:
	if selected_location != "广场" or location_skill_used_this_turn:
		return
	if active_character == 0:
		if items_lost_this_turn > 0:
			resolve_modern_plaza_bell()
		else:
			show_plaza_discard_choices()
	elif event_resolved and items_gained_this_turn == 0:
		show_effect_feedback("过去组发动广场技能", Color("#d39b4a"), "地点效果")
		location_skill_used_this_turn = true
		prevent_time_advance = true
		show_effect_feedback("过去时间本轮暂停", Color("#a879d8"), "时间")
		instruction_label.text = "过去组发动广场技能：本回合结束时，过去时间不会前进。"
		refresh_turn_actions()


func resolve_mandatory_location_effects() -> void:
	if selected_location == "运河" and active_character == 1 and not location_skill_used_this_turn:
		activate_canal_skill()
	elif selected_location == "博物馆" and not location_skill_used_this_turn:
		activate_museum_skill()


func activate_canal_skill() -> void:
	if selected_location != "运河" or location_skill_used_this_turn:
		return
	if active_character == 0:
		show_effect_feedback("现代组发动运河效果", Color("#d39b4a"), "地点效果")
		location_skill_used_this_turn = true
		gain_item(0, "石头")
		var previous_time: int = time_indices[1]
		advance_time(1, 1, "运河效果")
		var previous_time_text: String = TIMES[previous_time] if previous_time < TIMES.size() else "时间线末端"
		var new_time_text: String = TIMES[time_indices[1]] if time_indices[1] < TIMES.size() else "时间线末端"
		instruction_label.text = "现代人获得「石头」×1；过去时间：%s → %s。" % [previous_time_text, new_time_text]
	elif event_resolved:
		show_effect_feedback("过去组强制结算运河", Color("#d39b4a"), "地点效果")
		location_skill_used_this_turn = true
		if inventories[1].has("石头"):
			lose_item(1, "石头")
			instruction_label.text = "运河效果：过去人失去了「石头」×1。"
		else:
			gain_item(1, "石头")
			instruction_label.text = "运河效果：过去人没有石头，获得了「石头」×1。"
	refresh_turn_actions()


func show_canal_modern_choice() -> void:
	for child in item_choice_list.get_children():
		child.queue_free()
	var title := make_label("发动运河效果？", 32, CHARACTER_COLORS[0])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(title)
	var detail := make_label("获得「石头」×1，同时让过去组时间立即前进一格。", 20, Color("#d8e1ee"))
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_choice_list.add_child(detail)
	var confirm_button := make_button("获得石头，并推进过去时间", Vector2(400, 58))
	confirm_button.pressed.connect(confirm_canal_modern_choice)
	item_choice_list.add_child(confirm_button)
	var later_button := make_button("暂不发动，稍后再决定", Vector2(360, 54))
	later_button.pressed.connect(defer_canal_modern_choice)
	item_choice_list.add_child(later_button)
	item_choice_overlay.visible = true


func confirm_canal_modern_choice() -> void:
	item_choice_overlay.visible = false
	activate_canal_skill()


func defer_canal_modern_choice() -> void:
	item_choice_overlay.visible = false
	instruction_label.text = "已占据运河。你仍可在回合结束前点击地点技能，获得石头并推进过去时间。"


func activate_museum_skill() -> void:
	if selected_location != "博物馆" or not event_resolved or location_skill_used_this_turn:
		return
	location_skill_used_this_turn = true
	show_effect_feedback("%s强制结算博物馆" % ("现代组" if active_character == 0 else "过去组"), Color("#d39b4a"), "地点效果")
	if active_character == 0:
		gain_item(0, "文件")
		if inventories[0].count("文件") >= 2:
			if is_ai_turn():
				var item_to_lose: String = choose_ai_discard_item(0)
				lose_item(0, item_to_lose)
				instruction_label.text = "博物馆效果：AI 获得文件后失去了「%s」×1。" % item_to_lose
			else:
				mandatory_action_pending = true
				mandatory_action_source = "museum"
				end_turn_button.disabled = true
				instruction_label.text = "博物馆效果：获得了「文件」×1。现在必须选择失去一件物品。"
				show_museum_discard_choices()
		else:
			instruction_label.text = "博物馆效果：现代人获得了「文件」×1。"
	else:
		if inventories[1].has("文件"):
			lose_item(1, "文件")
			instruction_label.text = "博物馆效果：过去人失去了「文件」×1。"
		else:
			instruction_label.text = "博物馆效果：过去人没有文件，无事发生。"
	refresh_turn_actions()


func choose_ai_discard_item(character_index: int) -> String:
	for item in inventories[character_index]:
		if item != "铃铛":
			return item
	return inventories[character_index][0]


func show_museum_discard_choices() -> void:
	for child in item_choice_list.get_children():
		child.queue_free()
	var title := make_label("必须失去一件物品", 32, CHARACTER_COLORS[0])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(title)
	var detail := make_label("文件数量已达到 2 份，请选择要失去的物品。", 19, Color("#d8e1ee"))
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(detail)
	var unique_items: Array = []
	for item in inventories[0]:
		if not unique_items.has(item):
			unique_items.append(item)
	for item in unique_items:
		var item_button := make_button("失去 %s ×1" % item, Vector2(360, 54))
		item_button.pressed.connect(discard_item_for_museum.bind(item))
		item_choice_list.add_child(item_button)
	item_choice_overlay.visible = true


func discard_item_for_museum(item: String) -> void:
	if not inventories[0].has(item):
		return
	lose_item(0, item)
	mandatory_action_pending = false
	mandatory_action_source = ""
	item_choice_overlay.visible = false
	end_turn_button.disabled = settlement_in_progress
	instruction_label.text = "博物馆效果结算完成：现代人失去了「%s」×1。" % item


func show_archive_modern_choice() -> void:
	for child in item_choice_list.get_children():
		child.queue_free()
	var title := make_label("抽卡前决定", 32, CHARACTER_COLORS[0])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(title)
	var detail := make_label("交换可保留事件卡的全部效果；不交换则本次事件卡的物品效果无效。", 19, Color("#d8e1ee"))
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_choice_list.add_child(detail)
	var exchange_button := make_button("文件 ×1 → 钥匙 ×1", Vector2(380, 58))
	exchange_button.disabled = not inventories[0].has("文件")
	exchange_button.pressed.connect(exchange_archive_file_for_key)
	item_choice_list.add_child(exchange_button)
	if exchange_button.disabled:
		var no_file_hint := make_label("当前没有文件，无法交换", 17, Color("#f4b860"))
		no_file_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_choice_list.add_child(no_file_hint)
	var skip_button := make_button("不交换 · 屏蔽物品效果", Vector2(380, 58))
	skip_button.pressed.connect(skip_archive_exchange)
	item_choice_list.add_child(skip_button)
	item_choice_overlay.visible = true


func exchange_archive_file_for_key() -> void:
	if not inventories[0].has("文件") or archive_choice_made:
		return
	show_effect_feedback("现代组发动档案馆交换", Color("#d39b4a"), "地点效果")
	lose_item(0, "文件")
	gain_item(0, "钥匙")
	archive_choice_made = true
	event_item_effects_enabled = true
	item_choice_overlay.visible = false
	draw_button.disabled = false
	draw_button.text = "抽取事件卡（剩余 %d）" % event_decks[active_character].size()
	instruction_label.text = "档案馆交换完成：失去「文件」×1，获得「钥匙」×1。现在可以抽事件卡。"
	refresh_turn_actions()


func skip_archive_exchange() -> void:
	if archive_choice_made:
		return
	show_effect_feedback("档案馆屏蔽物品效果", Color("#d39b4a"), "地点效果")
	archive_choice_made = true
	event_item_effects_enabled = false
	item_choice_overlay.visible = false
	draw_button.disabled = false
	draw_button.text = "抽取事件卡（剩余 %d · 物品效果无效）" % event_decks[active_character].size()
	instruction_label.text = "你没有进行交换：本次事件卡的物品效果将无效。"
	refresh_turn_actions()


func activate_archive_past_effect() -> void:
	if selected_location != "档案馆" or location_skill_used_this_turn:
		return
	location_skill_used_this_turn = true
	show_effect_feedback("过去组强制结算档案馆", Color("#d39b4a"), "地点效果")
	if inventories[1].has("石头"):
		lose_item(1, "石头")
		gain_item(1, "文件")
		instruction_label.text = "档案馆效果：过去人用「石头」×1换得「文件」×1。"
	else:
		var previous_time: int = time_indices[1]
		advance_time(1, 1, "档案馆效果")
		var previous_text: String = TIMES[previous_time] if previous_time < TIMES.size() else "时间线末端"
		var new_text: String = TIMES[time_indices[1]] if time_indices[1] < TIMES.size() else "时间线末端"
		instruction_label.text = "档案馆无法交换：过去时间 %s → %s。" % [previous_text, new_text]
	refresh_turn_actions()


func gain_event_item(character_index: int, item: String, amount: int = 1) -> void:
	if event_item_effects_enabled:
		gain_item(character_index, item, amount)


func lose_event_item(character_index: int, item: String, amount: int = 1) -> int:
	return lose_item(character_index, item, amount) if event_item_effects_enabled else 0


func get_people_on_timeline(timeline_index: int) -> Array[int]:
	var people: Array[int] = []
	for person_index in range(person_timelines.size()):
		if person_timelines[person_index] == timeline_index:
			people.append(person_index)
	return people


func refresh_people_labels() -> void:
	for timeline_index in range(people_labels.size()):
		var people := get_people_on_timeline(timeline_index)
		if people.is_empty():
			people_labels[timeline_index].text = "人员：无人"
			people_labels[timeline_index].add_theme_color_override("font_color", Color("#ef6f6c"))
			continue
		var names: PackedStringArray = []
		for person_index in people:
			var suffix := "（下轮不能穿越）" if travel_cooldowns[person_index] > 0 else ""
			names.append("%s%s" % [CHARACTER_NAMES[person_index], suffix])
		people_labels[timeline_index].text = "人员：%s" % "、".join(names)
		people_labels[timeline_index].add_theme_color_override("font_color", Color("#d8e1ee"))


func show_workshop_traveler_choice() -> void:
	if selected_location != "工坊" or location_skill_used_this_turn:
		return
	for child in item_choice_list.get_children():
		child.queue_free()
	var destination_name := "过去" if active_character == 0 else "现在"
	var title := make_label("选择穿越者", 32, CHARACTER_COLORS[active_character])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(title)
	var detail := make_label("选择一人穿越到%s时间线。" % destination_name, 19, Color("#d8e1ee"))
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(detail)
	for person_index in get_people_on_timeline(active_character):
		var person_button := make_button(CHARACTER_NAMES[person_index], Vector2(340, 56))
		person_button.disabled = travel_cooldowns[person_index] > 0
		if active_character == 0:
			person_button.pressed.connect(show_workshop_item_choice.bind(person_index))
		else:
			person_button.pressed.connect(complete_workshop_travel.bind(person_index, ""))
		item_choice_list.add_child(person_button)
	var cancel_button := make_button("取消", Vector2(240, 50))
	cancel_button.pressed.connect(func() -> void: item_choice_overlay.visible = false)
	item_choice_list.add_child(cancel_button)
	item_choice_overlay.visible = true


func show_workshop_item_choice(person_index: int) -> void:
	for child in item_choice_list.get_children():
		child.queue_free()
	var title := make_label("携带一件物品？", 32, CHARACTER_COLORS[0])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(title)
	var warning_text := "《误差》生效：本次穿越禁止携带任何物品。" if travel_carry_blocked_once else "携带物品会让现代时间立即额外前进一格。"
	var warning := make_label(warning_text, 18, Color("#ef6f6c") if travel_carry_blocked_once else Color("#f4b860"))
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(warning)
	var no_item_button := make_button("不携带物品", Vector2(340, 54))
	no_item_button.pressed.connect(complete_workshop_travel.bind(person_index, ""))
	item_choice_list.add_child(no_item_button)
	if not travel_carry_blocked_once:
		var unique_items: Array = []
		for item in inventories[0]:
			if not unique_items.has(item):
				unique_items.append(item)
		for item in unique_items:
			var item_button := make_button("携带 %s ×1" % item, Vector2(340, 54))
			item_button.pressed.connect(complete_workshop_travel.bind(person_index, item))
			item_choice_list.add_child(item_button)
	item_choice_overlay.visible = true


func complete_workshop_travel(person_index: int, carried_item: String) -> void:
	if location_skill_used_this_turn or person_timelines[person_index] != active_character or travel_cooldowns[person_index] > 0:
		return
	if travel_carry_blocked_once and not carried_item.is_empty():
		show_effect_feedback("本次穿越禁止携带物品", Color("#ef6f6c"), "穿越限制")
		return
	show_effect_feedback("%s发动工坊穿越" % ("现代组" if active_character == 0 else "过去组"), Color("#d39b4a"), "地点效果")
	var source_timeline := active_character
	var target_timeline := 1 - source_timeline
	if source_timeline == 0 and not carried_item.is_empty():
		if not inventories[0].has(carried_item):
			return
		lose_item(0, carried_item)
		gain_item(1, carried_item)
		advance_time(0, 1, "携带物品穿越")
	elif source_timeline == 1:
		travel_cooldowns[person_index] = 1
	person_timelines[person_index] = target_timeline
	if travel_carry_blocked_once:
		travel_carry_blocked_once = false
		show_effect_feedback("禁带效果已消耗，下次穿越恢复正常", Color("#a879d8"), "穿越限制")
	location_skill_used_this_turn = true
	item_choice_overlay.visible = false
	refresh_people_labels()
	refresh_timelines()
	var item_message := "，并携带「%s」×1" % carried_item if not carried_item.is_empty() else ""
	var time_message := "；现代时间额外前进一格" if source_timeline == 0 and not carried_item.is_empty() else ""
	instruction_label.text = "%s穿越到%s时间线%s%s。" % [CHARACTER_NAMES[person_index], "过去" if target_timeline == 1 else "现在", item_message, time_message]
	refresh_turn_actions()


func show_plaza_discard_choices() -> void:
	if inventories[0].is_empty():
		return
	for child in item_choice_list.get_children():
		child.queue_free()
	var title := make_label("选择要丢弃的物品", 32, CHARACTER_COLORS[0])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(title)
	var detail := make_label("丢弃后将触发一次铃声。若仍持有铃铛，则获得胜利。", 18, Color("#b9c7db"))
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_choice_list.add_child(detail)
	var unique_items: Array = []
	for item in inventories[0]:
		if not unique_items.has(item):
			unique_items.append(item)
	for item in unique_items:
		var item_button := make_button("丢弃 %s ×1" % item, Vector2(360, 54))
		item_button.pressed.connect(discard_item_for_plaza.bind(item))
		item_choice_list.add_child(item_button)
	var cancel_button := make_button("取消", Vector2(240, 50))
	cancel_button.pressed.connect(func() -> void: item_choice_overlay.visible = false)
	item_choice_list.add_child(cancel_button)
	item_choice_overlay.visible = true


func discard_item_for_plaza(item: String) -> void:
	if not inventories[0].has(item) or location_skill_used_this_turn:
		return
	lose_item(0, item)
	item_choice_overlay.visible = false
	resolve_modern_plaza_bell(item)


func resolve_modern_plaza_bell(discarded_item: String = "") -> void:
	show_effect_feedback("现代组发动广场技能", Color("#d39b4a"), "地点效果")
	location_skill_used_this_turn = true
	instruction_label.text = ("现代人丢弃了「%s」并触发铃声。" % discarded_item) if not discarded_item.is_empty() else "现代人触发了广场铃声。"
	check_ringing_success("广场")
	refresh_turn_actions()


func gain_item(character_index: int, item: String, amount: int = 1) -> void:
	for count in range(amount):
		inventories[character_index].append(item)
	if character_index == active_character:
		items_gained_this_turn += amount
	refresh_inventory_labels()
	animate_inventory_highlight(character_index, Color("#58d68d"))
	show_effect_feedback("%s时间线获得 %s ×%d" % ["现在" if character_index == 0 else "过去", item, amount], Color("#58d68d"), "获得物品")


func lose_item(character_index: int, item: String, amount: int = 1) -> int:
	var lost_count := 0
	for count in range(amount):
		if not inventories[character_index].has(item):
			break
		inventories[character_index].erase(item)
		lost_count += 1
	if character_index == active_character:
		items_lost_this_turn += lost_count
	refresh_inventory_labels()
	if lost_count > 0:
		animate_inventory_highlight(character_index, Color("#ef6f6c"))
		show_effect_feedback("%s时间线失去 %s ×%d" % ["现在" if character_index == 0 else "过去", item, lost_count], Color("#ef6f6c"), "失去物品")
	return lost_count


func advance_time(timeline_index: int, amount: int = 1, reason: String = "") -> void:
	var old_index: int = time_indices[timeline_index]
	var new_index := mini(old_index + amount, TIMES.size())
	time_indices[timeline_index] = new_index
	if is_instance_valid(turn_label):
		refresh_timelines()
	if new_index == old_index:
		return
	animate_time_highlight(timeline_index)
	var old_text: String = TIMES[old_index] if old_index < TIMES.size() else "时间线末端"
	var new_text: String = TIMES[new_index] if new_index < TIMES.size() else "时间线末端"
	var reason_text := " · %s" % reason if not reason.is_empty() else ""
	show_effect_feedback("%s：%s → %s%s" % [TIMELINE_NAMES[timeline_index], old_text, new_text, reason_text], Color("#a879d8"), "时间推进")


func refresh_inventory_labels() -> void:
	for character_index in range(inventory_labels.size()):
		var item_counts: Dictionary = {}
		for item in inventories[character_index]:
			item_counts[item] = item_counts.get(item, 0) + 1
		if item_counts.is_empty():
			inventory_labels[character_index].text = "道具：暂无"
			continue
		var item_parts: PackedStringArray = []
		for item in item_counts:
			item_parts.append("%s ×%d" % [item, item_counts[item]])
		inventory_labels[character_index].text = "道具：%s" % "　".join(item_parts)


func finish_turn() -> void:
	if mandatory_action_pending:
		end_turn_button.disabled = true
		instruction_label.text = "还有必须完成的行动：请先选择并失去一件物品。"
		show_effect_feedback("必须先完成物品丢弃，不能结束回合", Color("#ef6f6c"), "强制行动")
		if mandatory_action_source == "modern_03":
			show_modern_03_discard_choices()
		else:
			show_museum_discard_choices()
		return
	if deferred_event_pending:
		end_turn_button.disabled = true
		review_event_button.visible = true
		review_event_button.text = "结算事件效果"
		instruction_label.text = "《误以为已经完成》尚未结算，不能结束回合。"
		show_effect_feedback("必须先结算延后的事件效果", Color("#ef6f6c"), "强制行动")
		return
	if settlement_in_progress or event_choice_pending:
		end_turn_button.disabled = true
		show_effect_feedback("当前结算尚未完成", Color("#ef6f6c"), "请稍候")
		return
	event_overlay.visible = false
	for person_index in get_people_on_timeline(active_character):
		if travel_cooldowns[person_index] > 0:
			travel_cooldowns[person_index] -= 1
	if not prevent_time_advance:
		advance_time(active_character, 1, "回合结束")
	selected_location = ""
	event_resolved = false
	tower_attempted_this_turn = false
	location_skill_used_this_turn = false
	items_gained_this_turn = 0
	items_lost_this_turn = 0
	prevent_time_advance = false
	event_item_effects_enabled = true
	archive_choice_made = false
	current_event_card = {}
	current_event_result = ""
	event_drawn_this_turn = false
	event_effect_resolved = false
	settlement_in_progress = false
	event_choice_pending = false
	mandatory_action_pending = false
	mandatory_action_source = ""
	deferred_event_pending = false
	if time_indices[0] >= TIMES.size() and time_indices[1] >= TIMES.size():
		show_timeline_complete()
		return
	active_character = 1 - active_character
	if time_indices[active_character] >= TIMES.size():
		active_character = 1 - active_character
	update_turn_ui()


func update_turn_ui() -> void:
	var current_time_text: String = TIMES[time_indices[active_character]] if time_indices[active_character] < TIMES.size() else "时间线末端"
	turn_label.text = "%s · %s" % [TIMELINE_NAMES[active_character], current_time_text]
	instruction_label.text = "AI 正在行动……" if is_ai_turn() else "选择一个地点。对方当前占据的地点无法进入。"
	draw_button.disabled = true
	draw_button.text = "请先选择地点"
	review_event_button.visible = false
	review_event_button.disabled = false
	end_turn_button.disabled = true
	refresh_timelines()
	refresh_locations()
	refresh_people_labels()
	refresh_turn_actions()
	if get_people_on_timeline(active_character).is_empty():
		instruction_label.text = "这条时间线当前无人：不能更换地点或抽卡，时间仍会正常前进。"
		location_action_button.visible = false
		for button in location_buttons.values():
			button.disabled = true
		if not empty_turn_in_progress:
			skip_empty_timeline_turn.call_deferred()
		return
	if is_ai_turn() and not ai_turn_in_progress:
		run_ai_turn.call_deferred()


func skip_empty_timeline_turn() -> void:
	if empty_turn_in_progress or not get_people_on_timeline(active_character).is_empty():
		return
	empty_turn_in_progress = true
	await get_tree().create_timer(1.2).timeout
	empty_turn_in_progress = false
	if get_people_on_timeline(active_character).is_empty():
		finish_turn()


func is_ai_turn() -> bool:
	return game_mode == "character" and person_timelines[player_character] != active_character


func run_ai_turn() -> void:
	if not is_ai_turn() or ai_turn_in_progress:
		return
	ai_turn_in_progress = true
	await get_tree().create_timer(0.8).timeout
	if not is_ai_turn():
		ai_turn_in_progress = false
		return
	var available_locations := LOCATIONS.filter(func(location: String) -> bool:
		return location != occupied_locations[1 - active_character]
	)
	selected_location = available_locations.pick_random()
	occupied_locations[active_character] = selected_location
	refresh_locations()
	if selected_location == "档案馆":
		if active_character == 0:
			if inventories[0].has("文件"):
				exchange_archive_file_for_key()
			else:
				skip_archive_exchange()
		else:
			activate_archive_past_effect()
	instruction_label.text = "AI 选择了「%s」，正在处理事件……" % selected_location
	await get_tree().create_timer(0.8).timeout
	var event_card := take_next_event_card(active_character)
	if not event_card.is_empty():
		resolve_event_card(event_card, active_character)
		if game_over:
			return
		while item_choice_overlay.visible:
			await get_tree().create_timer(0.2).timeout
	await get_tree().create_timer(0.8).timeout
	if selected_location == "钟塔":
		if active_character == 1 and inventories[1].count("石头") >= 1 and inventories[1].count("文件") >= 1:
			activate_tower_skill()
		elif active_character == 0 and inventories[0].has("钥匙"):
			activate_tower_skill()
			if game_over:
				return
	elif selected_location == "广场":
		if active_character == 1 and items_gained_this_turn == 0:
			event_resolved = true
			activate_plaza_skill()
		elif active_character == 0 and items_lost_this_turn > 0:
			activate_plaza_skill()
			if game_over:
				return
		elif active_character == 0 and not inventories[0].is_empty():
			var discard_item: String = choose_ai_discard_item(0)
			discard_item_for_plaza(discard_item)
			if game_over:
				return
	elif selected_location == "运河":
		if active_character == 1:
			event_resolved = true
		activate_canal_skill()
	elif selected_location == "博物馆":
		event_resolved = true
		activate_museum_skill()
	elif selected_location == "工坊":
		var eligible_people := get_people_on_timeline(active_character).filter(func(person_index: int) -> bool:
			return travel_cooldowns[person_index] == 0
		)
		if not eligible_people.is_empty():
			complete_workshop_travel(eligible_people[0], "")
	while item_choice_overlay.visible and not game_over:
		await get_tree().create_timer(0.2).timeout
	ai_turn_in_progress = false
	finish_turn()


func refresh_timelines() -> void:
	for character_index in range(2):
		for child in timeline_rows[character_index].get_children():
			child.queue_free()
		for time_index in range(TIMES.size()):
			var label := make_label(TIMES[time_index], 14)
			if time_index < time_indices[character_index]:
				label.add_theme_color_override("font_color", Color("#52627a"))
			elif time_index == time_indices[character_index]:
				label.add_theme_color_override("font_color", CHARACTER_COLORS[character_index])
			else:
				label.add_theme_color_override("font_color", Color("#93a4bd"))
			timeline_rows[character_index].add_child(label)
	for index in range(2):
		character_panels[index].modulate = Color.WHITE if index == active_character else Color(0.55, 0.6, 0.7, 0.7)


func refresh_locations() -> void:
	var blocked_location: String = occupied_locations[1 - active_character]
	var own_location: String = occupied_locations[active_character]
	for location in LOCATIONS:
		var button: Button = location_buttons[location]
		button.disabled = location == blocked_location
		if location == own_location:
			button.text = format_location_card_text(location, "%s已占据" % TIMELINE_NAMES[active_character])
		elif location == blocked_location:
			button.text = format_location_card_text(location, "%s占据中" % TIMELINE_NAMES[1 - active_character])
		else:
			button.text = format_location_card_text(location)


func check_ringing_success(trigger_location: String) -> bool:
	show_effect_feedback("铃声从%s响起，正在连接两条时间线……" % trigger_location, Color("#f4b860"), "响铃")
	var failure_reasons: PackedStringArray = []
	var tower_timeline := -1
	for timeline_index in range(occupied_locations.size()):
		if occupied_locations[timeline_index] == "钟塔" and not get_people_on_timeline(timeline_index).is_empty():
			tower_timeline = timeline_index
			break
	if tower_timeline == -1:
		failure_reasons.append("钟塔当前没有人")
	elif not inventories[tower_timeline].has("铃铛"):
		failure_reasons.append("钟塔所在时间线没有「铃铛」")
	if get_people_on_timeline(0).is_empty():
		failure_reasons.append("现在时间线没有人")
	if get_people_on_timeline(1).is_empty():
		failure_reasons.append("过去时间线没有人")
	if time_indices[0] != time_indices[1]:
		var modern_time: String = TIMES[time_indices[0]] if time_indices[0] < TIMES.size() else "时间线末端"
		var past_time: String = TIMES[time_indices[1]] if time_indices[1] < TIMES.size() else "时间线末端"
		failure_reasons.append("两条时间线不同步：现在为%s，过去为%s" % [modern_time, past_time])
	if failure_reasons.is_empty():
		show_game_won()
		return true
	show_ringing_failure(failure_reasons)
	return false


func show_ringing_failure(reasons: PackedStringArray) -> void:
	for child in item_choice_list.get_children():
		child.queue_free()
	var title := make_label("钟声未能连接时间线", 30, Color("#ef6f6c"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(title)
	var intro := make_label("响铃已经触发，但胜利条件尚未全部满足：", 18, Color("#d8e1ee"))
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_choice_list.add_child(intro)
	var reason_text := make_label("• %s" % "\n• ".join(reasons), 19, Color("#f4b860"))
	reason_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	reason_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_choice_list.add_child(reason_text)
	var continue_button := make_button("继续游戏", Vector2(300, 56))
	continue_button.pressed.connect(close_ringing_failure)
	item_choice_list.add_child(continue_button)
	item_choice_overlay.visible = true


func close_ringing_failure() -> void:
	item_choice_overlay.visible = false
	instruction_label.text = "响铃未成功，游戏继续。你仍可完成本回合的其他操作。"


func show_game_won() -> void:
	game_over = true
	clear_screen()
	make_background()
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-340, -230)
	center.size = Vector2(680, 460)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 24)
	add_child(center)
	var title := make_label("钟声响起！", 54, Color("#f4b860"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	var detail := make_label("钟塔有人守候，铃铛已就位，两条时间线也在同一时刻重合。\n跨越时空的钟声终于完整响起！", 24, Color("#d8e1ee"))
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(detail)
	var again_button := make_button("再玩一次")
	again_button.pressed.connect(start_game.bind(game_mode, player_character))
	center.add_child(again_button)
	var home_button := make_button("返回首页")
	home_button.pressed.connect(show_home)
	center.add_child(home_button)


func show_timeline_complete() -> void:
	clear_screen()
	make_background()
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-300, -210)
	center.size = Vector2(600, 420)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 22)
	add_child(center)
	var title := make_label("时间线已走完", 44, Color("#f6f0df"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	var detail := make_label("现代人与过去人都抵达了深夜之后。\n钟声的触发条件将在后续规则中加入。", 20, Color("#b9c7db"))
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(detail)
	var again_button := make_button("再试一次")
	again_button.pressed.connect(start_game.bind(game_mode, player_character))
	center.add_child(again_button)
	var home_button := make_button("返回首页")
	home_button.pressed.connect(show_home)
	center.add_child(home_button)
