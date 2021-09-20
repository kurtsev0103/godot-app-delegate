class_name OKThread extends Thread


signal module_loaded


var _loader: OKLoader


func _init():
	_loader = OKLoader.new()
	_loader.connect("module_loaded", self, "_module_loaded")


func load_module(module: String, async: bool):
	match async:
		true: start(_loader, "load_module_async", module, Thread.PRIORITY_HIGH)
		false: start(_loader, "load_module_sync", module, Thread.PRIORITY_HIGH)


func _module_loaded(result: Dictionary):
	emit_signal("module_loaded", self, result)
	call_deferred("wait_to_finish")
