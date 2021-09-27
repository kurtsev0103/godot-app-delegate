class_name OKApp extends OKModule


signal module_loaded
signal load_progress

var _sync_thread: OKThread
var _async_threads: Array
var _active_threads: Dictionary

var _modules: Dictionary
var _sync_waiting: Array
var _loading_modules: Array
var _incorrect_modules: Array
var _content_paths: Dictionary

var _total_progress: int
var _load_progress: int


# Initialization


func _init():
	_load_app_package()


func _load_app_package():
	var thread = _get_sync_thread()
	var script = thread.load_content("res://package.gd")
	assert(is_instance_valid(script), 'Create the file "package.gd" in the root folder')
	script = script.new()
	package_ready(script.package())


# Public Methods


func load_module(module: String, async: bool = true):
	if _is_module_not_found(module):
		_setup_load_progress([module])
		_preload_module(module, async)


func load_modules(modules: Array, async: bool = true):
	_setup_load_progress(modules)
	for module in modules: 
		if _is_module_not_found(module):
			_preload_module(module, async)


func unload_module(module: String):
	if _loading_modules.has(module):
		yield(await_module(module), "completed")
	
	yield(get_tree(), "idle_frame")
	if _modules.has(module):
		var scene = _modules.get(module)
		_modules.erase(module)
		scene.queue_free()
	yield(get_tree(), "idle_frame")


func unload_modules(modules: Array):
	for module in modules:
		unload_module(module)
	
	while true:
		yield(get_tree(), "idle_frame")
		
		var modules_count = 0
		for module in modules:
			if _is_module_not_found(module):
				modules_count += 1
		
		if modules_count == modules.size():
			return


func module(module: String) -> OKModule:
	return _modules.get(module, null)


func has_module(module: String) -> bool:
	return _modules.has(module)


func await_module(module: String, async: bool = true) -> OKModule:
	while true:
		yield(get_tree(), "idle_frame")
		
		if _is_module_not_found(module):
			load_module(module, async)
		if _modules.has(module):
			return _modules.get(module)
		if _incorrect_modules.has(module):
			return null
	return null


func await_modules(modules: Array, async: bool = true) -> Array:
	while true:
		yield(get_tree(), "idle_frame")
		
		for module in modules:
			if _is_module_not_found(module):
				load_module(module, async)
		
		var loaded_count = 0
		for module in modules:
			if _modules.has(module) or _incorrect_modules.has(module):
				loaded_count += 1
		
		if loaded_count == modules.size():
			var result = {}
			for module in modules:
				if !_incorrect_modules.has(module):
					result[module] = _modules.get(module)
			return result
	return null


# Signals


func _on_module_loaded(result: Dictionary):
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
		_content_paths.erase(m_name)
		_loading_modules.erase(m_name)
		emit_signal("module_loaded", scene)
	
	var thread = _active_threads.get(m_name)
	var is_active = thread.is_active()
	
	while(is_active):
		yield(get_tree(), "idle_frame")
		is_active = thread.is_active()
	
	_active_threads.erase(m_name)
	
	if thread.get_meta("type") == "async":
		_async_threads.append(thread)
	elif thread.get_meta("type") == "sync" and !_sync_waiting.empty():
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


func _preload_module(module: String, async: bool):
	if _content_paths.has(module):
		_loading_modules.append(module)
		_load_module(module, async)


func _load_module(module: String, async: bool):
	if async:
		var thread = _get_async_thread()
		_active_threads[module] = thread
		thread.load_module(module, _content_paths[module])
	else:
		var thread = _get_sync_thread()
		if thread.is_active():
			_sync_waiting.append(module)
		else:
			_active_threads[module] = thread
			thread.load_module(module, _content_paths[module])


func _setup_load_progress(modules: Array):
	for module in modules:
		if _is_module_not_found(module) and !_content_paths.has(module):
			var root_path = App.package("modules_path") + module
			var paths = OKHelper.get_content_paths(root_path)
			if paths.empty(): 
				_incorrect_modules.append(module)
				continue
			
			_total_progress += paths.size()
			_load_progress += paths.size()
			_content_paths[module] = paths


# Helpers


func _is_module_not_found(module: String) -> bool:
	return !_modules.has(module) and !_loading_modules.has(module)


func _get_async_thread() -> OKThread:
	if !_async_threads.empty(): 
		return _async_threads.pop_back()
	
	var thread = OKThread.new("async")
	thread.connect("module_loaded", self, "_on_module_loaded")
	thread.connect("load_progress", self, "_on_load_progress")
	return thread


func _get_sync_thread() -> OKThread:
	if _sync_thread: 
		return _sync_thread
	
	_sync_thread = OKThread.new("sync")
	_sync_thread.connect("module_loaded", self, "_on_module_loaded")
	_sync_thread.connect("load_progress", self, "_on_load_progress")
	return _sync_thread
