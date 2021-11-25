extends Node


var message_type_dic:Dictionary = {
	int(Message.Type.SOURCE):"Source",
	int(Message.Type.QUOTE):"Quote",
	int(Message.Type.AT):"At",
	int(Message.Type.AT_ALL):"AtAll",
	int(Message.Type.FACE):"Face",
	int(Message.Type.TEXT):"Plain",
	int(Message.Type.IMAGE):"Image",
	int(Message.Type.FLASH_IMAGE):"FlashImage",
	int(Message.Type.VOICE):"Voice",
	int(Message.Type.XML):"Xml",
	int(Message.Type.JSON_MSG):"Json",
	int(Message.Type.APP):"App",
	int(Message.Type.POKE):"Poke",
	int(Message.Type.DICE):"Dice",
	int(Message.Type.MUSIC_SHARE):"MusicShare",
	int(Message.Type.FORWARD_MESSAGE):"ForwardMessage",
	int(Message.Type.FILE):"File",
	int(Message.Type.BOT_CODE):"MiraiCode"
}

var action_event_dic:Dictionary = {
	int(ActionEvent.Type.NUDGE):"NudgeEvent"
}

var bot_event_dic:Dictionary = {
	int(BotEvent.Type.ONLINE):"BotOnlineEvent",
	int(BotEvent.Type.OFFLINE):["BotOfflineEventActive","BotOfflineEventForce","BotOfflineEventDropped"],
	int(BotEvent.Type.RELOGIN):"BotReloginEvent",
}

var friend_event_dic:Dictionary = {
	int(FriendEvent.Type.INPUT_STATUS_CHANGE):"FriendInputStatusChangedEvent",
	int(FriendEvent.Type.NICK_CHANGE):"FriendNickChangedEvent",
	int(FriendEvent.Type.RECALL):"FriendRecallEvent"
}

var group_event_dic:Dictionary = {
	int(GroupEvent.Type.BOT_PERM_CHANGE):"BotGroupPermissionChangeEvent",
	int(GroupEvent.Type.BOT_MUTE):"BotMuteEvent",
	int(GroupEvent.Type.BOT_UNMUTE):"BotUnmuteEvent",
	int(GroupEvent.Type.BOT_JOIN):"BotJoinGroupEvent",
	int(GroupEvent.Type.BOT_LEAVE):["BotLeaveEventActive","BotLeaveEventKick"],
	int(GroupEvent.Type.RECALL):"GroupRecallEvent",
	int(GroupEvent.Type.NAME_CHANGE):"GroupNameChangeEvent",
	int(GroupEvent.Type.ANNOUNCE_CHANGE):"GroupEntranceAnnouncementChangeEvent",
	int(GroupEvent.Type.MUTE_ALL):"GroupMuteAllEvent",
	int(GroupEvent.Type.ALLOW_ANONY_CHAT):"GroupAllowAnonymousChatEvent",
	int(GroupEvent.Type.ALLOW_CONFESS_TALK):"GroupAllowConfessTalkEvent",
	int(GroupEvent.Type.ALLOW_INVITE):"GroupAllowMemberInviteEvent",
	int(GroupEvent.Type.MEMBER_JOIN):"MemberJoinEvent",
	int(GroupEvent.Type.MEMBER_LEAVE):["MemberLeaveEventKick","MemberLeaveEventQuit"],
	int(GroupEvent.Type.MEMBER_MUTE):"MemberMuteEvent",
	int(GroupEvent.Type.MEMBER_UNMUTE):"MemberUnmuteEvent",
	int(GroupEvent.Type.MEMBER_HONOR_CHANGE):"MemberHonorChangeEvent",
	int(GroupEvent.Type.MEMBER_NAME_CHANGE):"MemberCardChangeEvent",
	int(GroupEvent.Type.MEMBER_PERM_CHANGE):"MemberPermissionChangeEvent",
	int(GroupEvent.Type.MEMBER_TITLE_CHANGE):"MemberSpecialTitleChangeEvent"
}

var message_event_dic:Dictionary = {
	int(MessageEvent.Type.FRIEND):"FriendMessage",
	int(MessageEvent.Type.GROUP):"GroupMessage",
	int(MessageEvent.Type.TEMP):"TempMessage",
	int(MessageEvent.Type.STRANGER):"StrangerMessage",
	int(MessageEvent.Type.OTHER_CLIENT):"OtherClientMessage"
}

var request_event_dic:Dictionary = {
	int(RequestEvent.Type.NEW_FRIEND):"NewFriendRequestEvent",
	int(RequestEvent.Type.MEMBER_JOIN):"MemberJoinRequestEvent",
	int(RequestEvent.Type.GROUP_INVITE):"BotInvitedJoinGroupRequestEvent"
}

var other_client_event_dic:Dictionary = {
	int(OtherClientEvent.Type.ONLINE):"OtherClientOnlineEvent",
	int(OtherClientEvent.Type.OFFLINE):"OtherClientOfflineEvent"
}

var event_category_dic:Dictionary = {
	int(Event.Category.ACTION):action_event_dic,
	int(Event.Category.BOT):bot_event_dic,
	int(Event.Category.FRIEND):friend_event_dic,
	int(Event.Category.GROUP):group_event_dic,
	int(Event.Category.MESSAGE):message_event_dic,
	int(Event.Category.OTHER_CLIENT):other_client_event_dic,
	int(Event.Category.REQUEST):request_event_dic
}

var mirai_client:= MiraiClient.new()
var mirai_config_manager:=MiraiAdapterConfig.new()
var mirai_loader:=MiraiLoader.new()


func init():
	GuiManager.console_print_warning("正在加载内置模块: Mirai-Adapter | 版本:V2.0-Pre-Alpha-2 | 作者:Xwdit")
	add_to_group("console_command_mirai")
	var usages = [
		"mirai status - 获取与Mirai框架的连接状态",
		"mirai restart - 在Mirai主进程被关闭后重新启动Mirai框架",
		"mirai command <命令> - 向Mirai框架发送命令并显示回调(不支持额外参数)",
	]
	CommandManager.register_console_command("mirai",true,usages,"Mirai-Adapter",false)
	mirai_config_manager.connect("config_loaded",Callable(self,"_mirai_config_loaded"))
	mirai_config_manager.name = "MiraiAdapterConfig"
	mirai_client.name = "MiraiClient"
	mirai_loader.name = "MiraiLoader"
	add_child(mirai_config_manager,true)
	add_child(mirai_client,true)
	add_child(mirai_loader,true)
	mirai_config_manager.init_config()


func _mirai_config_loaded():
	mirai_client.connect_to_mirai(get_ws_url())


func _call_console_command(cmd:String,args:Array):
	match args[0]:
		"status":
			GuiManager.console_print_text("当前连接状态:"+str(is_bot_connected()))
			GuiManager.console_print_text("连接地址:"+get_ws_url())
		"restart":
			mirai_loader.load_mirai()
		"command":
			if args.size() > 1:
				var result = await send_bot_request(args[1])
				GuiManager.console_print_text("收到回调: "+str(result))


func get_ws_url()->String:
	return mirai_config_manager.get_ws_address(mirai_config_manager.loaded_config)


func is_bot_connected()->bool:
	return mirai_client.is_bot_connected()


func get_bot_id()->int:
	return mirai_config_manager.get_bot_id()
	
	
func send_bot_request(_command,_sub_command=null,_content={},_timeout:float=20.0):
	return await mirai_client.send_bot_request(_command,_sub_command,_content,_timeout)
			
			
func parse_permission_text(perm:String)->int:
	match perm:
		"ADMINISTRATOR":
			return GroupMember.Permission.ADMINISTRATOR
		"OWNER":
			return GroupMember.Permission.OWNER
	return GroupMember.Permission.MEMBER
			
			
func parse_message_dic(dic:Dictionary)->Message:
	if !dic.has("type"):
		return null
	match dic.type:
		"Source":
			return SourceMessage.init_meta(dic)
		"Quote":
			return QuoteMessage.init_meta(dic)
		"At":
			return AtMessage.init_meta(dic)
		"AtAll":
			return AtAllMessage.init_meta(dic)
		"Face":
			return FaceMessage.init_meta(dic)
		"Plain":
			return TextMessage.init_meta(dic)
		"Image":
			return ImageMessage.init_meta(dic)
		"FlashImage":
			return FlashImageMessage.init_meta(dic)
		"Voice":
			return VoiceMessage.init_meta(dic)
		"Xml":
			return XmlMessage.init_meta(dic)
		"Json":
			return JsonMessage.init_meta(dic)
		"App":
			return AppMessage.init_meta(dic)
		"Poke":
			return PokeMessage.init_meta(dic)
		"Dice":
			return DiceMessage.init_meta(dic)
		"MusicShare":
			return MusicShareMessage.init_meta(dic)
		"ForwardMessage":
			return ForwardMessage.init_meta(dic)
		"File":
			return FileMessage.init_meta(dic)
		"MiraiCode":
			return BotCodeMessage.init_meta(dic)
	return null


func parse_event(result_dic:Dictionary):
	var ins:Event
	var event_dic = result_dic["data"]
	var event_name:String = event_dic["type"]
	match event_name:
		"FriendMessage":
			ins = FriendMessageEvent.init_meta(event_dic)
		"GroupMessage":
			ins = GroupMessageEvent.init_meta(event_dic)
		"TempMessage":
			ins = TempMessageEvent.init_meta(event_dic)
		"StrangerMessage":
			ins = StrangerMessageEvent.init_meta(event_dic)
		"OtherClientMessage":
			ins = OtherClientMessageEvent.init_meta(event_dic)
		"NudgeEvent":
			ins = NudgeEvent.init_meta(event_dic)
		"BotOnlineEvent":
			ins = BotOnlineEvent.init_meta(event_dic)
		"BotOfflineEventActive":
			ins = BotOfflineEvent.init_meta(event_dic,BotOfflineEvent.ReasonType.ACTIVE)
		"BotOfflineEventForce":
			ins = BotOfflineEvent.init_meta(event_dic,BotOfflineEvent.ReasonType.FORCE)
		"BotOfflineEventDropped":
			ins = BotOfflineEvent.init_meta(event_dic,BotOfflineEvent.ReasonType.DROPPED)
		"BotReloginEvent":
			ins = BotReloginEvent.init_meta(event_dic)
		"FriendInputStatusChangedEvent":
			ins = FriendInputStatusChangeEvent.init_meta(event_dic)
		"FriendNickChangedEvent":
			ins = FriendNickChangeEvent.init_meta(event_dic)
		"FriendRecallEvent":
			ins = FriendRecallEvent.init_meta(event_dic)
		"BotGroupPermissionChangeEvent":
			ins = BotPermChangeEvent.init_meta(event_dic)
		"BotMuteEvent":
			ins = BotMuteEvent.init_meta(event_dic)
		"BotUnmuteEvent":
			ins = BotUnmuteEvent.init_meta(event_dic)
		"BotJoinGroupEvent":
			ins = BotJoinGroupEvent.init_meta(event_dic)
		"BotLeaveEventActive":
			ins = BotLeaveGroupEvent.init_meta(event_dic,BotLeaveGroupEvent.ReasonType.ACTIVE)
		"BotLeaveEventKick":
			ins = BotLeaveGroupEvent.init_meta(event_dic,BotLeaveGroupEvent.ReasonType.KICK)
		"GroupRecallEvent":
			ins = GroupRecallEvent.init_meta(event_dic)
		"GroupNameChangeEvent":
			ins = GroupNameChangeEvent.init_meta(event_dic)
		"GroupEntranceAnnouncementChangeEvent":
			ins = GroupAnnounceChangeEvent.init_meta(event_dic)
		"GroupMuteAllEvent":
			ins = GroupMuteAllEvent.init_meta(event_dic)
		"GroupAllowAnonymousChatEvent":
			ins = GroupAllowAnonyChatEvent.init_meta(event_dic)
		"GroupAllowConfessTalkEvent":
			ins = GroupAllowConfessTalkEvent.init_meta(event_dic)
		"GroupAllowMemberInviteEvent":
			ins = GroupAllowInviteEvent.init_meta(event_dic)
		"MemberJoinEvent":
			ins = MemberJoinEvent.init_meta(event_dic)
		"MemberLeaveEventKick":
			ins = MemberLeaveEvent.init_meta(event_dic,MemberLeaveEvent.ReasonType.KICK)
		"MemberLeaveEventQuit":
			ins = MemberLeaveEvent.init_meta(event_dic,MemberLeaveEvent.ReasonType.QUIT)
		"MemberMuteEvent":
			ins = MemberMuteEvent.init_meta(event_dic)
		"MemberUnmuteEvent":
			ins = MemberUnmuteEvent.init_meta(event_dic)
		"MemberHonorChangeEvent":
			ins = MemberHonorChangeEvent.init_meta(event_dic)
		"MemberCardChangeEvent":
			ins = MemberNameChangeEvent.init_meta(event_dic)
		"MemberPermissionChangeEvent":
			ins = MemberPermChangeEvent.init_meta(event_dic)
		"MemberSpecialTitleChangeEvent":
			ins = MemberTitleChangeEvent.init_meta(event_dic)
		"NewFriendRequestEvent":
			ins = NewFriendRequestEvent.init_meta(event_dic)
		"MemberJoinRequestEvent":
			ins = MemberJoinRequestEvent.init_meta(event_dic)
		"BotInvitedJoinGroupRequestEvent":
			ins = GroupInviteRequestEvent.init_meta(event_dic)
		"OtherClientOnlineEvent":
			ins = OtherClientOnlineEvent.init_meta(event_dic)
		"OtherClientOfflineEvent":
			ins = OtherClientOfflineEvent.init_meta(event_dic)
		_:
			return
	get_tree().call_group(event_name,"_call_event",event_name,ins)
