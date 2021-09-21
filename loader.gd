class_name OKLoader extends Reference


signal module_loaded
signal load_progress


var _module_name: String = ""
var _assets: Dictionary = {}
var _tasks_count: int = 0


# Public Methods


func load_module_async(module: String):
	var paths = OKHelper.get_dir_contents(App.package("modules_path") + module)
	_tasks_count = paths.size()
	_module_name = module
	
	for path in paths:
		var loader = ResourceLoader.load_interactive(path)
		if loader != null: _load_content(loader, path)
		else: _check_finished("Unable to load content")


func load_module_sync(module: String):
	var paths = OKHelper.get_dir_contents(App.package("modules_path") + module)
	_tasks_count = paths.size()
	_module_name = module
	
	for path in paths:
		var resource = ResourceLoader.load(path)
		_load_complete(resource, path)


func load_content(path: String):
	return ResourceLoader.load(path)


# Private Methods


func _load_content(loader: ResourceInteractiveLoader, path: String):
	match loader.wait():
		ERR_FILE_EOF: _load_complete(loader.get_resource(), path)
		_: _check_finished("Unable to load content")


func _load_complete(resource: Resource, path: String):
	_assets[path] = resource
	_check_finished()


func _check_finished(error: String = ""):
	_update_progress()
	
	if !error.empty(): 
		printerr(error)
	if _tasks_count == 0: 
		_finished()


func _finished():
	var result = {
		"name": _module_name,
		"assets": _assets.duplicate(),
	}
	
	_module_name = ""
	_tasks_count = 0
	_assets.clear()
	
	call_deferred("emit_signal", "module_loaded", result)


func _update_progress():
	_tasks_count -= 1
	call_deferred("emit_signal", "load_progress")
