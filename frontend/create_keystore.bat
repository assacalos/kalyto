@echo off
echo Creation de la cle de signature pour EasyConnect...
echo.

keytool -genkey -v -keystore android\app\keystore\easyconnect-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias easyconnect -storepass easyconnect123 -keypass easyconnect123 -dname "CN=EasyConnect, OU=IT, O=EasyConnect, L=City, S=State, C=FR"

echo.
echo Cle de signature creee avec succes !
echo Fichier: android\app\keystore\easyconnect-key.jks
echo Mot de passe: easyconnect123
echo.
pause

