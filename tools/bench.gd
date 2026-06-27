extends SceneTree

# Headless benchmark for the crossword board generator.
# Run: godot --headless --path <project> --script res://tools/bench.gd

func _initialize() -> void:
	var provider := ThemedLevelProvider.new()
	var generator := BoardGenerator.new()
	provider.build_levels(generator)

	var topic_count := 0
	var stage_count := 0
	var stage_ok := 0
	var total_in := 0
	var total_placed := 0
	var total_usec := 0
	var per_theme: Array = []
	var min_ratio := 999.0
	var max_ratio := 0.0

	var topic_index := 0
	while true:
		var topic: Dictionary = provider.get_topic(topic_index)
		if topic.is_empty():
			break
		topic_count += 1
		var stages: Array = provider.get_topic_stages(topic_index)
		var t_in := 0
		var t_placed := 0
		var t_stages := 0
		var t_ok := 0
		var t_usec := 0
		for s in range(stages.size()):
			var stage: Dictionary = stages[s]
			var in_words: int = int(stage.get("words", []).size())
			if in_words == 0 and stage.has("entries"):
				in_words = int(stage["entries"].size())
			var t0 := Time.get_ticks_usec()
			var result: Dictionary = provider.create_stage_level(topic_index, s, generator)
			var dt := Time.get_ticks_usec() - t0
			stage_count += 1
			t_stages += 1
			t_usec += dt
			total_usec += dt
			if result.is_empty():
				continue
			var level: Dictionary = result["level"]
			# input count = number of entries the stage actually fed in
			var fed: int = int(provider.get_topic_stages(topic_index)[s].get("words", []).size())
			var placed: int = int(level.get("word_count", 0))
			# recompute input as entries count for accuracy
			var board: Dictionary = result["board"]
			var input_n: int = _stage_input_count(provider, topic_index, s)
			stage_ok += 1
			t_ok += 1
			total_in += input_n
			total_placed += placed
			t_in += input_n
			t_placed += placed
			var ratio := float(placed) / float(max(input_n, 1))
			min_ratio = min(min_ratio, ratio)
			max_ratio = max(max_ratio, ratio)
		per_theme.append({
			"title": String(topic.get("title", "")),
			"stages": t_stages,
			"ok": t_ok,
			"in": t_in,
			"placed": t_placed,
			"usec": t_usec,
		})
		topic_index += 1

	print("=== BENCHMARK RESULT ===")
	print("topics=", topic_count)
	print("stages_total=", stage_count)
	print("stages_ok=", stage_ok)
	print("words_in=", total_in)
	print("words_placed=", total_placed)
	printt("placed_ratio=%.4f" % (float(total_placed) / float(max(total_in, 1))))
	printt("min_stage_ratio=%.4f" % min_ratio, "max_stage_ratio=%.4f" % max_ratio)
	printt("total_ms=%.2f" % (float(total_usec) / 1000.0))
	printt("avg_ms_per_stage=%.2f" % (float(total_usec) / 1000.0 / float(max(stage_count, 1))))
	print("--- PER THEME (title | stages | ok | in | placed | ms) ---")
	for row in per_theme:
		print("%s | %d | %d | %d | %d | %.2f" % [row["title"], row["stages"], row["ok"], row["in"], row["placed"], float(row["usec"]) / 1000.0])
	quit()

func _stage_input_count(provider, topic_index: int, stage_index: int) -> int:
	var stages: Array = provider.get_topic_stages(topic_index)
	if stage_index < 0 or stage_index >= stages.size():
		return 0
	var stage: Dictionary = stages[stage_index]
	if stage.has("entries") and typeof(stage["entries"]) == TYPE_ARRAY:
		return int(stage["entries"].size())
	return 0
