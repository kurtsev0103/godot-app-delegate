class_name OKLoader extends Reference

signal module_loaded

var _module_name: String = ""
var _package: Dictionary = {}
var _assets: Dictionary = {}
var _task_count: int = 0

# Public Methods

func load_module_async(module: String):
	var paths = _get_dir_contents(App.package("modules_path") + module)
	_task_count = paths.size()
	_module_name = module
	
	for path in paths:
		var loader = ResourceLoader.load_interactive(path)
		if loader != null: _load_content(loader, path)
		else: _check_finished("Unable to load content")

func load_module_sync(module: String):
	var paths = _get_dir_contents(App.package("modules_path") + module)
	_task_count = paths.size()
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
	_task_count -= 1
	
	if !error.empty(): 
		printerr(error)
	if _task_count == 0: 
		_finished()

func _finished():
	var result = {
		"name": _module_name,
		"assets": _assets.duplicate(),
		"package": _package.duplicate(),
	}
	
	_module_name = ""
	_task_count = 0
	_package.clear()
	_assets.clear()
	
	emit_signal("module_loaded", result)

# Helpers

func _get_dir_contents(rootPath: String) -> Array:
	var dir = Directory.new()
	var directories = []
	var files = []
	
	if dir.open(rootPath) == OK:
		dir.list_dir_begin(true, false)
		_add_dir_contents(dir, files, directories)
	else:
		printerr("An error occurred when trying to access the path.")
	
	return files

func _add_dir_contents(dir: Directory, files: Array, directories: Array):
	var file_name = dir.get_next()
	
	while (file_name != ""):
		if file_name[0] == ".": 
			file_name = dir.get_next()
			continue
		
		var path = dir.get_current_dir() + "/" + file_name
		
		if dir.current_is_dir():
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			directories.append(path)
			_add_dir_contents(subDir, files, directories)
		elif !(".import" in path):
			files.append(path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
