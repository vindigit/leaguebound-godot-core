class_name RandomStreamKey
extends RefCounted


const VERSION: StringName = &"sha256-stream-key-v1"


static func derive_seed(parent_seed: int, label: StringName, source_version: StringName) -> int:
	assert(not label.is_empty(), "child stream labels must be non-empty")
	var material := "%d|%s|%s|%s" % [parent_seed, VERSION, source_version, label]
	var context := HashingContext.new()
	var start_error := context.start(HashingContext.HASH_SHA256)
	assert(start_error == OK, "unable to initialize deterministic stream hashing")
	var update_error := context.update(material.to_utf8_buffer())
	assert(update_error == OK, "unable to hash deterministic stream material")
	var digest := context.finish()
	var derived_seed: int = 0
	for index in range(8):
		derived_seed = (derived_seed << 8) | int(digest[index])
	return derived_seed
