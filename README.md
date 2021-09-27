# app-delegate
Simple, modular, reactive. 
> Currently in the process of creating

## Description

The "App" class manages your app’s shared behaviors. It is effectively the root object of your app, and it works to manage some interactions with the system. Use your "App" class to handle the following tasks:
- Load resources and modules of your application. (Sync/Async depending on your needs)
- Responding to signals, such as loading process, completion of loading, and others.

## Installation

1. [Download AppDelegate](https://github.com/kurtsev0103/godot-app-delegate/archive/refs/heads/main.zip), unzip and copy files to your Godot project's ```res://addons/app_delegate``` directory.

2. You must add the ```app.gd``` script to the ```AutoLoad``` (as in the example below). To do this, select Project > Project Settings and switch to the AutoLoad tab.
	<img width="894" alt="img" src="https://user-images.githubusercontent.com/27446881/134975753-30594561-42e2-4097-a59d-36fb26c9d92d.png">

3. Create a ```package.gd``` file in the root directory following the example below and specify the path to the folder with your modules.
```gdscript
extends Reference

func package():
	return {
		"name": "APP_NAME",
		"version": "0.0.0",
		
		"modules_path": "res://modules/"
	}
```

## Samples and Example Usage

### Creating a module

1. In the ```modules``` folder, create a folder with the name of the new module.
	> For example, let's create the "menu" module.
	<img width="178" alt="1" src="https://user-images.githubusercontent.com/27446881/134774017-82c35f23-9091-456d-9156-63b7bd000280.png">

	- ```assets``` folder is used to store the various resources (image/audio, etc.) related to this module.
	- ```menu.tscn``` is the scene that has ```CanvasLayer``` as its root node.
	- ```menu.gd``` is a script linked to the root node.
	- ```package.gd``` is a script that contains important information/constants related to this module.

2. Extend ```menu.gd``` from the ```OKModule``` class.

	<img width="248" alt="2" src="https://user-images.githubusercontent.com/27446881/134774019-1899e381-5790-4c9d-b84a-7450cd5a6760.png">

3. Fill ```package.gd``` with the default initial information.

	<img width="252" alt="3" src="https://user-images.githubusercontent.com/27446881/134774018-436f3438-de3b-4b8c-8f56-641d5ef94017.png">

### Loading modules

> Loads and caches module/s and all its/their resources:
```gdscript
# Asynchronous loading of 1 module
App.load_module("menu")

# Synchronous loading of 1 module
App.load_module("menu", false)

# Asynchronous loading of several modules
App.load_modules(["menu", "player", "game"])

# Synchronous loading of several modules
App.load_modules(["menu", "player", "game"], false)
```

> Loading with pending completion:
```gdscript
# Asynchronous loading of 1 module
yield(App.await_module("menu"), "completed")
print("The menu module is loaded and ready.")

# Synchronous loading of 1 module
yield(App.await_module("menu", false), "completed")
print("The menu module is loaded and ready.")

# Asynchronous loading of several modules
yield(App.await_modules(["menu", "player", "game"]), "completed")
print("All modules is loaded and ready.")

# Synchronous loading of several modules
yield(App.await_modules(["menu", "player", "game"], false), "completed")
print("All modules is loaded and ready.")
```

> - The "await_module" method also returns the module itself that you are waiting for.
> - The "await_modules" method also returns the array of modules you are waiting for.
> - You can take advantage of this in the following way:
```gdscript
# On the example of async loading 1 module
var menu = yield(App.await_module("menu"), "completed")
menu.some_method()

# On the example of async loading with several modules
var modules = yield(App.await_modules(["menu", "player", "game"]), "completed")
modules.menu.some_method()
modules.player.some_method()
modules.game.some_method()
```

### Unloading modules
> Unloading module/s and all its/their resources:
```gdscript
# Unloading of 1 module
App.unload_module("menu")

# Unloading of several modules
App.unload_modules(["menu", "player", "game"])
```

> Unloading with pending completion:
```gdscript
# Unloading of 1 module
yield(App.unload_module("menu"), "completed")
print("The menu module is completely unloaded.")

# Unloading of several modules
yield(App.unload_modules(["menu", "player", "game"]), "completed")
print("All modules is completely unloaded.")
```

### Tracking the progress of loading

```gdscript
func _ready():
	App.connect("load_progress", self, "_on_load_progress")

func _on_load_progress(value: float):
	print(value) # from 0.0 to 100.0
```

### Accessing modules and resources

> Check if the module is loaded:
```gdscript
if App.has_module("menu"):
	print("The module is loaded")
else:
	print("Module is not loaded")
```

> Calling methods (Module must be loaded):
```gdscript
# Inside the module
some_method()

# From outside the module
App.module("menu").some_method()
```

> Getting data from ```package.gd``` (Module must be loaded):
```gdscript
# Inside the module
var version = package("version")

# From outside the module
var version = App.module("menu").package("version")
```

> Getting module resources (Module must be loaded):
```gdscript
# Inside the module
var img1: StreamTexture = asset("some_image.png") # assets/ folder
var img2: StreamTexture = asset("main/some_image.png") # assets/main/ folder
var array: Array = assets("main") # all resources in assets/main/ folder

# From outside the module
var img1: StreamTexture = App.module("menu").asset("some_image.png") # assets/ folder
var img2: StreamTexture = App.module("menu").asset("main/some_image.png") # assets/main/ folder
var array: Array = App.module("menu").assets("main") # all resources in assets/main/ folder
```


## Created by Oleksandr Kurtsev (Copyright © 2021) [LICENSE](https://github.com/kurtsev0103/godot-app-delegate/blob/main/LICENSE)
