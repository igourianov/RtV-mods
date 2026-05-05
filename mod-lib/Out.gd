
static var prefix: String = "[likho]"
static var debug_enabled: bool = true

static func debug(...args):
	if debug_enabled:
		print(prefix, " [DEBUG] ", " ".join(args.map(str)))

static func warning(...args):
	push_warning(prefix, " [WARNING] ", " ".join(args.map(str)))