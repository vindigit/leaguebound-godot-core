class_name JsonRead
extends RefCounted

## Typed readers for parsed JSON.
##
## `Dictionary.get` returns `Variant`, which the project's strict typing rejects
## at every call site. Funnelling the reads through here keeps the aggregator's
## deserialization readable and gives every field one defaulting rule instead of
## a cast per line.
##
## Each reader checks the stored type rather than coercing: a string where a
## number belongs is a corrupt report, and returning the fallback surfaces that
## as a validation failure downstream instead of a plausible-looking zero.


static func string_at(payload: Dictionary, key: String, fallback: String = "") -> String:
	if not payload.has(key):
		return fallback
	var value: Variant = payload[key]
	if typeof(value) == TYPE_STRING:
		var text: String = value
		return text
	if typeof(value) == TYPE_STRING_NAME:
		var name_value: StringName = value
		return String(name_value)
	return fallback


static func name_at(payload: Dictionary, key: String, fallback: StringName = &"") -> StringName:
	if not payload.has(key):
		return fallback
	var value: Variant = payload[key]
	if typeof(value) == TYPE_STRING:
		var text: String = value
		return StringName(text)
	if typeof(value) == TYPE_STRING_NAME:
		var name_value: StringName = value
		return name_value
	return fallback


static func int_at(payload: Dictionary, key: String, fallback: int = 0) -> int:
	if not payload.has(key):
		return fallback
	var value: Variant = payload[key]
	if typeof(value) == TYPE_INT:
		return value
	if typeof(value) == TYPE_FLOAT:
		var number: float = value
		return int(roundf(number))
	return fallback


static func float_at(payload: Dictionary, key: String, fallback: float = 0.0) -> float:
	if not payload.has(key):
		return fallback
	var value: Variant = payload[key]
	if typeof(value) == TYPE_FLOAT:
		return value
	if typeof(value) == TYPE_INT:
		var number: int = value
		return float(number)
	return fallback


static func bool_at(payload: Dictionary, key: String, fallback: bool = false) -> bool:
	if not payload.has(key):
		return fallback
	var value: Variant = payload[key]
	if typeof(value) != TYPE_BOOL:
		return fallback
	return value


static func dictionary_at(payload: Dictionary, key: String) -> Dictionary:
	if not payload.has(key):
		return {}
	var value: Variant = payload[key]
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return value


static func array_at(payload: Dictionary, key: String) -> Array:
	if not payload.has(key):
		return []
	var value: Variant = payload[key]
	if typeof(value) != TYPE_ARRAY:
		return []
	return value


## A float that may legitimately be absent, returned as NAN so a caller can tell
## "not present" from "present and zero".
static func optional_float_at(payload: Dictionary, key: String) -> float:
	if not payload.has(key):
		return NAN
	return float_at(payload, key, NAN)
