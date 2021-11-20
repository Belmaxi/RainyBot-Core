extends Control


class_name PluginEditor


var loaded_path:String = ""
var loaded_name:String = ""
var unsaved:bool = false


func load_script(path:String)->int:
	var scr:GDScript = ResourceLoader.load(path,"GDScript",2)
	set_unsaved(false)
	if is_instance_valid(scr):
		get_code_edit().text = scr.source_code
		$EditorPanel/File/FileName.text = path.get_file()
		loaded_path = path
		loaded_name = path.get_file()
		return OK
	else:
		GuiManager.console_print_error("插件文件加载时出现错误，请检查文件权限是否正确")
		return ERR_CANT_OPEN
	

func get_code_edit()->CodeEdit:
	return get_node("CodeEdit")


func save_script(reload:bool=false)->int:
	var scr:GDScript = GDScript.new()
	scr.source_code = get_code_edit().text
	var err_code = ResourceSaver.save(loaded_path,scr)
	if err_code == OK:
		set_unsaved(false)
		GuiManager.console_print_success("插件保存成功！")
		if reload:
			var plug = PluginManager.get_plugin_with_filename(loaded_name)
			await get_tree().process_frame
			if is_instance_valid(plug):
				PluginManager.reload_plugin(plug)
				return err_code
			PluginManager.load_plugin(loaded_name)
		else:
			GuiManager.console_print_success("请不要忘记重载插件以使更改生效!")	
	else:
		GuiManager.console_print_error("插件文件保存时出现错误，请检查文件权限是否正确")
	return err_code


func set_unsaved(enabled:bool=true):
	unsaved = enabled
	if unsaved:
		$EditorPanel/File/FileStatus.text = "(未保存)"
	else:
		$EditorPanel/File/FileStatus.text = ""


func _on_CodeEdit_text_changed():
	set_unsaved()


func _on_CodeEdit_caret_changed():
	$EditorPanel/Edit/EditStatus.text = str(get_code_edit().get_caret_line()+1)+" : "+str(get_code_edit().get_caret_column()+1)


func _on_SaveButton_button_down():
	save_script(true)


func _on_HelpButton_button_down():
	OS.shell_open("https://github.com/Xwdit/RainyBot-API")
