
var _prefix: String = "[likho]"

func _init(prefix: String):
	_prefix = prefix

func debug(...args):
	print(_prefix, " [DEBUG] ", " ".join(args.map(str)))

func warning(...args):
	push_warning(_prefix, " [WARNING] ", " ".join(args.map(str)))