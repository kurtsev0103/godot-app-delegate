class_name OKApp extends OKModule


signal module_loaded
signal load_progress


var _modules: Dictionary
var _loading_modules: Array
var _async_threads: Array
var _sync_thread: OKThread
var _sync_waiting: Array
var _total_progress: int
var _load_progress: int

# Initialization


func _init():
	_load_app_package()


func _load_app_package():
	var loader = OKLoader.new()
	var p = "res://package.gd"
	var script = loader.load_content(p)
	assert(is_instance_valid(script), 'Create the file "package.gd" in the root folder')
	script = script.new()
	package_ready(script.package())


# Public Methods


func load_module(module: String, async: bool = true):
	if !_modules.has(module) and !_loading_modules.has(module):
		_loading_modules.append(module)
		_setup_load_progress([module], true)
		_load_module(module, async)


func load_modules(modules: Array, async: bool = true):
	_setup_load_progress(modules)
	for module in modules: 
		if !_modules.has(module) and !_loading_modules.has(module):
			_loading_modules.append(module)
			_load_module(module, async)


func module(module: String) -> OKModule:
	return _modules.get(module, null)


func has_module(module: String) -> bool:
	return _modules.has(module)


func await_module(module: String):
	while true:
		yield(get_tree(), "idle_frame")
		
		if !_modules.has(module) and !_loading_modules.has(module):
			load_module(module)
		
		if _modules.has(module):
			return _modules.get(module)


# Signals


func _on_module_loaded(thread: OKThread, result: Dictionary):
	if thread.has_meta("async"):
		_async_threads.append(thread)
	
	var m_name = result.name
	var assets = result.assets
	
	var scene_path = "%s/%s.tscn" % [m_name, m_name]
	var full_scene_path = App.package("modules_path") + scene_path
	
	var package_path = "%s/package.gd" % m_name
	var full_package_path = App.package("modules_path") + package_path
	
	var scene = assets.get(full_scene_path, null)
	var package = assets.get(full_package_path, null)
	
	if scene:
		var main = get_node("/root/main")
		scene = scene.instance()
		
		if package:
			var script = package.new()
			var dict = script.package()
			scene.package_ready(dict)
		
		scene.assets_ready(assets)
		scene.scene_ready(main)
		
		_modules[m_name] = scene
		_loading_modules.erase(m_name)
		emit_signal("module_loaded", scene)
	
	if thread.has_meta("sync") and !_sync_waiting.empty():
		yield(get_tree(), "idle_frame")
		_load_module(_sync_waiting.pop_front(), false)


func _on_load_progress():
	_load_progress -= 1
	var norm = float(_load_progress) / float(_total_progress)
	var progress = (1.0 - norm) * 100.0
	
	if progress == 100.0:
		_load_progress = 0
		_total_progress = 0
	
	emit_signal("load_progress", progress)


# Private Methods


func _load_module(module: String, async: bool = true):
	if async:
		var thread = _get_async_thread()
		thread.load_module(module, async)
	else:
		var thread = _get_sync_thread()
		match thread.is_active():
			true: _sync_waiting.append(module)
			false: thread.load_module(module, async)


func _setup_load_progress(modules: Array, force: bool = false):
	for module in modules:
		if force or (!_modules.has(module) and !_loading_modules.has(module)):
			var root_path = App.package("modules_path") + module
			var paths = OKHelper.get_dir_contents(root_path)
			_total_progress += paths.size()
			_load_progress += paths.size()


# Helpers


func _get_async_thread() -> OKThread:
	if !_async_threads.empty(): 
		return _async_threads.pop_back()
	
	var thread = OKThread.new()
	thread.set_meta("async", true)
	thread.connect("module_loaded", self, "_on_module_loaded")
	thread.connect("load_progress", self, "_on_load_progress")
	return thread


func _get_sync_thread() -> OKThread:
	if _sync_thread: 
		return _sync_thread
	
	_sync_thread = OKThread.new()
	_sync_thread.set_meta("sync", true)
	_sync_thread.connect("module_loaded", self, "_on_module_loaded")
	_sync_thread.connect("load_progress", self, "_on_load_progress")
	return _sync_thread
