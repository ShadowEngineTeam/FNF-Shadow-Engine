@echo off
echo Installing FNF Shadow Engine libraries...
echo.

:: Git-based libraries
echo Installing lime...
haxelib git lime https://github.com/FNF-SE/lime

echo Installing openfl...
haxelib git openfl https://github.com/FNF-SE/openfl

echo Installing flixel...
haxelib git flixel https://github.com/FNF-SE/flixel

echo Installing flixel-addons...
haxelib git flixel-addons https://github.com/FNF-SE/flixel-addons

echo Installing flixel-ui...
haxelib git flixel-ui https://github.com/FNF-SE/flixel-ui

echo Installing hxcpp...
haxelib git hxcpp https://github.com/FNF-SE/hxcpp

echo Installing SScript...
haxelib git SScript https://github.com/FNF-SE/SScript

echo Installing hxluajit...
haxelib git hxluajit https://github.com/FNF-SE/hxluajit

echo Installing format...
haxelib git format https://github.com/FNF-SE/format

echo Installing hxp...
haxelib git hxp https://github.com/FNF-SE/hxp

echo Installing hxvlc...
haxelib git hxvlc https://github.com/FNF-SE/hxvlc

echo Installing flixel-animate...
haxelib git flixel-animate https://github.com/FNF-SE/flixel-animate

echo Installing fnf-modcharting-tools...
haxelib git fnf-modcharting-tools https://github.com/FNF-SE/FNF-Modcharting-Tools

:: Haxelib libraries
echo Installing hxdiscord_rpc...
haxelib install hxdiscord_rpc

echo Installing hxgamemode...
haxelib install hxgamemode

echo.
echo All libraries installed!
pause
