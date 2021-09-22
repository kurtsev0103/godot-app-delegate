class_name OKThread extends Thread


signal module_loaded
signal load_progress

var _mutex: Mutex
var _loader: OKLoader


func _init(type: String):
	set_meta("type", type)
	
	_mutex = Mutex.new()
	_loader = OKLoader.new()
	_loader.connect("module_loaded", self, "_on_module_loaded")
	_loader.connect("load_progress", self, "_on_load_progress")


func load_module(module: String, paths: Array):
	if get_meta("type") == "sync": 
		_mutex.lock()
	
	var userdata = {"module": module, "paths": paths}
	start(_loader, "load_module", userdata, Thread.PRIORITY_HIGH)


# Signals


func _on_module_loaded(result: Dictionary):
	call_deferred("emit_signal", "module_loaded", result)
	call_deferred("wait_to_finish")
	
	if get_meta("type") == "sync": 
		_mutex.unlock()


func _on_load_progress():
	_mutex.lock()
	call_deferred("emit_signal", "load_progress")
	_mutex.unlock()
