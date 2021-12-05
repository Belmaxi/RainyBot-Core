extends Node


const INIT_PATH = [
	"/plugins/",
	"/config/",
	"/data/",
	"/logs/"
]


func _init():
	init_dir()


func _ready():
	get_tree().set_auto_accept_quit(false)
	add_to_group("console_command_stop")
	CommandManager.register_console_command("stop",false,["stop - 卸载所有插件并安全退出RainyBot进程"],"RainyBot-Core",false)


func init_dir():
	var dir = Directory.new()
	for p in INIT_PATH:
		var path = OS.get_executable_path().get_base_dir() + p
		if !dir.dir_exists(path):
			dir.make_dir(path)
			
			
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GuiManager.console_print_warning("正在安全退出RainyBot进程.....")
		await PluginManager.unload_plugins()
		BotAdapter.mirai_client.disconnect_to_mirai()
		await get_tree().create_timer(0.5).timeout
		GuiManager.console_print_success("RainyBot进程已被安全退出!")
		await get_tree().create_timer(0.5).timeout
		var _dir = Directory.new()
		_dir.open(OS.get_executable_path().get_base_dir() + "/logs/")
		_dir.copy("user://logs/rainybot.log",OS.get_executable_path().get_base_dir() + "/logs/rainybot_"+Time.get_datetime_string_from_system().replace("T","_").replace(":",".")+".log")
		get_tree().quit()


func _call_console_command(_cmd:String,_args:Array):
	notification(NOTIFICATION_WM_CLOSE_REQUEST)
