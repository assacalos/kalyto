@echo off
echo Verification de la signature de l'APK...
echo.

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo APK trouve: build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo Verification de la signature...
    jarsigner -verify -verbose -certs build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo Verification terminee !
) else (
    echo ERREUR: APK non trouve !
    echo Assurez-vous d'avoir execute build_release_apk.bat d'abord.
)

echo.
pause

