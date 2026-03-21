@echo off
REM Script pour tester EasyConnect Web localement
REM Auteur: EasyConnect Team
REM Date: Janvier 2026

echo ============================================
echo   Test EasyConnect Web (Local)
echo ============================================
echo.

REM Vérifier que Flutter est installé
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERREUR: Flutter n'est pas installé ou n'est pas dans le PATH
    pause
    exit /b 1
)

echo Choisissez le mode de test:
echo   1. Chrome (recommandé)
echo   2. Edge
echo   3. Serveur web local (port 8080)
echo.
set /p choice="Votre choix (1-3): "

if "%choice%"=="1" (
    echo.
    echo Lancement dans Chrome...
    echo CTRL+C pour arrêter
    echo.
    flutter run -d chrome
) else if "%choice%"=="2" (
    echo.
    echo Lancement dans Edge...
    echo CTRL+C pour arrêter
    echo.
    flutter run -d edge
) else if "%choice%"=="3" (
    echo.
    echo Lancement du serveur web sur http://localhost:8080
    echo CTRL+C pour arrêter
    echo.
    flutter run -d web-server --web-port=8080
) else (
    echo Choix invalide
    pause
    exit /b 1
)

pause

