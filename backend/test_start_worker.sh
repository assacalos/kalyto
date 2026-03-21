#!/bin/bash

# Script de test pour vérifier que start_queue_worker.sh fonctionne

APP_DIR="/home/amyv4492/kalyto.smil-app.com/kalyto_prod"
cd $APP_DIR || exit 1

echo "=========================================="
echo "TEST DE DÉMARRAGE DU WORKER"
echo "=========================================="
echo ""

# 1. Vérifier les permissions
echo "1. Vérification des permissions..."
if [ -x "start_queue_worker.sh" ]; then
    echo "✅ Script exécutable"
else
    echo "❌ Script non exécutable - Exécutez: chmod +x start_queue_worker.sh"
    exit 1
fi
echo ""

# 2. Vérifier que PHP est accessible
echo "2. Vérification de PHP..."
PHP_PATH="/opt/cpanel/ea-php81/root/usr/bin/php"
if [ -f "$PHP_PATH" ]; then
    echo "✅ PHP trouvé: $PHP_PATH"
    $PHP_PATH --version | head -1
else
    echo "⚠️  PHP standard non trouvé, test avec 'php'..."
    if command -v php > /dev/null 2>&1; then
        echo "✅ PHP trouvé dans PATH"
        php --version | head -1
    else
        echo "❌ PHP non trouvé"
        exit 1
    fi
fi
echo ""

# 3. Vérifier que artisan existe
echo "3. Vérification de artisan..."
if [ -f "artisan" ]; then
    echo "✅ artisan trouvé"
else
    echo "❌ artisan non trouvé"
    exit 1
fi
echo ""

# 4. Tester la commande queue:work directement
echo "4. Test de la commande queue:work (dry-run)..."
if $PHP_PATH artisan queue:work --help > /dev/null 2>&1; then
    echo "✅ Commande queue:work accessible"
else
    echo "❌ Commande queue:work non accessible"
    exit 1
fi
echo ""

# 5. Vérifier les répertoires de logs
echo "5. Vérification des répertoires de logs..."
if [ -d "storage/logs" ]; then
    echo "✅ Répertoire storage/logs existe"
    if [ -w "storage/logs" ]; then
        echo "✅ Répertoire storage/logs accessible en écriture"
    else
        echo "❌ Répertoire storage/logs non accessible en écriture"
        exit 1
    fi
else
    echo "❌ Répertoire storage/logs n'existe pas"
    exit 1
fi
echo ""

echo "=========================================="
echo "✅ TOUS LES TESTS PASSÉS"
echo "=========================================="
echo ""
echo "Vous pouvez maintenant démarrer le worker avec:"
echo "  nohup ./start_queue_worker.sh > /dev/null 2>&1 &"
echo ""

