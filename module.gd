class_name OKModule extends Node


var _assets: Dictionary
var _package: Dictionary


# Module Life Cycle


func package_ready(package: Dictionary):
	_package = package
	
	if has_method("_package_ready"):
		call("_package_ready")


func assets_ready(assets: Dictionary):
	_assets = assets
	
	if has_method("_assets_ready"):
		call("_assets_ready")


func scene_ready(main: Node):
	if has_method("_scene_ready"):
		call("_scene_ready")
	
	main.add_child(self)


# Public Methods


func asset(n: String = "") -> Resource:
	var mid = self.name + "/assets/"
	var path = App.package("modules_path") + mid + n
	return _assets.get(path, null)


func assets(n: String = "") -> Array:
	var mid = self.name + "/assets/"
	var path = App.package("modules_path") + mid + n
	var result = []
	
	for key in _assets.keys():
		if path in key:
			result.append(_assets.get(key))
	
	return result


func package(what: String):
	return _package.get(what, null)
