@echo off
REM CampusSports Flutter Launcher
REM This batch file runs Flutter commands with the correct path
REM Usage: flutter.bat run -d chrome  OR  flutter run -d chrome (if in PATH)

setlocal
set FLUTTER_PATH=C:\Users\Prajesh\Downloads\flutter_windows_3.41.2-stable\flutter\bin\flutter.bat

REM Run the flutter command with all arguments passed
"%FLUTTER_PATH%" %*

endlocal
