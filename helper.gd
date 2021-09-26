class_name OKHelper extends Reference


static func get_content_paths(rootPath: String) -> Array:
	var dir_queue = [rootPath]
	var content_paths = []
	var current_dir: Directory
	var current_file: String
	
	while current_file or not dir_queue.empty():
		if current_file:
			if current_dir.current_is_dir():
				var path = "%s/%s" % [current_dir.get_current_dir(), current_file]
				dir_queue.append(path)
			
			elif !current_file.begins_with(".") and !current_file.ends_with(".remap"):
				var path = "%s/%s" % [current_dir.get_current_dir(), current_file]
				
				if path.ends_with(".import"):
					path = path.replace(".import", "")
				if !content_paths.has(path):
					content_paths.append(path)
			
		else:
			if current_dir:
				current_dir.list_dir_end()
			if dir_queue.empty():
				break
			
			current_dir = Directory.new()
			var path = dir_queue.pop_front()
			
			if current_dir.open(path) == OK:
				current_dir.list_dir_begin(true, true)
			else:
				var name = path.substr(path.find_last("/") + 1)
				printerr("Unknown module: %s" % name)
				return content_paths
		
		current_file = current_dir.get_next()
	
	return content_paths
