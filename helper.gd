class_name OKHelper extends Reference


static func get_dir_contents(rootPath: String) -> Array:
	var dir = Directory.new()
	var directories = []
	var files = []
	
	if dir.open(rootPath) == OK:
		dir.list_dir_begin(true, false)
		_add_dir_contents(dir, files, directories)
	else:
		printerr("An error occurred when trying to access the path.")
	
	return files


static func _add_dir_contents(dir: Directory, files: Array, directories: Array):
	var file_name = dir.get_next()
	
	while (file_name != ""):
		if file_name[0] == ".": 
			file_name = dir.get_next()
			continue
		
		var path = dir.get_current_dir() + "/" + file_name
		
		if dir.current_is_dir():
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			directories.append(path)
			_add_dir_contents(subDir, files, directories)
		elif !(".import" in path):
			files.append(path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
