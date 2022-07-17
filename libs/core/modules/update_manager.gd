extends Node


var paths_to_check:Array = [
	".godot/imported/",
	"adapters/mirai/libs/",
	"adapters/mirai/plugin-libraries/",
	"adapters/mirai/plugins/",
	"libs/"
]

var files_to_check:Array = [
	".godot/uid_cache.bin",
	"project.godot"
]

var update_url:String = "https://raw.githubusercontent.com/Xwdit/RainyBot-Core/main/"


func _ready():
	if GlobalManager.is_running_from_editor():
		build_update_json("res://update.json")


func check_update()->bool:
	GuiManager.console_print_warning("正在检查您的RainyBot是否为最新版本，请稍候...")
	Console.disable_sysout(true)
	var result:HttpRequestResult = await Utils.send_http_get_request(update_url+"update.json")
	var dic:Dictionary = result.get_as_dic()
	Console.disable_sysout(false)
	if !dic.is_empty():
		var version:String = dic["version"]
		if RainyBotCore.VERSION.to_lower() != version.to_lower():
			if dic["need_full_update"]:
				var confirmed:bool = await Console.popup_confirm("发现RainyBot新版本! 最新版本为: %s, 您的当前版本为: %s\n此版本需要下载完整更新包，您想要更新吗?"%[version,RainyBotCore.VERSION])
				if confirmed:
					OS.shell_open("https://github.com/Xwdit/RainyBot-Core/releases")
			else:
				var confirmed:bool = await Console.popup_confirm("发现RainyBot新版本! 最新版本为: %s, 您的当前版本为: %s\n您想要进行自动增量热更新吗?"%[version,RainyBotCore.VERSION])
				if confirmed:
					await update_files(dic)
			return true
		GuiManager.console_print_success("版本检查完毕，您的RainyBot已为最新版本！")
		return true
	GuiManager.console_print_error("检查更新时出现错误，请检查网络连接是否正常")
	return false
	

func build_update_json(path:String):
	GuiManager.console_print_warning("正在生成升级统计文件，请稍候...")
	var file_ins:File = File.new()
	var dict:Dictionary = {"total_size":0}
	var root:String = GlobalManager.root_path
	for _path in paths_to_check:
		parse_path_dict(root+_path,dict)
	for _file in files_to_check:
		build_file_dict(root+_file,dict)
	dict["version"]=RainyBotCore.VERSION
	dict["need_full_update"]=RainyBotCore.NEED_FULL_UPDATE
	var json:JSON = JSON.new()
	var _text:String = json.stringify(dict)
	file_ins.open(path,File.WRITE)
	file_ins.store_line(_text)
	file_ins.close()
	GuiManager.console_print_success("成功生成升级统计文件 %s" % path)


func update_files(dict:Dictionary={}):
	GuiManager.console_print_warning("正在统计需要更新的文件，请稍候...")
	if dict.is_empty():
		var result:HttpRequestResult = await Utils.send_http_get_request(update_url+"update.json")
		dict = result.get_as_dic()
	var root:String = GlobalManager.root_path
	if !dict.is_empty():
		var result_dict:Dictionary = {"total_size":0,"removes":[],"adds":[],"updates":[]}
		for _path in paths_to_check:
			parse_path_dict(root+_path,dict,result_dict)
		for _file in files_to_check:
			check_file_update(root+_file,dict,result_dict)
		var args:Array = [format_bytes(result_dict["total_size"]),result_dict["updates"].size(),result_dict["adds"].size(),result_dict["removes"].size()]
		var confirm:bool = await Console.popup_confirm("本次更新需要下载 %s，将更新%s个文件，新增%s个文件，删除%s个文件\n确定要进行更新吗？"% args) 
		if confirm:
			var removed:int = 0
			var added:int = 0
			var updated:int = 0
			for f in result_dict["removes"]:
				var dir:Directory = Directory.new()
				if dir.file_exists(f):
					var err:int = dir.remove(f)
					if err==OK:
						removed+=1
			for f in result_dict["updates"]:
				var err:int = await download_file(f)
				if err==OK:
					updated+=1
			for f in result_dict["adds"]:
				var err:int = await download_file(f)
				if err==OK:
					added+=1


func format_bytes(bytes:int, decimals:int = 2)->String:
	if bytes == 0:
		return "0 Bytes"
	var k:int = 1024
	var dm:int = 0 if decimals < 0 else decimals
	var sizes:Array = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]

	var i:int = floor(log(bytes) / log(k))

	return (("%."+str(decimals)+"f") % (bytes / pow(k, i))) + " " + sizes[i]


func parse_path_dict(path:String,dict:Dictionary,update_dict:Dictionary={}):
	var dir:Directory = Directory.new()
	var error:int = dir.open(path)
	if error!=OK:
		print(path)
		return
		
	dir.list_dir_begin()

	while true:
		var file:String = dir.get_next()
		if file == "":
			break
		if dir.current_is_dir():
			parse_path_dict(path+file+"/",dict,update_dict)
			continue
		else:
			if update_dict.is_empty():
				build_file_dict(path+file,dict)
			else:
				check_file_update(path+file,dict,update_dict)
	dir.list_dir_end()


func build_file_dict(_f_path:String,dict:Dictionary):
	var _file:File = File.new()
	var _unique_path:String = _f_path.replace(GlobalManager.root_path,"")
	dict[_unique_path] = {}
	dict[_unique_path]["md5"] = _file.get_md5(_f_path)
	_file.open(_f_path,File.READ)
	dict[_unique_path]["size"] = _file.get_length()
	dict["total_size"] += _file.get_length()
	_file.close()


func check_file_update(_f_path:String,dict:Dictionary,result_dict:Dictionary):
	var _file:File = File.new()
	var _unique_path:String = _f_path.replace(GlobalManager.root_path,"")
	if dict.has(_unique_path):
		if _file.get_md5(_f_path) != dict[_unique_path]["md5"]:
			result_dict["updates"].append(_f_path)
			result_dict["total_size"]+=dict[_unique_path]["size"]
	else:
		result_dict["removes"].append(_f_path)


func check_new_files(dict:Dictionary,result_dict:Dictionary):
	var root_path:String = GlobalManager.root_path
	for f in dict:
		var _dir:Directory = Directory.new()
		if !_dir.file_exists(root_path+f):
			result_dict["adds"].append(root_path+f)
			result_dict["total_size"]+=dict[f]["size"]


func download_file(path:String):
	var _unique_path:String = path.replace(GlobalManager.root_path,"")
	var result:HttpRequestResult = await Utils.send_http_get_request("https://raw.githubusercontent.com/Xwdit/RainyBot-Core/main/"+_unique_path)
	var dir_path:String = (path).get_base_dir()+"/"
	var _dir:Directory = Directory.new()
	if !_dir.dir_exists(dir_path):
		_dir.make_dir_recursive(dir_path)
	result.save_to_file(path)
	return result
