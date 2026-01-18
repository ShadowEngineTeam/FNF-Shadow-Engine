#if !macro
// Discord API
#if DISCORD_ALLOWED
import backend.Discord;
#end
import haxe.Json;
// Psych
#if LUA_ALLOWED
import hxluajit.*;
import hxluajit.Types;
import psychlua.*;
#else
import psychlua.LuaUtils;
import psychlua.FunkinLua;
import psychlua.ModchartSprite;
import psychlua.HScript;
#end
#if HSCRIPT_ALLOWED
import tea.SScript;
#end
// Mobile Controls
import mobile.objects.MobileControls;
import mobile.objects.IMobileControls;
import mobile.objects.Hitbox;
import mobile.objects.TouchPad;
import mobile.objects.TouchButton;
import mobile.input.MobileInputID;
import mobile.backend.MobileData;
import mobile.input.MobileInputManager;
// Android
#if android
import android.content.Context as AndroidContext;
import android.widget.Toast as AndroidToast;
import android.os.Environment as AndroidEnvironment;
import android.Permissions as AndroidPermissions;
import android.Settings as AndroidSettings;
import android.Tools as AndroidTools;
import android.os.Build.VERSION as AndroidVersion;
import android.os.Build.VERSION_CODES as AndroidVersionCode;
//import android.os.BatteryManager as AndroidBatteryManager;
#end
import backend.Paths;
import backend.Controls;
import backend.CoolUtil;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.CustomFadeTransition;
import backend.ClientPrefs;
import backend.Conductor;
import backend.BaseStage;
import backend.Difficulty;
import backend.io.*;
import backend.Mods;
import mobile.backend.StorageUtil;
import objects.Alphabet;
import objects.BGSprite;
import states.PlayState;
import states.LoadingState;
// Flixel
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxShader;

// flixel-animate
import animate.FlxAnimate;

// ShadowUI
import ui.ShadowStyle;
import ui.components.controls.ShadowButton;
import ui.components.controls.ShadowCheckbox;
import ui.components.controls.ShadowStepper;
import ui.components.controls.ShadowDropdown;
import ui.components.controls.ShadowList;
import ui.components.controls.ShadowSlider;
import ui.components.text.ShadowLabel;
import ui.components.text.ShadowInputText;
import ui.components.text.ShadowTextInput;
import ui.components.layout.ShadowPanel;
import ui.components.layout.ShadowTabMenu;

using StringTools;
#end
