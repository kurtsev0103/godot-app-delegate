class_name OKLoader extends Reference


signal module_loaded
signal load_progress

var _loader: ResourceInteractiveLoader
var _module_name: String = ""
var _assets: Dictionary = {}
var _tasks_count: int = 0


# Public Methods


func load_module(userdata: Dictionary):
	_tasks_count = userdata.paths.size()
	_module_name = userdata.module
	
	for path in userdata.paths:
		_loader = ResourceLoader.load_interactive(path)
		if _loader != null: _load_content(path)
		else: _check_finished("Unable to load content")


func load_content(path: String):
	return ResourceLoader.load(path)


# Private Methods


func _load_content(path: String):
	match _loader.wait():
		ERR_FILE_EOF: _load_complete(_loader.get_resource(), path)
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
