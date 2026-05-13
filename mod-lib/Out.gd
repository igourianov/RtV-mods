const PROTIP_COLOR: Color = Color(0.3, 0.7, 1.0)
const PROTIP_DELAY: int = 10 * 60 * 1000 # 10 minutes
static var protip_timers: Dictionary[StringName,int] = {}

static var prefix: String = "[likho]"
static var debug_enabled: bool = true
static var mod_main: Node


static func debug(...args):
	if debug_enabled:
		print(prefix, " [DEBUG] ", " ".join(args.map(str)))


static func warning(...args):
	push_warning(prefix, " [WARNING] ", " ".join(args.map(str)))


static func bugfix(...args):
	print(prefix, " [BUGFIX] ", " ".join(args.map(str)))


static func protip(id: StringName, message: String) -> bool:
	var loader = mod_main.get_node_or_null("/root/Loader")
	if !loader:
		return false
	var last = protip_timers.get(id, 0)
	var now = Time.get_ticks_msec()
	protip_timers.set(id, now)
	if last && (now - last) < PROTIP_DELAY:
		return false
	loader.Message("Likho's pro-tip: " + message, PROTIP_COLOR)
	return true

