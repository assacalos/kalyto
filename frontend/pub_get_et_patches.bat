@echo off
REM Utilisez ce script a la place de "flutter pub get" pour appliquer automatiquement
REM le correctif flutter_app_badger (namespace Android) apres chaque pub get.
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "scripts\pub_get_et_patches.ps1"
exit /b %ERRORLEVEL%
