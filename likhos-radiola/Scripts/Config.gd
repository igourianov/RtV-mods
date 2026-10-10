extends RefCounted

static var instance := new()

# the hiss bed underneath the music
@export var radio_static: bool = true
# percent chance each radio starts playing a random station on zone load
@export_range(0.0, 100.0, 1.0) var radio_on_chance: float = 75.0
