@echo off
REM Script de build pour la version web d'EasyConnect
REM Auteur: EasyConnect Team
REM Date: Janvier 2026

echo ============================================
echo   Build EasyConnect Web
echo ============================================
echo.

REM Vérifier que Flutter est installé
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERREUR: Flutter n'est pas installé ou n'est pas dans le PATH
    pause
    exit /b 1
)

echo [1/5] Nettoyage des builds précédents...
if exist build\web (
    rmdir /s /q build\web
    echo - Dossier build\web supprimé
)

echo.
echo [2/5] Récupération des dépendances...
flutter pub get
if %errorlevel% neq 0 (
    echo ERREUR: Échec de flutter pub get
    pause
    exit /b 1
)

echo.
echo [3/5] Analyse du code...
flutter analyze
if %errorlevel% neq 0 (
    echo ATTENTION: Des erreurs d'analyse ont été détectées
    echo Voulez-vous continuer quand même ? (O/N)
    set /p continue=
    if /i not "%continue%"=="O" (
        echo Build annulé
        pause
        exit /b 1
    )
)

echo.
echo [4/5] Build de l'application web...
echo Options de build:
echo   1. Build standard (HTML renderer)
echo   2. Build optimisé (CanvasKit renderer - recommandé)
echo   3. Build automatique (détection auto)
echo.
set /p choice="Choisissez une option (1-3): "

if "%choice%"=="1" (
    echo Building avec HTML renderer...
    flutter build web --release --web-renderer html
) else if "%choice%"=="2" (
    echo Building avec CanvasKit renderer (recommandé)...
    flutter build web --release --web-renderer canvaskit --tree-shake-icons
) else if "%choice%"=="3" (
    echo Building avec détection automatique...
    flutter build web --release --web-renderer auto --tree-shake-icons
) else (
    echo Choix invalide, utilisation du build optimisé par défaut
    flutter build web --release --web-renderer canvaskit --tree-shake-icons
)

if %errorlevel% neq 0 (
    echo.
    echo ERREUR: Le build a échoué!
    pause
    exit /b 1
)

echo.
echo [5/5] Vérification du build...
if exist build\web\index.html (
    echo ✅ Build réussi!
    echo.
    echo Les fichiers se trouvent dans: build\web\
    echo.
    echo Prochaines étapes:
    echo   - Pour tester localement: flutter run -d chrome
    echo   - Pour déployer: Copiez le contenu de build\web\ vers votre serveur
    echo   - Firebase Hosting: firebase deploy --only hosting
    echo   - Netlify: netlify deploy --prod --dir=build\web
) else (
    echo ❌ Build échoué - index.html non trouvé
    pause
    exit /b 1
)

echo.
echo ============================================
pause

