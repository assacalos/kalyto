<?php

use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
|
| Here you may register all of the event broadcasting channels that your
| application supports. The given channel authorization callbacks are
| used to check if an authenticated user can listen to the channel.
|
*/

// Ne définir les channels que si le broadcasting est activé et configuré
$broadcastDriver = config('broadcasting.default');
$canDefineBroadcastChannels = $broadcastDriver !== 'null';

// Vérifier aussi que les credentials sont présentes selon le driver
if ($broadcastDriver === 'pusher') {
    $canDefineBroadcastChannels = $canDefineBroadcastChannels && config('broadcasting.connections.pusher.key');
} elseif ($broadcastDriver === 'reverb') {
    $canDefineBroadcastChannels = $canDefineBroadcastChannels && config('broadcasting.connections.reverb.key');
}

if ($canDefineBroadcastChannels) {
Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

// Canal pour les notifications en temps réel
Broadcast::channel('user.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});

// Canal pour les notifications globales (admin)
Broadcast::channel('notifications', function ($user) {
    return $user->role == 1; // Seuls les admins
});

// Canal pour le PATRON (Soumissions des commerciaux, RH, etc.)
Broadcast::channel('patron-approvals', function ($user) {
    return $user->isAdmin() || $user->isPatron();
});

// Canal pour les notifications RH
Broadcast::channel('hr-notifications', function ($user) {
    return in_array($user->role, [1, 4]); // Admin et RH
});

// Canal pour les notifications techniques
Broadcast::channel('tech-notifications', function ($user) {
    return in_array($user->role, [1, 5]); // Admin et Technicien
});

// Canal global Admin
Broadcast::channel('admin-only', function ($user) {
    return $user->isAdmin();
});
}