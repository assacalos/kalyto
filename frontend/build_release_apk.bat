@echo off
echo Construction de l'APK de production pour EasyConnect...
echo.

echo Nettoyage du build precedent...
flutter clean

echo.
echo Installation des dependances...
flutter pub get

echo.
echo Construction de l'APK release universel (toutes architectures)...
flutter build apk --release --target-platform android-arm,android-arm64,android-x64

echo.
echo APK genere avec succes !
echo Fichier: build\app\outputs\flutter-apk\app-release.apk
echo.
echo Cet APK supporte les architectures suivantes:
echo - armeabi-v7a (ARM 32-bit)
echo - arm64-v8a (ARM 64-bit)
echo - x86_64 (Intel 64-bit)
echo.
pause

