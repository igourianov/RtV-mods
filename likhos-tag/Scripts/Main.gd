extends "../Lib/Main.gd"

const Catalog = preload("./Catalog.gd")


func setup(lib) -> void:
	Catalog.apply(lib)
