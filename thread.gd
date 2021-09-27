class_name OKThread extends Thread


signal module_loaded
signal load_progress

var _mutex: Mutex


# Initialization


func _init(type: String):
	set_meta("type", type)
	_mutex = Mutex.new()


# Public Methods


func load_module(module: String, paths: Array):
	var userdata = {"module": module, "paths": paths}
	start(self, "_load_module", userdata, Thread.PRIORITY_HIGH)


func load_content(path: String) -> Resource:
	return ResourceLoader.load(path)


# Private Method


func _load_module(userdata: Dictionary):
	var assets = {}
	
	for path in userdata.paths:
		var resource = ResourceLoader.load(path)
		
		_mutex.lock()
		call_deferred("emit_signal", "load_progress")
		_mutex.unlock()
		
		match resource == null:
			true: printerr("Unable to load content")
			false: assets[path] = resource
	
	var result = {"name": userdata.module, "assets": assets}
	
	_mutex.lock()
	call_deferred("emit_signal", "module_loaded", result)
	call_deferred("wait_to_finish")
	_mutex.unlock()
