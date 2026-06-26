class_name DiacriticHelper
extends RefCounted

# Tone order: ngang, sac, huyen, hoi, nga, nang.
const TONE_NAMES := ["ngang", "sac", "huyen", "hoi", "nga", "nang"]

const VOWEL_GROUPS := {
	"a": ["a", "á", "à", "ả", "ã", "ạ"],
	"aw": ["ă", "ắ", "ằ", "ẳ", "ẵ", "ặ"],
	"aa": ["â", "ấ", "ầ", "ẩ", "ẫ", "ậ"],
	"e": ["e", "é", "è", "ẻ", "ẽ", "ẹ"],
	"ee": ["ê", "ế", "ề", "ể", "ễ", "ệ"],
	"i": ["i", "í", "ì", "ỉ", "ĩ", "ị"],
	"o": ["o", "ó", "ò", "ỏ", "õ", "ọ"],
	"oo": ["ô", "ố", "ồ", "ổ", "ỗ", "ộ"],
	"ow": ["ơ", "ớ", "ờ", "ở", "ỡ", "ợ"],
	"u": ["u", "ú", "ù", "ủ", "ũ", "ụ"],
	"uw": ["ư", "ứ", "ừ", "ử", "ữ", "ự"],
	"y": ["y", "ý", "ỳ", "ỷ", "ỹ", "ỵ"],
}

const VARIANT_TO_BASE := {
	"aw": "a",
	"aa": "a",
	"ee": "e",
	"oo": "o",
	"ow": "o",
	"uw": "u",
}

const CONSONANTS := ["b", "c", "d", "đ", "g", "h", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "x"]

static func char_to_info(ch: String) -> Dictionary:
	var lower: String = ch.to_lower()
	for variant in VOWEL_GROUPS.keys():
		var list: Array = VOWEL_GROUPS[variant]
		var idx: int = list.find(lower)
		if idx != -1:
			var base: String = String(VARIANT_TO_BASE.get(variant, variant))
			return {
				"char": lower,
				"base": base,
				"variant": variant,
				"tone": idx,
				"is_vowel": true,
			}
	return {
		"char": lower,
		"base": lower,
		"variant": "",
		"tone": -1,
		"is_vowel": false,
	}

static func strip_diacritics(text: String) -> String:
	var out: String = ""
	for ch in text:
		var info: Dictionary = char_to_info(String(ch))
		out += info["base"]
	return out

static func apply_tone(letter: String, tone: int) -> String:
	var info: Dictionary = char_to_info(letter)
	if not info["is_vowel"]:
		return letter
	var variant: String = String(info["variant"])
	if variant == "":
		variant = String(info["base"])
	if not VOWEL_GROUPS.has(variant):
		return letter
	var list: Array = VOWEL_GROUPS[variant]
	if tone < 0 or tone >= list.size():
		return letter
	return list[tone]

static func get_keyboard_base_letters() -> Array[String]:
	var letters: Array[String] = []
	letters.append_array(CONSONANTS)
	var vowels: Array[String] = ["a", "ă", "â", "e", "ê", "i", "o", "ô", "ơ", "u", "ư", "y"]
	letters.append_array(vowels)
	return letters

static func get_keyboard_letters() -> Array[String]:
	var letters: Array[String] = []
	letters.append_array(CONSONANTS)
	var order: Array[String] = ["a", "aw", "aa", "e", "ee", "i", "o", "oo", "ow", "u", "uw", "y"]
	for variant in order:
		letters.append_array(VOWEL_GROUPS[variant])
	return letters

static func get_tone_labels() -> Array[String]:
	return ["Ngang", "Sắc", "Huyền", "Hỏi", "Ngã", "Nặng"]
