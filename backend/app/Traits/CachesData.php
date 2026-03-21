<?php

namespace App\Traits;

use Illuminate\Support\Facades\Cache;

trait CachesData
{
    /**
     * Durées de cache en secondes
     */
    protected function getCacheDurations()
    {
        return [
            'static' => 86400,      // 24 heures pour les données statiques (listes déroulantes)
            'daily_stats' => 3600,  // 1 heure pour les statistiques quotidiennes
            'hourly_stats' => 1800, // 30 minutes pour les statistiques horaires
            'roles' => 86400,       // 24 heures pour les rôles/permissions
        ];
    }

    /**
     * Récupérer ou mettre en cache des données statiques
     */
    protected function rememberStatic($key, $callback, $ttl = null)
    {
        $ttl = $ttl ?? $this->getCacheDurations()['static'];
        return Cache::remember($key, $ttl, $callback);
    }

    /**
     * Récupérer ou mettre en cache des statistiques quotidiennes
     */
    protected function rememberDailyStats($key, $date, $callback)
    {
        $cacheKey = "{$key}:{$date}";
        $ttl = $this->getCacheDurations()['daily_stats'];
        return Cache::remember($cacheKey, $ttl, $callback);
    }

    /**
     * Récupérer ou mettre en cache des statistiques horaires
     */
    protected function rememberHourlyStats($key, $date, $hour, $callback)
    {
        $cacheKey = "{$key}:{$date}:{$hour}";
        $ttl = $this->getCacheDurations()['hourly_stats'];
        return Cache::remember($cacheKey, $ttl, $callback);
    }

    /**
     * Invalider le cache pour une clé
     */
    protected function forgetCache($key)
    {
        Cache::forget($key);
    }

    /**
     * Invalider le cache avec un pattern (pour les statistiques quotidiennes)
     */
    protected function forgetCachePattern($pattern)
    {
        // Pour Redis, on peut utiliser des patterns
        if (config('cache.default') === 'redis') {
            $redis = Cache::getStore()->getRedis();
            $keys = $redis->keys($pattern);
            if (!empty($keys)) {
                $redis->del($keys);
            }
        } else {
            // Pour les autres drivers, on doit invalider manuellement
            // Cette méthode peut être étendue selon les besoins
        }
    }
}

