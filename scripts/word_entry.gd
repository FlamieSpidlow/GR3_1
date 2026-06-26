class_name WordEntry
extends RefCounted

var word: String
var puzzle_word: String
var meaning: String
var base: String
var diacritics: Array[Dictionary]
var letters: Array[String]
var length: int

func _init(new_word: String, new_meaning: String) -> void:
	var clean: String = VietnameseNormalizer.clean_word(new_word)
	word = clean
	# Keep spaces in word for guessing, but remove them for board placement.
	puzzle_word = VietnameseNormalizer.compact_word(clean)
	meaning = new_meaning.strip_edges()
	var normalized: Dictionary = VietnameseNormalizer.split_word(puzzle_word)
	base = normalized["base"]
	diacritics = normalized["diacritics"]
	letters = normalized["letters"]
	length = letters.size()
