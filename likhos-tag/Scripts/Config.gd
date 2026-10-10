extends Resource

static var instance := new()

# read once on startup, so a change takes a game restart
@export var force_english_names: bool = false
