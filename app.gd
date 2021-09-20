class_name OKApp extends OKModule


signal module_loaded


var _modules: Dictionary
var _async_threads: Array
var _sync_thread: OKThread
var _sync_waiting: Array


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
	if async:
		var thread = _get_async_thread()
		thread.load_module(module, async)
	else:
		var thread = _get_sync_thread()
		match thread.is_active():
			true: _sync_waiting.append(module)
			false: thread.load_module(module, async)


func load_modules(modules: Array, async: bool = true):
	for module in modules: 
		load_module(module, async)


func module(module: String) -> OKModule:
	return _modules.get(module, null)


func has_module(module: String) -> bool:
	return _modules.has(module)


# Signals


func _on_module_loaded(thread: OKThread, result: Dictionary):
	if thread.has_meta("async"):
		_async_threads.append(thread)
	
	var m_name = result.name
	var assets = result.assets
	var package = result.package
	var scene_path = "%s/%s.tscn" % [m_name, m_name]
	var full_scene_path = App.package("modules_path") + scene_path
	var scene = assets.get(full_scene_path, null)
	
	if scene:
		var main = get_node("/root/main")
		scene = scene.instance()
		
		scene.package_ready(package)
		scene.assets_ready(assets)
		scene.scene_ready(main)
		
		_modules[m_name] = scene
		emit_signal("module_loaded", scene)
	
	if thread.has_meta("sync") and !_sync_waiting.empty():
		yield(get_tree(), "idle_frame")
		load_module(_sync_waiting.pop_front(), false)


# Helpers


func _get_async_thread() -> OKThread:
	if !_async_threads.empty(): 
		return _async_threads.pop_back()
	
	var thread = OKThread.new()
	thread.set_meta("async", true)
	thread.connect("module_loaded", self, "_on_module_loaded")
	return thread


func _get_sync_thread() -> OKThread:
	if _sync_thread: 
		return _sync_thread
	
	_sync_thread = OKThread.new()
	_sync_thread.set_meta("sync", true)
	_sync_thread.connect("module_loaded", self, "_on_module_loaded")
	return _sync_thread
