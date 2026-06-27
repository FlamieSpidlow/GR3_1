extends SceneTree

# Headless logic test runner for TC01..TC14.
# Run: godot --headless --path <project> --script res://tools/test_runner.gd

var _pass := 0
var _fail := 0

func _check(code: String, name: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("%s | %s | PASS | %s" % [code, name, detail])
	else:
		_fail += 1
		print("%s | %s | FAIL | %s" % [code, name, detail])

func _initialize() -> void:
	print("=== TEST RESULTS ===")
	var provider := ThemedLevelProvider.new()
	var generator := BoardGenerator.new()
	provider.build_levels(generator)

	# Clean slate for save tests.
	var fa := FileAccess.open("user://records.json", FileAccess.WRITE)
	if fa != null:
		fa.store_string(JSON.stringify(SaveManager._default_root_records()))
		fa = null

	# TC01 - create account
	var new_id := SaveManager.create_profile("Kiểm thử")
	var profiles := SaveManager.get_profiles()
	var has_new := false
	for p in profiles:
		if p["id"] == new_id:
			has_new = true
	_check("TC01", "Tạo tài khoản", new_id != "" and has_new and SaveManager.get_current_profile_id() == new_id,
		"id=%s, current=%s, so tk=%d" % [new_id, SaveManager.get_current_profile_id(), profiles.size()])

	# TC02 - select account
	var sel := SaveManager.select_profile("player")
	_check("TC02", "Chọn tài khoản", sel and SaveManager.get_current_profile_id() == "player",
		"chon lai 'player' -> current=%s" % SaveManager.get_current_profile_id())

	# TC03/TC04 - topic & stage available (logic level)
	var topic0 := provider.get_topic(0)
	var stages0 := provider.get_topic_stages(0)
	_check("TC03", "Chọn chủ đề (có dữ liệu)", not topic0.is_empty() and stages0.size() > 0,
		"chu de='%s', so man=%d" % [String(topic0.get("title", "")), stages0.size()])

	var stage_result := provider.create_stage_level(0, 0, generator)
	var board: Dictionary = stage_result.get("board", {})
	var placed: Array = board.get("placed_words", [])
	_check("TC04", "Chọn màn chơi (khởi tạo)", not stage_result.is_empty() and placed.size() >= 4,
		"man 1: so tu dat=%d" % placed.size())

	# TC05 - board generation: words placed and connected (no isolated)
	var connected_ok := _all_connected(board, placed)
	_check("TC05", "Sinh bảng ô chữ", placed.size() >= 4 and connected_ok,
		"so tu=%d, tat ca lien ket=%s" % [placed.size(), str(connected_ok)])

	# TC06 - correct answer matching (diacritics + spaces)
	var m1 := VietnameseNormalizer.matches_answer("Bánh Trung Thu", "bánh trung thu")
	var m2 := VietnameseNormalizer.matches_answer("bánhtrungthu", "bánh trung thu")
	var m3 := VietnameseNormalizer.matches_answer("  Giường  ", "giường")
	_check("TC06", "Nhập đáp án đúng", m1 and m2 and m3,
		"hoa/thuong=%s, bo trang=%s, trim+dau=%s" % [str(m1), str(m2), str(m3)])

	# TC07 - wrong / empty answer
	var w1 := VietnameseNormalizer.matches_answer("giuong", "giường")  # missing diacritics -> must be false
	var w2 := VietnameseNormalizer.matches_answer("", "giường")
	var w3 := VietnameseNormalizer.matches_answer("sai", "giường")
	_check("TC07", "Nhập đáp án sai/rỗng", (not w1) and (not w2) and (not w3),
		"khong dau=%s, rong=%s, sai=%s (ky vong false)" % [str(w1), str(w2), str(w3)])

	# Build a GameState for reveal/scoring tests
	var gs := GameState.new()
	gs.set_board(board)
	var first_id: int = int(placed[0]["id"])

	# TC08 - reveal one letter
	var r8 := gs.reveal_one_letter(first_id)
	gs.mark_hinted_letter(first_id)
	_check("TC08", "Dùng gợi ý mở chữ", r8 and gs.get_hinted_letter_count(first_id) >= 1,
		"mo 1 chu=%s, so chu da goi y=%d" % [str(r8), gs.get_hinted_letter_count(first_id)])

	# TC09 - reveal whole word
	var r9 := gs.reveal_word(first_id)
	var wd: Variant = gs.get_word_data(first_id)
	_check("TC09", "Dùng gợi ý mở cả từ", r9 and bool(wd.get("completed", false)),
		"mo ca tu=%s, hoan thanh=%s" % [str(r9), str(wd.get("completed", false))])

	# TC10 - insufficient stars
	var nid := SaveManager.create_profile("HetSao")
	var start_stars := SaveManager.load_total_stars()
	var spent_all := SaveManager.spend_stars(start_stars)
	var spent_more := SaveManager.spend_stars(1)
	_check("TC10", "Không đủ sao", spent_all and (not spent_more) and SaveManager.load_total_stars() == 0,
		"sao dau=%d, tieu het=%s, tieu them=%s (ky vong false)" % [start_stars, str(spent_all), str(spent_more)])
	SaveManager.select_profile("player")

	# TC11 - scoring & missions
	var gs2 := GameState.new()
	gs2.set_board(board)
	var wid: int = int(placed[0]["id"])
	gs2.select_word_timer(wid)
	var earned := gs2.award_score_for_word(wid)
	var missions: Array = gs2.missions
	_check("TC11", "Tính điểm và nhiệm vụ", earned > 0 and missions.size() == 3,
		"diem nhan=%d, tong diem=%d, so nhiem vu=%d" % [earned, gs2.score, missions.size()])

	# TC12 - save progress
	var saved := SaveManager.record_level_completion("test_stage_1", 3, 1500, 95)
	var prog := SaveManager.get_level_progress("test_stage_1")
	_check("TC12", "Lưu tiến độ", saved and bool(prog.get("completed", false)) and int(prog.get("stars", 0)) == 3,
		"luu=%s, hoan thanh=%s, sao=%d" % [str(saved), str(prog.get("completed", false)), int(prog.get("stars", 0))])

	# TC13 - reload progress (read fresh from disk)
	var prog2 := SaveManager.get_level_progress("test_stage_1")
	_check("TC13", "Tải lại tiến độ", bool(prog2.get("completed", false)) and int(prog2.get("best_score", 0)) == 1500,
		"doc lai: hoan thanh=%s, diem tot nhat=%d" % [str(prog2.get("completed", false)), int(prog2.get("best_score", 0))])

	# TC14 - corrupt / partial save normalization
	var bad := FileAccess.open("user://records.json", FileAccess.WRITE)
	if bad != null:
		bad.store_string('{"best_score": 7}')  # legacy/partial structure
		bad = null
	var recovered := SaveManager.load_records()
	var ok14 := recovered.has("profiles") and recovered.has("current_profile_id")
	_check("TC14", "Dữ liệu lưu không hợp lệ", ok14,
		"phuc hoi cau truc profiles=%s" % str(ok14))

	print("=== SUMMARY pass=%d fail=%d ===" % [_pass, _fail])
	quit()

func _all_connected(board: Dictionary, placed: Array) -> bool:
	if placed.size() <= 1:
		return true
	var grid: Array = board.get("grid", [])
	for wd in placed:
		var start: Vector2i = wd["start"]
		var dir: Vector2i = wd["dir"]
		var length: int = int(wd["length"])
		var has_cross := false
		for i in range(length):
			var pos: Vector2i = start + dir * i
			var cell: Variant = grid[pos.y][pos.x]
			if cell != null and cell.get("word_ids", []).size() > 1:
				has_cross = true
				break
		if not has_cross:
			return false
	return true
