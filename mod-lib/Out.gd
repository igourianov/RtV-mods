
static var prefix: String = "[likho]"

static func debug(...args):
	print(prefix, " [DEBUG] ", " ".join(args.map(str)))

static func warning(...args):
	push_warning(prefix, " [WARNING] ", " ".join(args.map(str)))