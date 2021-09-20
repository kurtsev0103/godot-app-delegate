class_name OKModule extends Node


var _assets: Dictionary
var _package: Dictionary


# Module Life Cycle


func scene_ready(main: Node):
	main.add_child(self)


func package_ready(package: Dictionary):
	_package = package


func assets_ready(assets: Dictionary):
	_assets = assets


# Public Methods


func asset(n: String) -> Resource:
	var mid = self.name + "/assets/"
	var path = App.package("modules_path") + mid + n
	return _assets.get(path, null)


func assets(n: String) -> Array:
	var mid = self.name + "/assets/"
	var path = App.package("modules_path") + mid + n
	var result = []
	
	for key in _assets.keys():
		if path in key:
			result.append(_assets.get(key))
	
	return result


func package(what: String):
	return _package.get(what, null)
