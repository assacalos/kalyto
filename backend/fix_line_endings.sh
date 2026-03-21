#!/bin/bash

# Script pour convertir les fins de ligne Windows en Unix
# À exécuter sur le serveur

echo "Conversion des fins de ligne Windows vers Unix..."

# Convertir start_queue_worker.sh
if [ -f "start_queue_worker.sh" ]; then
    dos2unix start_queue_worker.sh 2>/dev/null || sed -i 's/\r$//' start_queue_worker.sh
    echo "✅ start_queue_worker.sh converti"
else
    echo "❌ start_queue_worker.sh non trouvé"
fi

# Convertir check_and_start_worker.sh
if [ -f "check_and_start_worker.sh" ]; then
    dos2unix check_and_start_worker.sh 2>/dev/null || sed -i 's/\r$//' check_and_start_worker.sh
    echo "✅ check_and_start_worker.sh converti"
else
    echo "❌ check_and_start_worker.sh non trouvé"
fi

# Convertir check_notification_system.sh
if [ -f "check_notification_system.sh" ]; then
    dos2unix check_notification_system.sh 2>/dev/null || sed -i 's/\r$//' check_notification_system.sh
    echo "✅ check_notification_system.sh converti"
else
    echo "❌ check_notification_system.sh non trouvé"
fi

echo ""
echo "✅ Conversion terminée"
echo "Vous pouvez maintenant exécuter les scripts normalement"

