class_name VietnameseNormalizer
extends RefCounted

static func clean_word(word: String) -> String:
	return word.strip_edges().to_lower()

static func compact_word(word: String) -> String:
	return clean_word(word).replace(" ", "")

static func split_word(word: String) -> Dictionary:
	var clean: String = clean_word(word)
	var base: String = ""
	var diacritics: Array[Dictionary] = []
	var letters: Array[String] = []
	for ch in clean:
		var info: Dictionary = DiacriticHelper.char_to_info(String(ch))
		base += info["base"]
		diacritics.append(info)
		letters.append(info["char"])
	return {"base": base, "diacritics": diacritics, "letters": letters}

static func count_letters(word: String) -> int:
	return split_word(word)["letters"].size()

static func matches_full(input: String, target: String) -> bool:
	return clean_word(input) == clean_word(target)

static func matches_answer(input: String, target: String) -> bool:
	return matches_full(input, target) or compact_word(input) == compact_word(target)

static func matches_base(input: String, target: String) -> bool:
	return DiacriticHelper.strip_diacritics(clean_word(input)) == DiacriticHelper.strip_diacritics(clean_word(target))
