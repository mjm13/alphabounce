@echo off
cd /d D:\Project\SELF\alphabounce\game
mkdir C:\Users\admin\AppData\Roaming\Godot\export-templates 2>nul
mklink /J C:\Users\admin\AppData\Roaming\Godot\export-templates\4.7.1-stable D:\Project\SELF\alphabounce\tools\godot\templates\4.7.1.stable 2>nul
if not exist export_presets.cfg copy .export_presets.cfg export_presets.cfg
set ANDROID_HOME=D:\Project\SELF\alphabounce\tools\android-sdk
set ANDROID_SDK_ROOT=D:\Project\SELF\alphabounce\tools\android-sdk
set JAVA_HOME=D:\Project\SELF\alphabounce\tools\jdk
set PATH=%PATH%;D:\Project\SELF\alphabounce\tools\android-sdk\platform-tools;D:\Project\SELF\alphabounce\tools\jdk\bin
"D:\Project\SELF\alphabounce\tools\godot_std\Godot_v4.7.1-stable_win64.exe" --headless --path D:\Project\SELF\alphabounce\game --export-debug Android bin/AlphaBounce_debug.apk > build.log 2>&1
echo EXIT_CODE=%ERRORLEVEL% > build_result.txt
