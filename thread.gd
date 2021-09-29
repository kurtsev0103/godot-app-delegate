class_name OKThread extends Thread


signal module_loaded
signal load_progress
signal load_canceled

var _mutex: Mutex

var _load_counter: int
var _is_cancelled: bool


# Initialization


func _init(type: String):
	set_meta("type", type)
	_mutex = Mutex.new()


# Public Methods


func load_module(module: String, paths: Array):
	var userdata = {"module": module, "paths": paths}
	start(self, "_load_module", userdata, Thread.PRIORITY_HIGH)


func load_content(path: String) -> Resource:
	var resource = ResourceLoader.load(path)
	if resource == null: 
		printerr("Unable to load content")
	return resource


func cancel():
	_is_cancelled = true

# Private Method


func _load_module(userdata: Dictionary):
	_is_cancelled = false
	_load_counter = 0
	var assets = {}
	
	for path in userdata.paths:
		if _is_cancelled:
			_emit_cancel(userdata)
			return
		
		var resource = ResourceLoader.load(path)
		_emit_progress()
		
		match resource == null:
			true: printerr("Unable to load content")
			false: assets[path] = resource
	
	_emit_loaded(userdata.module, assets)


# Emit Signals


func _emit_loaded(module: String, assets: Dictionary):
	var result = {"name": module, "assets": assets}
	
	_mutex.lock()
	call_deferred("emit_signal", "module_loaded", result)
	call_deferred("wait_to_finish")
	_mutex.unlock()


func _emit_progress():
	_mutex.lock()
	_load_counter += 1
	call_deferred("emit_signal", "load_progress")
	_mutex.unlock()


func _emit_cancel(userdata: Dictionary):
	var paths_count = userdata.paths.size()
	var count = (paths_count - _load_counter)
	var result = {"thread": self, "count": count}
	
	_mutex.lock()
	call_deferred("emit_signal", "load_canceled", result)
	call_deferred("wait_to_finish")
	_mutex.unlock()
