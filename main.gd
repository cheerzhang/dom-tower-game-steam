extends Control

const TIMES := ["清晨", "上午", "中午", "下午", "深夜"]
const LOCATIONS := ["钟塔", "广场", "运河", "博物馆", "档案馆", "工坊"]
const CHARACTER_NAMES := ["现代人", "过去人"]
const CHARACTER_COLORS := [Color("#55c2ff"), Color("#f4b860")]

var active_character := 0
var time_indices := [0, 0]
var occupied_locations := ["", ""]
var event_deck: Array[int] = []
var selected_location := ""
var location_buttons: Dictionary = {}
var turn_label: Label
var instruction_label: Label
var timeline_rows: Array[HBoxContainer] = []
var character_panels: Array[PanelContainer] = []
var draw_button: Button
var event_overlay: ColorRect
var event_title: Label
var event_body: Label
var game_mode := "single"
var player_character := 0
var ai_turn_in_progress := false


func _ready() -> void:
	show_home()


func clear_screen() -> void:
	for child in get_children():
		child.queue_free()
	location_buttons.clear()
	timeline_rows.clear()
	character_panels.clear()


func make_background() -> void:
	var background := ColorRect.new()
	background.color = Color("#101827")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)


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
	return button


func show_home() -> void:
	clear_screen()
	make_background()
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-310, -230)
	center.size = Vector2(620, 460)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 22)
	add_child(center)
	var eyebrow := make_label("A TIME-BENDING COOPERATIVE GAME", 20, Color("#f4b860"))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(eyebrow)
	var title := make_label("DOM TOWER", 64, Color("#f6f0df"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	center.add_child(HSeparator.new())
	var goal := make_label("让跨越时空的钟声再次响起", 28, Color("#b9c7db"))
	goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(goal)
	var start_button := make_button("开始游戏")
	start_button.pressed.connect(show_mode_select)
	center.add_child(start_button)
	var hint := make_label("选择游玩模式，修复跨越时空的钟塔", 21, Color("#8190a8"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(hint)


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
	active_character = 0
	time_indices = [0, 0]
	occupied_locations = ["", ""]
	selected_location = ""
	event_deck.clear()
	for card in range(1, 21):
		event_deck.append(card)
	event_deck.shuffle()
	build_game_screen()
	update_turn_ui()


func build_game_screen() -> void:
	clear_screen()
	make_background()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 20)
	margin.add_child(page)
	var header := HBoxContainer.new()
	page.add_child(header)
	var brand := make_label("DOM TOWER", 34, Color("#f6f0df"))
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	var exit_button := make_button("退出游戏", Vector2(130, 42))
	exit_button.pressed.connect(show_home)
	header.add_child(exit_button)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 16)
	page.add_child(status)
	for index in range(2):
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.custom_minimum_size.y = 108
		status.add_child(panel)
		character_panels.append(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		panel.add_child(box)
		box.add_child(make_label(CHARACTER_NAMES[index], 26, CHARACTER_COLORS[index]))
		box.add_child(make_label("此刻的守望者" if index == 0 else "穿越时间的来客", 20, Color("#93a4bd")))
		var timeline := HBoxContainer.new()
		timeline.add_theme_constant_override("separation", 8)
		box.add_child(timeline)
		timeline_rows.append(timeline)
	var turn_box := VBoxContainer.new()
	turn_box.add_theme_constant_override("separation", 4)
	page.add_child(turn_box)
	turn_label = make_label("", 38, Color("#f6f0df"))
	turn_box.add_child(turn_label)
	instruction_label = make_label("", 22, Color("#b9c7db"))
	turn_box.add_child(instruction_label)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	page.add_child(grid)
	for location in LOCATIONS:
		var button := make_button(location, Vector2(0, 92))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.pressed.connect(select_location.bind(location))
		grid.add_child(button)
		location_buttons[location] = button
	draw_button = make_button("请先选择地点", Vector2(260, 56))
	draw_button.disabled = true
	draw_button.pressed.connect(draw_event_card)
	page.add_child(draw_button)
	build_event_overlay()


func build_event_overlay() -> void:
	event_overlay = ColorRect.new()
	event_overlay.color = Color(0.03, 0.05, 0.09, 0.94)
	event_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	event_overlay.visible = false
	add_child(event_overlay)
	var card := VBoxContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-240, -175)
	card.size = Vector2(480, 350)
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_theme_constant_override("separation", 22)
	event_overlay.add_child(card)
	event_title = make_label("", 30, Color("#f4b860"))
	event_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(event_title)
	event_body = make_label("", 24, Color("#d8e1ee"))
	event_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(event_body)
	var continue_button := make_button("结束回合")
	continue_button.pressed.connect(finish_turn)
	card.add_child(continue_button)


func select_location(location: String) -> void:
	if is_ai_turn():
		return
	selected_location = location
	occupied_locations[active_character] = location
	draw_button.disabled = false
	draw_button.text = "抽取事件卡"
	instruction_label.text = "已选择「%s」。现在抽取一张事件卡。" % location
	refresh_locations()


func draw_event_card() -> void:
	if is_ai_turn():
		return
	show_event_card()


func show_event_card() -> void:
	var card_number: int = event_deck.pop_front() if not event_deck.is_empty() else 0
	event_title.text = "事件卡 %02d" % card_number
	event_body.text = "事件内容暂时留空\n\n%s 在「%s」发现了一段尚未书写的故事。" % [CHARACTER_NAMES[active_character], selected_location]
	event_overlay.visible = true


func finish_turn() -> void:
	event_overlay.visible = false
	time_indices[active_character] += 1
	selected_location = ""
	if time_indices[0] >= TIMES.size() and time_indices[1] >= TIMES.size():
		show_timeline_complete()
		return
	active_character = 1 - active_character
	if time_indices[active_character] >= TIMES.size():
		active_character = 1 - active_character
	update_turn_ui()


func update_turn_ui() -> void:
	turn_label.text = "%s · %s" % [CHARACTER_NAMES[active_character], TIMES[time_indices[active_character]]]
	instruction_label.text = "AI 正在行动……" if is_ai_turn() else "选择一个地点。对方当前占据的地点无法进入。"
	draw_button.disabled = true
	draw_button.text = "请先选择地点"
	refresh_timelines()
	refresh_locations()
	if is_ai_turn() and not ai_turn_in_progress:
		run_ai_turn.call_deferred()


func is_ai_turn() -> bool:
	return game_mode == "character" and active_character != player_character


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
	instruction_label.text = "AI 选择了「%s」，正在处理事件……" % selected_location
	await get_tree().create_timer(0.8).timeout
	var card_number: int = event_deck.pop_front() if not event_deck.is_empty() else 0
	await get_tree().create_timer(0.8).timeout
	ai_turn_in_progress = false
	finish_turn()


func refresh_timelines() -> void:
	for character_index in range(2):
		for child in timeline_rows[character_index].get_children():
			child.queue_free()
		for time_index in range(TIMES.size()):
			var label := make_label(TIMES[time_index], 20)
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
	for location in LOCATIONS:
		var button: Button = location_buttons[location]
		button.disabled = location == blocked_location
		if location == selected_location:
			button.text = "%s\n%s 已占据" % [location, CHARACTER_NAMES[active_character]]
		elif location == blocked_location:
			button.text = "%s\n%s 占据中" % [location, CHARACTER_NAMES[1 - active_character]]
		else:
			button.text = location


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
