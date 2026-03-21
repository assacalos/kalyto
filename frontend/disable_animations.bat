@echo off
echo Désactivation des animations pour améliorer les performances de l'émulateur...
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
echo Animations désactivées avec succès!


