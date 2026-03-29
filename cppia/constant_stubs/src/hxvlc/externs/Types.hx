package hxvlc.externs;

class Types {}

typedef LibVLC_Instance_T = Dynamic;

typedef LibVLC_Time_T = Dynamic;

typedef LibVLC_Media_T = Dynamic;

typedef LibVLC_Media_List_T = Dynamic;

typedef LibVLC_Media_Player_T = Dynamic;

typedef LibVLC_Event_Manager_T = Dynamic;

typedef LibVLC_Log_T = Dynamic;

typedef LibVLC_Media_Stats_T = Dynamic;

typedef LibVLC_Audio_Track_T = Dynamic;

typedef LibVLC_Video_Track_T = Dynamic;

typedef LibVLC_Subtitle_Track_T = Dynamic;

typedef LibVLC_Media_Track_T = Dynamic;

typedef LibVLC_Track_Description_T = Dynamic;

typedef LibVLC_Event_T = Dynamic;

typedef LibVLC_Callback_T = Dynamic;

typedef LibVLC_Log_CB = Dynamic;

typedef LibVLC_Media_Open_CB = Dynamic;

typedef LibVLC_Media_Read_CB = Dynamic;

typedef LibVLC_Media_Seek_CB = Dynamic;

typedef LibVLC_Media_Close_CB = Dynamic;

typedef LibVLC_Video_Format_CB = Dynamic;

typedef LibVLC_Video_Cleanup_CB = Dynamic;

typedef LibVLC_Video_Lock_CB = Dynamic;

typedef LibVLC_Video_Unlock_CB = Dynamic;

typedef LibVLC_Video_Display_CB = Dynamic;

typedef LibVLC_Audio_Play_CB = Dynamic;

typedef LibVLC_Audio_Pause_CB = Dynamic;

typedef LibVLC_Audio_Resume_CB = Dynamic;

typedef LibVLC_Audio_Flush_CB = Dynamic;

typedef LibVLC_Audio_Drain_CB = Dynamic;

typedef LibVLC_Audio_Setup_CB = Dynamic;

typedef LibVLC_Audio_Cleanup_CB = Dynamic;

typedef LibVLC_Audio_Set_Volume_CB = Dynamic;

enum abstract LibVLC_Meta_T(Int)
{
	var LibVLC_Meta_Title        = 0;
	var LibVLC_Meta_Artist       = 1;
	var LibVLC_Meta_Genre        = 2;
	var LibVLC_Meta_Copyright    = 3;
	var LibVLC_Meta_Album        = 4;
	var LibVLC_Meta_TrackNumber  = 5;
	var LibVLC_Meta_Description  = 6;
	var LibVLC_Meta_Rating       = 7;
	var LibVLC_Meta_Date         = 8;
	var LibVLC_Meta_Setting      = 9;
	var LibVLC_Meta_URL          = 10;
	var LibVLC_Meta_Language     = 11;
	var LibVLC_Meta_NowPlaying   = 12;
	var LibVLC_Meta_Publisher    = 13;
	var LibVLC_Meta_EncodedBy    = 14;
	var LibVLC_Meta_ArtworkURL   = 15;
	var LibVLC_Meta_TrackID      = 16;
	var LibVLC_Meta_TrackTotal   = 17;
	var LibVLC_Meta_Director     = 18;
	var LibVLC_Meta_Season       = 19;
	var LibVLC_Meta_Episode      = 20;
	var LibVLC_Meta_ShowName     = 21;
	var LibVLC_Meta_Actors       = 22;
	var LibVLC_Meta_AlbumArtist  = 23;
	var LibVLC_Meta_DiscNumber   = 24;
	var LibVLC_Meta_DiscTotal    = 25;

	@:from public static inline function fromInt(i:Int):LibVLC_Meta_T return cast i;
	
	@:to public inline function toInt():Int return cast this;
}

enum abstract LibVLC_Track_Type(Int)
{
	var LibVLC_Track_Unknown = -1;
	var LibVLC_Track_Audio   = 0;
	var LibVLC_Track_Video   = 1;
	var LibVLC_Track_Text    = 2;

	@:from public static inline function fromInt(i:Int):LibVLC_Track_Type return cast i;
	
	@:to public inline function toInt():Int return cast this;
}

enum abstract LibVLC_Video_Orient(Int)
{
	var LibVLC_Video_Orient_Top_Left     = 0;
	var LibVLC_Video_Orient_Top_Right    = 1;
	var LibVLC_Video_Orient_Bottom_Left  = 2;
	var LibVLC_Video_Orient_Bottom_Right = 3;
	var LibVLC_Video_Orient_Left_Top     = 4;
	var LibVLC_Video_Orient_Left_Bottom  = 5;
	var LibVLC_Video_Orient_Right_Top    = 6;
	var LibVLC_Video_Orient_Right_Bottom = 7;

	@:from public static inline function fromInt(i:Int):LibVLC_Video_Orient return cast i;

	@:to public inline function toInt():Int return cast this;
}

enum abstract LibVLC_Media_Parse_Flag_T(Int)
{
	var LibVLC_Media_Parse_Local    = 0;
	var LibVLC_Media_Parse_Network  = 1;
	var LibVLC_Media_Fetch_Local    = 2;
	var LibVLC_Media_Fetch_Network  = 4;
	var LibVLC_Media_Do_Interact    = 8;

	@:from public static inline function fromInt(i:Int):LibVLC_Media_Parse_Flag_T return cast i;
	
	@:to public inline function toInt():Int return cast this;
}

enum abstract LibVLC_Media_Slave_Type_T(Int)
{
	var LibVLC_Media_Slave_Type_Subtitle = 0;
	var LibVLC_Media_Slave_Type_Audio    = 1;
	@:from public static inline function fromInt(i:Int):LibVLC_Media_Slave_Type_T return cast i;

	@:to public inline function toInt():Int return cast this;
}

enum abstract LibVLC_Media_Parsed_Status_T(Int)
{
	var LibVLC_Media_Parsed_Status_Skipped = 1;
	var LibVLC_Media_Parsed_Status_Failed  = 2;
	var LibVLC_Media_Parsed_Status_Timeout = 3;
	var LibVLC_Media_Parsed_Status_Done    = 4;

	@:from public static inline function fromInt(i:Int):LibVLC_Media_Parsed_Status_T return cast i;

	@:to public inline function toInt():Int return cast this;
}
enum abstract LibVLC_Media_Player_Role_T(Int)
{
	var LibVLC_Role_None          = 0;
	var LibVLC_Role_Music         = 1;
	var LibVLC_Role_Video         = 2;
	var LibVLC_Role_Communication = 3;
	var LibVLC_Role_Game          = 4;
	var LibVLC_Role_Notification  = 5;
	var LibVLC_Role_Animation     = 6;
	var LibVLC_Role_Production    = 7;
	var LibVLC_Role_Accessibility = 8;
	var LibVLC_Role_Test          = 9;
	var LibVLC_Role_Last          = 10;

	@:from public static inline function fromInt(i:Int):LibVLC_Media_Player_Role_T return cast i;

	@:to public inline function toInt():Int return cast this;
}

enum abstract LibVLC_Event_E(Int)
{
	var LibVLC_MediaMetaChanged               = 0;
	var LibVLC_MediaSubItemAdded              = 1;
	var LibVLC_MediaDurationChanged           = 2;
	var LibVLC_MediaParsedChanged             = 3;
	var LibVLC_MediaFreed                     = 4;
	var LibVLC_MediaStateChanged              = 5;
	var LibVLC_MediaSubItemTreeAdded          = 6;
	var LibVLC_MediaPlayerMediaChanged        = 256;
	var LibVLC_MediaPlayerNothingSpecial      = 257;
	var LibVLC_MediaPlayerOpening             = 258;
	var LibVLC_MediaPlayerBuffering           = 259;
	var LibVLC_MediaPlayerPlaying             = 260;
	var LibVLC_MediaPlayerPaused              = 261;
	var LibVLC_MediaPlayerStopped             = 262;
	var LibVLC_MediaPlayerForward             = 263;
	var LibVLC_MediaPlayerBackward            = 264;
	var LibVLC_MediaPlayerEndReached          = 265;
	var LibVLC_MediaPlayerEncounteredError    = 266;
	var LibVLC_MediaPlayerTimeChanged         = 267;
	var LibVLC_MediaPlayerPositionChanged     = 268;
	var LibVLC_MediaPlayerSeekableChanged     = 269;
	var LibVLC_MediaPlayerPausableChanged     = 270;
	var LibVLC_MediaPlayerTitleChanged        = 271;
	var LibVLC_MediaPlayerSnapshotTaken       = 272;
	var LibVLC_MediaPlayerLengthChanged       = 273;
	var LibVLC_MediaPlayerVout                = 274;
	var LibVLC_MediaPlayerScrambledChanged    = 275;
	var LibVLC_MediaPlayerESAdded             = 276;
	var LibVLC_MediaPlayerESDeleted           = 277;
	var LibVLC_MediaPlayerESSelected          = 278;
	var LibVLC_MediaPlayerCorked              = 279;
	var LibVLC_MediaPlayerUncorked            = 280;
	var LibVLC_MediaPlayerMuted               = 281;
	var LibVLC_MediaPlayerUnmuted             = 282;
	var LibVLC_MediaPlayerAudioVolume         = 283;
	var LibVLC_MediaPlayerAudioDevice         = 284;
	var LibVLC_MediaPlayerChapterChanged      = 285;
	var LibVLC_MediaListItemAdded             = 512;
	var LibVLC_MediaListWillAddItem           = 513;
	var LibVLC_MediaListItemDeleted           = 514;
	var LibVLC_MediaListWillDeleteItem        = 515;
	var LibVLC_MediaListEndReached            = 516;
	var LibVLC_MediaListViewItemAdded         = 517;
	var LibVLC_MediaListViewWillAddItem       = 518;
	var LibVLC_MediaListViewItemDeleted       = 519;
	var LibVLC_MediaListViewWillDeleteItem    = 520;
	var LibVLC_MediaListPlayerPlayed          = 521;
	var LibVLC_MediaListPlayerNextItemSet     = 522;
	var LibVLC_MediaListPlayerStopped         = 523;
	var LibVLC_MediaDiscovererStarted         = 524;
	var LibVLC_MediaDiscovererEnded           = 525;
	var LibVLC_RendererDiscovererItemAdded    = 526;
	var LibVLC_RendererDiscovererItemDeleted  = 527;
	var LibVLC_VlmMediaAdded                  = 528;
	var LibVLC_VlmMediaRemoved                = 529;
	var LibVLC_VlmMediaChanged                = 530;
	var LibVLC_VlmMediaInstanceStarted        = 531;
	var LibVLC_VlmMediaInstanceStopped        = 532;
	var LibVLC_VlmMediaInstanceStatusInit     = 533;
	var LibVLC_VlmMediaInstanceStatusOpening  = 534;
	var LibVLC_VlmMediaInstanceStatusPlaying  = 535;
	var LibVLC_VlmMediaInstanceStatusPause    = 536;
	var LibVLC_VlmMediaInstanceStatusEnd      = 537;
	var LibVLC_VlmMediaInstanceStatusError    = 538;

	@:from public static inline function fromInt(i:Int):LibVLC_Event_E return cast i;

	@:to public inline function toInt():Int return cast this;
}
