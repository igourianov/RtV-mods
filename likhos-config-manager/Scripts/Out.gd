const PREFIX := "[LCM]"


static func debug(...args):
	print(PREFIX, " [DEBUG] ", " ".join(args.map(str)))


static func warning(...args):
	push_warning(PREFIX, " [WARNING] ", " ".join(args.map(str)))
