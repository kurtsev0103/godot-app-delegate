class_name OKThread extends Thread


signal module_loaded
signal load_progress


var _loader: OKLoader


func _init():
	_loader = OKLoader.new()
	_loader.connect("module_loaded", self, "_on_module_loaded")
	_loader.connect("load_progress", self, "_on_load_progress")


func load_module(module: String, async: bool):
	match async:
		true: start(_loader, "load_module_async", module, Thread.PRIORITY_HIGH)
		false: start(_loader, "load_module_sync", module, Thread.PRIORITY_HIGH)


# Signals


func _on_module_loaded(result: Dictionary):
	emit_signal("module_loaded", self, result)
	call_deferred("wait_to_finish")


func _on_load_progress():
	emit_signal("load_progress")
