class_name OKApp extends OKModule

var version = "0.0.0"


# Signals
signal load_progress
signal module_loaded
signal module_unloaded

# Threads
var _sync_thread: OKThread
var _async_threads: Array
var _canceled_threads: Array
var _active_threads: Dictionary

# Modules
var _modules: Dictionary
var _loading_modules: Array
var _waiting_modules: Array
var _incorrect_modules: Array
var _content_paths: Dictionary

# Properties
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


func load_module(module: String, async: bool = true) -> OKModule:
	_setup_load_progress(module)
	_preload_module(module, async)
	
	return yield(_await_module(module), "completed")


func load_modules(modules: Array, async: bool = true) -> Array:
	for module in modules:
		_setup_load_progress(module)
	for module in modules: 
		_preload_module(module, async)
	
	return yield(_await_modules(modules), "completed")


func await_module(module: String) -> OKModule:
	return yield(load_module(module), "completed")


func await_modules(modules: Array) -> Dictionary:
	return yield(load_modules(modules), "completed")


func unload_module(module: String):
	yield(get_tree(), "idle_frame")
	_unload_module(module)
	yield(get_tree(), "idle_frame")


func unload_modules(modules: Array):
	yield(get_tree(), "idle_frame")
	for module in modules:
		_unload_module(module)
	yield(get_tree(), "idle_frame")


func module(module: String) -> OKModule:
	return _modules.get(module, null)


func has_module(module: String) -> bool:
	return _modules.has(module)


func is_module_loading(module: String) -> bool:
	return _loading_modules.has(module)


# Signals


func _on_module_loaded(result: Dictionary):
	var m_name = result.name
	var assets = result.assets
	
	var scene_path = "%s/%s.tscn" % [m_name, m_name]
	var full_scene_path = App.package("modules_path") + scene_path
	
	var script_path = "%s/%s.gd" % [m_name, m_name]
	var full_script_path = App.package("modules_path") + script_path
	
	var package_path = "%s/package.gd" % m_name
	var full_package_path = App.package("modules_path") + package_path
	
	var main = get_node("/root").get_child(1)
	var scene = assets.get(full_scene_path, null)
	var script = assets.get(full_script_path, null)
	var package = assets.get(full_package_path, null)
	
	if scene:
		scene = scene.instance()
	else:
		scene = OKModule.new()
		scene.set_script(script)
		scene.name = m_name
	
	if package:
		var package_script = package.new()
		var dict = package_script.package()
		scene.package_ready(dict)
	
	scene.assets_ready(assets)
	scene.scene_ready(main)
	
	_modules[m_name] = scene
	_content_paths.erase(m_name)
	_loading_modules.erase(m_name)
	emit_signal("module_loaded", scene)
	
	var thread = _active_threads.get(m_name)
	_release_thread(thread, m_name)


func _on_load_canceled(result: Dictionary):
	_on_load_progress(result.count)
	_release_thread(result.thread)


func _on_load_progress(count: int = 1):
	_load_progress -= count
	var norm = float(_load_progress) / float(_total_progress)
	var progress = (1.0 - norm) * 100.0
	
	if progress == 100.0:
		_load_progress = 0
		_total_progress = 0
	
	emit_signal("load_progress", progress)


# Private Methods


func _setup_load_progress(module: String):
	if _is_module_not_found(module) and !_content_paths.has(module):
		var root_path = App.package("modules_path") + module
		var paths = OKHelper.get_content_paths(root_path)
		
		if paths.empty(): 
			_incorrect_modules.append(module)
		else:
			_content_paths[module] = paths
			_total_progress += paths.size()
			_load_progress += paths.size()


func _preload_module(module: String, async: bool):
	if _is_module_not_found(module) and _content_paths.has(module):
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
			_waiting_modules.append(module)
		else:
			_active_threads[module] = thread
			thread.load_module(module, _content_paths[module])


func _await_module(module: String) -> OKModule:
	while true:
		yield(get_tree(), "idle_frame")
		
		if _modules.has(module):
			return _modules.get(module)
		elif _incorrect_modules.has(module):
			return null
		elif !_loading_modules.has(module):
			return null
	return null


func _await_modules(modules: Array) -> Dictionary:
	while true:
		yield(get_tree(), "idle_frame")
		
		var loaded_count = 0
		for module in modules:
			if _modules.has(module):
				loaded_count += 1
			elif _incorrect_modules.has(module):
				loaded_count += 1
			elif !_loading_modules.has(module):
				loaded_count += 1
		
		if loaded_count == modules.size():
			var result = {}
			for module in modules:
				if _modules.has(module):
					result[module] = _modules.get(module)
			return result
	return null


func _release_thread(thread: OKThread, module: String = ""):
	while(thread.is_active()):
		yield(get_tree(), "idle_frame")
	
	if _active_threads.has(module):
		_active_threads.erase(module)
	if _canceled_threads.has(thread):
		_canceled_threads.erase(thread)
	
	_finished_release_thread(thread)


func _finished_release_thread(thread: OKThread):
	if thread.get_meta("type") == "async":
		_async_threads.append(thread)
	elif thread.get_meta("type") == "sync" and !_waiting_modules.empty():
		_load_module(_waiting_modules.pop_front(), false)


func _unload_module(module: String):
	match is_module_loading(module):
		true: _cancel_load_module(module)
		false: _queue_free_module(module)
	
	emit_signal("module_unloaded", module)


func _cancel_load_module(module: String):
	var thread = _active_threads.get(module)
	_canceled_threads.append(thread)
	_active_threads.erase(module)
	_loading_modules.erase(module)
	_content_paths.erase(module)
	thread.cancel()


func _queue_free_module(module: String):
	if _modules.has(module):
		var scene = _modules.get(module)
		_modules.erase(module)
		scene.queue_free()


# Helpers


func _is_module_not_found(module: String) -> bool:
	return !_modules.has(module) and !_loading_modules.has(module)


func _get_async_thread() -> OKThread:
	if !_async_threads.empty(): 
		return _async_threads.pop_back()
	
	var thread = OKThread.new("async")
	thread.connect("module_loaded", self, "_on_module_loaded")
	thread.connect("load_progress", self, "_on_load_progress")
	thread.connect("load_canceled", self, "_on_load_canceled")
	return thread


func _get_sync_thread() -> OKThread:
	if _sync_thread: 
		return _sync_thread
	
	_sync_thread = OKThread.new("sync")
	_sync_thread.connect("module_loaded", self, "_on_module_loaded")
	_sync_thread.connect("load_progress", self, "_on_load_progress")
	_sync_thread.connect("load_canceled", self, "_on_load_canceled")
	return _sync_thread
