<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\User;
use App\Jobs\ProcessNotificationActionsJob;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    /**
     * LE CŒUR DU SERVICE : 
     * 1. Enregistre en base de données de façon synchrone (Sécurité des données)
     * 2. Déclenche le Job asynchrone pour les envois externes (Performance)
     */
    public function createAndBroadcast($userId, $type, $titre, $message, $data = [], $priorite = 'normale', $canal = 'app')
    {
        try {
            // 1. Sauvegarde IMMÉDIATE en Base de Données
            // Comme ça, même si le worker de queue s'arrête, la donnée est là.
            $notification = Notification::create([
                'user_id'   => $userId,
                'type'      => $type,
                'titre'     => $titre,
                'message'   => $message,
                'data'      => $data,    // Stockage JSON des infos supplémentaires (entity_type, entity_id, action_route, etc.)
                'priorite'  => $priorite,
                'canal'     => $canal,
                'statut'    => 'non_lue',
            ]);

            // 2. DÉLÉGATION AU JOB (ASYNCHRONE)
            // On envoie le job dans la file d'attente pour ne pas faire attendre l'utilisateur
            ProcessNotificationActionsJob::dispatch($notification);

            return $notification;

        } catch (\Exception $e) {
            Log::error("Erreur critique lors de la création de notification : " . $e->getMessage());
            return null;
        }
    }

    /**
     * Envoyer une notification à tous les utilisateurs ayant un rôle spécifique
     */
    public function broadcastToRole($roleId, $type, $titre, $message, $data = [], $priorite = 'normale')
    {
        $users = User::where('role', $roleId)->get();
        foreach ($users as $user) {
            $this->createAndBroadcast($user->id, $type, $titre, $message, $data, $priorite);
        }
    }

    // --- MÉTHODES MÉTIERS CLIENTS (AJOUTÉES) ---

    public function notifyNewClient($client)
    {
        // On notifie le Patron (Rôle 6) pour validation
        $this->broadcastToRole(6, 'client', 'Nouveau client à valider', 
            "L'entreprise {$client->nom_entreprise} a été soumise pour validation.", 
            ['client_id' => $client->id, 'action' => 'validation']);
    }

    public function notifyClientValidated($client)
    {
        // On notifie le Commercial (celui qui a créé le client)
        $this->createAndBroadcast($client->user_id, 'client', 'Client Validé', 
            "Votre client {$client->nom_entreprise} a été approuvé par la direction.", 
            ['client_id' => $client->id]);
    }

    public function notifyClientRejected($client)
    {
        // On notifie le Commercial avec la raison du rejet
        $this->createAndBroadcast($client->user_id, 'client', 'Client Rejeté', 
            "Le dossier {$client->nom_entreprise} a été rejeté.", 
            ['client_id' => $client->id, 'raison' => $client->commentaire_rejet]);
    }

    // --- AUTRES MÉTHODES MÉTIERS (POINTAGE, CONGÉS, etc.) ---


    public function notifyNewAttendance($attendance)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$attendance->relationLoaded('user') && isset($attendance->user_id)) {
            $attendance->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($attendance->user)) {
            $userName = trim(($attendance->user->nom ?? '') . ' ' . ($attendance->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $datePointage = $attendance->check_in_time 
            ? $attendance->check_in_time->format('Y-m-d H:i') 
            : ($attendance->check_out_time 
                ? $attendance->check_out_time->format('Y-m-d H:i') 
                : $attendance->id);
        
        $this->broadcastToRole(6, 'attendance', 'Nouveau pointage', 
            "{$userName} a pointé le {$datePointage}", 
            [
                'attendance_id' => $attendance->id,
                'entity_type' => 'attendance',
                'entity_id' => (string)$attendance->id,
                'action_route' => "/attendances/{$attendance->id}"
            ]);
    }

    public function notifyAttendanceValidated($attendance)
    {
        $this->createAndBroadcast($attendance->user_id, 'attendance', 'Pointage validé', 
            'Votre pointage a été validé', ['attendance_id' => $attendance->id]);
    }

    public function notifyAttendanceRejected($attendance, $reason)
    {
        $identifier = $attendance->check_in_time 
            ? $attendance->check_in_time->format('Y-m-d') 
            : ($attendance->check_out_time 
                ? $attendance->check_out_time->format('Y-m-d') 
                : $attendance->id);
        $this->notifySubmitterOnRejection($attendance, 'attendance', 'Pointage', $reason, 'user_id', $identifier);
    }

    public function notifyNewConge($conge)
    {
        if (!$conge->relationLoaded('user') && isset($conge->user_id)) {
            $conge->load('user');
        }
        $userName = 'Un utilisateur';
        if (isset($conge->user)) {
            $userName = trim(($conge->user->nom ?? '') . ' ' . ($conge->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        $this->broadcastToRole(6, 'conge', 'Nouvelle demande de congé', 
            "{$userName} a demandé un congé", 
            ['conge_id' => $conge->id], $conge->urgent ? 'urgente' : 'normale');
    }

    public function notifyCongeApproved($conge)
    {
        $this->createAndBroadcast($conge->user_id, 'conge', 'Congé approuvé', 
            'Votre demande de congé a été approuvée', ['conge_id' => $conge->id]);
    }
    public function notifyCongeRejected($conge)
    {
        $this->createAndBroadcast($conge->user_id, 'conge', 'Congé rejeté', 
            'Votre demande de congé a été rejetée', ['conge_id' => $conge->id]);
    }
    

    // --- MÉTHODES MÉTIERS POUR TOUTES LES ENTITÉS ---

    /**
     * Notifier le patron lors d'une soumission (générique)
     */
    public function notifyApproverOnSubmission($entity, $entityType, $entityName, $approverRole = 6, $identifier = null)
    {
        $identifier = $identifier ?? $entity->id ?? 'N/A';
        $entityId = $entity->id ?? null;
        
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$entity->relationLoaded('user') && isset($entity->user_id)) {
            $entity->load('user');
        }
        
        $userName = 'Utilisateur';
        if (isset($entity->user)) {
            $userName = trim(($entity->user->nom ?? '') . ' ' . ($entity->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Utilisateur';
            }
        }
        
        $this->broadcastToRole($approverRole, $entityType, "Soumission {$entityName}", 
            "{$entityName} #{$identifier} a été soumise pour validation par {$userName}", 
            [
                'entity_type' => $entityType,
                'entity_id' => $entityId,
                'entity_name' => $entityName,
                'identifier' => $identifier,
                'action' => 'validation',
                'action_route' => "/{$entityType}s/{$entityId}"
            ], 
            'haute'
        );
    }

    /**
     * Notifier le soumetteur lors d'une validation (générique)
     */
    public function notifySubmitterOnApproval($entity, $entityType, $entityName, $userIdField = 'user_id', $identifier = null)
    {
        $userId = $entity->{$userIdField} ?? null;
        if (!$userId) {
            Log::warning("Impossible de notifier : {$userIdField} manquant", ['entity_type' => $entityType, 'entity_id' => $entity->id ?? null]);
            return;
        }

        $identifier = $identifier ?? $entity->id ?? 'N/A';
        $entityId = $entity->id ?? null;
        
        $this->createAndBroadcast($userId, $entityType, "{$entityName} Validé", 
            "Votre {$entityName} #{$identifier} a été validée", 
            [
                'entity_type' => $entityType,
                'entity_id' => $entityId,
                'entity_name' => $entityName,
                'identifier' => $identifier,
                'action' => 'view',
                'action_route' => "/{$entityType}s/{$entityId}"
            ], 
            'normale'
        );
    }

    /**
     * Notifier le soumetteur lors d'un rejet (générique)
     */
    public function notifySubmitterOnRejection($entity, $entityType, $entityName, $reason, $userIdField = 'user_id', $identifier = null)
    {
        $userId = $entity->{$userIdField} ?? null;
        if (!$userId) {
            Log::warning("Impossible de notifier : {$userIdField} manquant", ['entity_type' => $entityType, 'entity_id' => $entity->id ?? null]);
            return;
        }

        $identifier = $identifier ?? $entity->id ?? 'N/A';
        $entityId = $entity->id ?? null;
        
        $this->createAndBroadcast($userId, $entityType, "{$entityName} Rejeté", 
            "Votre {$entityName} #{$identifier} a été rejetée. Raison : {$reason}", 
            [
                'entity_type' => $entityType,
                'entity_id' => $entityId,
                'entity_name' => $entityName,
                'identifier' => $identifier,
                'reason' => $reason,
                'action' => 'view',
                'action_route' => "/{$entityType}s/{$entityId}"
            ], 
            'normale'
        );
    }

    // --- MÉTHODES SPÉCIFIQUES PAR ENTITÉ ---

    // Pointage
    // Reporting
    public function notifyNewReporting($reporting)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$reporting->relationLoaded('user') && isset($reporting->user_id)) {
            $reporting->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($reporting->user)) {
            $userName = trim(($reporting->user->nom ?? '') . ' ' . ($reporting->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $this->broadcastToRole(6, 'reporting', 'Nouveau reporting', 
            "{$userName} a soumis un reporting", 
            [
                'reporting_id' => $reporting->id,
                'entity_type' => 'reporting',
                'entity_id' => (string)$reporting->id,
                'action_route' => "/reportings/{$reporting->id}"
            ]);
    }

    public function notifyReportingValidated($reporting)
    {
        $this->createAndBroadcast($reporting->user_id, 'reporting', 'Reporting validé', 
            'Votre reporting a été validé', ['reporting_id' => $reporting->id]);
    }

    public function notifyReportingRejected($reporting, $reason)
    {
        $this->createAndBroadcast($reporting->user_id, 'reporting', 'Reporting rejeté', 
            "Votre reporting a été rejeté. Raison : {$reason}", 
            ['reporting_id' => $reporting->id, 'raison' => $reason]);
    }

    // Commande Entreprise
    public function notifyNewCommandeEntreprise($commande)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$commande->relationLoaded('user') && isset($commande->user_id)) {
            $commande->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($commande->user)) {
            $userName = trim(($commande->user->nom ?? '') . ' ' . ($commande->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $commande->numero_commande ?? $commande->id;
        $this->broadcastToRole(6, 'commande_entreprise', 'Nouvelle commande entreprise', 
            "{$userName} a soumis une commande entreprise #{$identifier} pour validation", 
            [
                'commande_id' => $commande->id,
                'entity_type' => 'commande_entreprise',
                'entity_id' => (string)$commande->id,
                'action_route' => "/commandes/{$commande->id}"
            ]);
    }

    public function notifyCommandeEntrepriseValidated($commande)
    {
        $identifier = $commande->numero_commande ?? $commande->id;
        $this->createAndBroadcast($commande->user_id, 'commande_entreprise', 'Commande validée', 
            "Votre commande entreprise #{$identifier} a été validée", 
            ['commande_id' => $commande->id]);
    }

    public function notifyCommandeEntrepriseRejected($commande, $reason)
    {
        $identifier = $commande->numero_commande ?? $commande->id;
        $this->createAndBroadcast($commande->user_id, 'commande_entreprise', 'Commande rejetée', 
            "Votre commande entreprise #{$identifier} a été rejetée. Raison : {$reason}", 
            ['commande_id' => $commande->id, 'raison' => $reason]);
    }

    // Devis (relation commercial = user_id sur le modèle Devis)
    public function notifyNewDevis($devis)
    {
        if (!$devis->relationLoaded('commercial') && isset($devis->user_id)) {
            $devis->load('commercial');
        }
        
        $userName = 'Un utilisateur';
        if (isset($devis->commercial)) {
            $userName = trim(($devis->commercial->nom ?? '') . ' ' . ($devis->commercial->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $devis->reference ?? $devis->id;
        $this->broadcastToRole(6, 'devis', 'Nouveau devis', 
            "{$userName} a soumis un devis #{$identifier} pour validation", 
            [
                'devis_id' => $devis->id,
                'entity_type' => 'devis',
                'entity_id' => (string)$devis->id,
                'action_route' => "/devis/{$devis->id}"
            ]);
    }

    public function notifyDevisValidated($devis)
    {
        $identifier = $devis->reference ?? $devis->id;
        $this->createAndBroadcast($devis->user_id, 'devis', 'Devis validé', 
            "Votre devis #{$identifier} a été validé", 
            ['devis_id' => $devis->id]);
    }

    public function notifyDevisRejected($devis, $reason)
    {
        $identifier = $devis->reference ?? $devis->id;
        $this->createAndBroadcast($devis->user_id, 'devis', 'Devis rejeté', 
            "Votre devis #{$identifier} a été rejeté. Raison : {$reason}", 
            ['devis_id' => $devis->id, 'raison' => $reason]);
    }

    // Bordereau
    public function notifyNewBordereau($bordereau)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$bordereau->relationLoaded('user') && isset($bordereau->user_id)) {
            $bordereau->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($bordereau->user)) {
            $userName = trim(($bordereau->user->nom ?? '') . ' ' . ($bordereau->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $bordereau->reference ?? $bordereau->id;
        $this->broadcastToRole(6, 'bordereau', 'Nouveau bordereau', 
            "{$userName} a soumis un bordereau #{$identifier} pour validation", 
            [
                'bordereau_id' => $bordereau->id,
                'entity_type' => 'bordereau',
                'entity_id' => (string)$bordereau->id,
                'action_route' => "/bordereaux/{$bordereau->id}"
            ]);
    }

    public function notifyBordereauValidated($bordereau)
    {
        $identifier = $bordereau->reference ?? $bordereau->id;
        $this->createAndBroadcast($bordereau->user_id, 'bordereau', 'Bordereau validé', 
            "Votre bordereau #{$identifier} a été validé", 
            ['bordereau_id' => $bordereau->id]);
    }

    public function notifyBordereauRejected($bordereau, $reason)
    {
        $identifier = $bordereau->reference ?? $bordereau->id;
        $this->createAndBroadcast($bordereau->user_id, 'bordereau', 'Bordereau rejeté', 
            "Votre bordereau #{$identifier} a été rejeté. Raison : {$reason}", 
            ['bordereau_id' => $bordereau->id, 'raison' => $reason]);
    }

    // Bon de Commande Fournisseur
    public function notifyNewBonCommandeFournisseur($bonCommande)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$bonCommande->relationLoaded('user') && isset($bonCommande->user_id)) {
            $bonCommande->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($bonCommande->user)) {
            $userName = trim(($bonCommande->user->nom ?? '') . ' ' . ($bonCommande->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $bonCommande->numero_commande ?? $bonCommande->id;
        $this->broadcastToRole(6, 'bon_commande_fournisseur', 'Nouveau bon de commande fournisseur', 
            "{$userName} a soumis un bon de commande fournisseur #{$identifier} pour validation", 
            [
                'bon_commande_id' => $bonCommande->id,
                'entity_type' => 'bon_commande_fournisseur',
                'entity_id' => (string)$bonCommande->id,
                'action_route' => "/bon-commandes/{$bonCommande->id}"
            ]);
    }

    public function notifyBonCommandeFournisseurValidated($bonCommande)
    {
        $identifier = $bonCommande->numero_commande ?? $bonCommande->id;
        $this->createAndBroadcast($bonCommande->user_id, 'bon_commande_fournisseur', 'Bon de commande validé', 
            "Votre bon de commande fournisseur #{$identifier} a été validé", 
            ['bon_commande_id' => $bonCommande->id]);
    }

    public function notifyBonCommandeFournisseurRejected($bonCommande, $reason)
    {
        $identifier = $bonCommande->numero_commande ?? $bonCommande->id;
        $this->createAndBroadcast($bonCommande->user_id, 'bon_commande_fournisseur', 'Bon de commande rejeté', 
            "Votre bon de commande fournisseur #{$identifier} a été rejeté. Raison : {$reason}", 
            ['bon_commande_id' => $bonCommande->id, 'raison' => $reason]);
    }

    // Facture
    public function notifyNewFacture($facture)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$facture->relationLoaded('user') && isset($facture->user_id)) {
            $facture->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($facture->user)) {
            $userName = trim(($facture->user->nom ?? '') . ' ' . ($facture->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $facture->numero_facture ?? $facture->id;
        $this->broadcastToRole(6, 'facture', 'Nouvelle facture', 
            "{$userName} a soumis une facture #{$identifier} pour validation", 
            [
                'facture_id' => $facture->id,
                'entity_type' => 'facture',
                'entity_id' => (string)$facture->id,
                'action_route' => "/factures/{$facture->id}"
            ]);
    }

    public function notifyFactureValidated($facture)
    {
        $identifier = $facture->numero_facture ?? $facture->id;
        $this->createAndBroadcast($facture->user_id, 'facture', 'Facture validée', 
            "Votre facture #{$identifier} a été validée", 
            ['facture_id' => $facture->id]);
    }

    public function notifyFactureRejected($facture, $reason)
    {
        $identifier = $facture->numero_facture ?? $facture->id;
        $this->createAndBroadcast($facture->user_id, 'facture', 'Facture rejetée', 
            "Votre facture #{$identifier} a été rejetée. Raison : {$reason}", 
            ['facture_id' => $facture->id, 'raison' => $reason]);
    }

    // Paiement
    public function notifyNewPaiement($paiement)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$paiement->relationLoaded('user') && isset($paiement->user_id)) {
            $paiement->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($paiement->user)) {
            $userName = trim(($paiement->user->nom ?? '') . ' ' . ($paiement->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $paiement->numero_paiement ?? $paiement->id;
        $this->broadcastToRole(6, 'paiement', 'Nouveau paiement', 
            "{$userName} a soumis un paiement #{$identifier} pour validation", 
            [
                'paiement_id' => $paiement->id,
                'entity_type' => 'paiement',
                'entity_id' => (string)$paiement->id,
                'action_route' => "/paiements/{$paiement->id}"
            ]);
    }

    public function notifyPaiementValidated($paiement)
    {
        $identifier = $paiement->reference ?? $paiement->numero_paiement ?? $paiement->id;
        $userId = $paiement->comptable_id ?? $paiement->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'paiement', 'Paiement validé', 
                "Votre paiement #{$identifier} a été validé", 
                ['paiement_id' => $paiement->id]);
        }
    }

    public function notifyPaiementRejected($paiement, $reason)
    {
        $identifier = $paiement->reference ?? $paiement->numero_paiement ?? $paiement->id;
        $userId = $paiement->comptable_id ?? $paiement->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'paiement', 'Paiement rejeté', 
                "Votre paiement #{$identifier} a été rejeté. Raison : {$reason}", 
                ['paiement_id' => $paiement->id, 'raison' => $reason]);
        }
    }

    // Dépense
    public function notifyNewDepense($depense)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$depense->relationLoaded('user') && isset($depense->user_id)) {
            $depense->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($depense->user)) {
            $userName = trim(($depense->user->nom ?? '') . ' ' . ($depense->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $depense->expense_number ?? $depense->numero_depense ?? $depense->id;
        $this->broadcastToRole(6, 'depense', 'Nouvelle dépense', 
            "{$userName} a soumis une dépense #{$identifier} pour validation", 
            [
                'depense_id' => $depense->id,
                'entity_type' => 'depense',
                'entity_id' => (string)$depense->id,
                'action_route' => "/depenses/{$depense->id}"
            ]);
    }

    public function notifyDepenseValidated($depense)
    {
        $identifier = $depense->expense_number ?? $depense->numero_depense ?? $depense->id;
        $userId = $depense->employee_id ?? $depense->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'depense', 'Dépense validée', 
                "Votre dépense #{$identifier} a été validée", 
                ['depense_id' => $depense->id]);
        }
    }

    public function notifyDepenseRejected($depense, $reason)
    {
        $identifier = $depense->expense_number ?? $depense->numero_depense ?? $depense->id;
        $userId = $depense->employee_id ?? $depense->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'depense', 'Dépense rejetée', 
                "Votre dépense #{$identifier} a été rejetée. Raison : {$reason}", 
                ['depense_id' => $depense->id, 'raison' => $reason]);
        }
    }

    // Stock
    public function notifyNewStock($stock)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$stock->relationLoaded('user') && isset($stock->user_id)) {
            $stock->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($stock->user)) {
            $userName = trim(($stock->user->nom ?? '') . ' ' . ($stock->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $stock->name ?? $stock->sku ?? $stock->id;
        $this->broadcastToRole(6, 'stock', 'Nouveau stock', 
            "{$userName} a créé un stock : {$identifier}", 
            [
                'stock_id' => $stock->id,
                'entity_type' => 'stock',
                'entity_id' => (string)$stock->id,
                'action_route' => "/stocks/{$stock->id}"
            ]);
    }

    public function notifyStockValidated($stock)
    {
        $identifier = $stock->name ?? $stock->sku ?? $stock->id;
        $userId = $stock->created_by ?? $stock->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'stock', 'Stock validé', 
                "Votre stock \"{$identifier}\" a été validé", 
                ['stock_id' => $stock->id]);
        }
    }

    public function notifyStockRejected($stock, $reason)
    {
        $identifier = $stock->name ?? $stock->sku ?? $stock->id;
        $userId = $stock->created_by ?? $stock->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'stock', 'Stock rejeté', 
                "Votre stock \"{$identifier}\" a été rejeté. Raison : {$reason}", 
                ['stock_id' => $stock->id, 'raison' => $reason]);
        }
    }

    // Taxe
    public function notifyNewTaxe($taxe)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$taxe->relationLoaded('user') && isset($taxe->user_id)) {
            $taxe->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($taxe->user)) {
            $userName = trim(($taxe->user->nom ?? '') . ' ' . ($taxe->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $taxe->reference ?? $taxe->nom ?? $taxe->id;
        $this->broadcastToRole(6, 'taxe', 'Nouvelle taxe', 
            "{$userName} a créé une taxe : {$identifier}", 
            [
                'taxe_id' => $taxe->id,
                'entity_type' => 'taxe',
                'entity_id' => (string)$taxe->id,
                'action_route' => "/taxes/{$taxe->id}"
            ]);
    }

    public function notifyTaxeValidated($taxe)
    {
        $identifier = $taxe->reference ?? $taxe->nom ?? $taxe->id;
        $userId = $taxe->comptable_id ?? $taxe->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'taxe', 'Taxe validée', 
                "Votre taxe \"{$identifier}\" a été validée", 
                ['taxe_id' => $taxe->id]);
        }
    }

    public function notifyTaxeRejected($taxe, $reason)
    {
        $identifier = $taxe->reference ?? $taxe->nom ?? $taxe->id;
        $userId = $taxe->comptable_id ?? $taxe->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'taxe', 'Taxe rejetée', 
                "Votre taxe \"{$identifier}\" a été rejetée. Raison : {$reason}", 
                ['taxe_id' => $taxe->id, 'raison' => $reason]);
        }
    }

    // Fournisseur
    public function notifyNewFournisseur($fournisseur)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$fournisseur->relationLoaded('user') && isset($fournisseur->user_id)) {
            $fournisseur->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($fournisseur->user)) {
            $userName = trim(($fournisseur->user->nom ?? '') . ' ' . ($fournisseur->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $fournisseur->nom_entreprise ?? $fournisseur->nom ?? $fournisseur->id;
        $this->broadcastToRole(6, 'fournisseur', 'Nouveau fournisseur', 
            "{$userName} a ajouté le fournisseur {$identifier}", 
            [
                'fournisseur_id' => $fournisseur->id,
                'entity_type' => 'fournisseur',
                'entity_id' => (string)$fournisseur->id,
                'action_route' => "/fournisseurs/{$fournisseur->id}"
            ]);
    }

    public function notifyFournisseurValidated($fournisseur)
    {
        $identifier = $fournisseur->nom_entreprise ?? $fournisseur->nom ?? $fournisseur->id;
        $userId = $fournisseur->created_by ?? $fournisseur->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'fournisseur', 'Fournisseur validé', 
                "Le fournisseur {$identifier} a été validé", 
                ['fournisseur_id' => $fournisseur->id]);
        }
    }

    public function notifyFournisseurRejected($fournisseur, $reason)
    {
        $identifier = $fournisseur->nom_entreprise ?? $fournisseur->nom ?? $fournisseur->id;
        $userId = $fournisseur->created_by ?? $fournisseur->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'fournisseur', 'Fournisseur rejeté', 
                "Le fournisseur {$identifier} a été rejeté. Raison : {$reason}", 
                ['fournisseur_id' => $fournisseur->id, 'raison' => $reason]);
        }
    }

    // Salaire
    public function notifyNewSalaire($salaire)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$salaire->relationLoaded('user') && isset($salaire->user_id)) {
            $salaire->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($salaire->user)) {
            $userName = trim(($salaire->user->nom ?? '') . ' ' . ($salaire->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $salaire->mois ?? $salaire->id;
        $this->broadcastToRole(6, 'salaire', 'Nouveau salaire', 
            "{$userName} a créé un salaire pour {$identifier}", 
            [
                'salaire_id' => $salaire->id,
                'entity_type' => 'salaire',
                'entity_id' => (string)$salaire->id,
                'action_route' => "/salaires/{$salaire->id}"
            ]);
    }

    public function notifySalaireValidated($salaire)
    {
        $identifier = $salaire->mois ?? $salaire->id;
        $userId = $salaire->employee_id ?? $salaire->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'salaire', 'Salaire validé', 
                "Votre salaire pour {$identifier} a été validé", 
                ['salaire_id' => $salaire->id]);
        }
    }

    public function notifySalaireRejected($salaire, $reason)
    {
        $identifier = $salaire->mois ?? $salaire->id;
        $userId = $salaire->employee_id ?? $salaire->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'salaire', 'Salaire rejeté', 
                "Votre salaire pour {$identifier} a été rejeté. Raison : {$reason}", 
                ['salaire_id' => $salaire->id, 'raison' => $reason]);
        }
    }

    // Intervention
    public function notifyNewIntervention($intervention)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$intervention->relationLoaded('user') && isset($intervention->user_id)) {
            $intervention->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($intervention->user)) {
            $userName = trim(($intervention->user->nom ?? '') . ' ' . ($intervention->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $intervention->numero_intervention ?? $intervention->id;
        $this->broadcastToRole(6, 'intervention', 'Nouvelle intervention', 
            "{$userName} a créé une intervention #{$identifier}", 
            [
                'intervention_id' => $intervention->id,
                'entity_type' => 'intervention',
                'entity_id' => (string)$intervention->id,
                'action_route' => "/interventions/{$intervention->id}"
            ]);
    }

    public function notifyInterventionValidated($intervention)
    {
        $identifier = $intervention->numero_intervention ?? $intervention->id;
        $userId = $intervention->created_by ?? $intervention->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'intervention', 'Intervention validée', 
                "Votre intervention #{$identifier} a été validée", 
                ['intervention_id' => $intervention->id]);
        }
    }

    public function notifyInterventionRejected($intervention, $reason)
    {
        $identifier = $intervention->numero_intervention ?? $intervention->id;
        $userId = $intervention->created_by ?? $intervention->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'intervention', 'Intervention rejetée', 
                "Votre intervention #{$identifier} a été rejetée. Raison : {$reason}", 
                ['intervention_id' => $intervention->id, 'raison' => $reason]);
        }
    }

    // Besoin (demande technicien → patron, rappels automatiques hors intervention)
    public function notifyNewBesoin($besoin)
    {
        $besoin->loadMissing('creator');
        $creatorName = $besoin->creator
            ? trim(($besoin->creator->prenom ?? '') . ' ' . ($besoin->creator->nom ?? ''))
            : 'Le technicien';
        if (empty(trim($creatorName))) {
            $creatorName = 'Le technicien';
        }
        $this->broadcastToRole(6, 'besoin', 'Nouveau besoin / rappel',
            "{$creatorName} : {$besoin->title}. Vous serez rappelé automatiquement selon la période définie.",
            [
                'besoin_id' => $besoin->id,
                'entity_type' => 'besoin',
                'entity_id' => (string) $besoin->id,
                'action_route' => "/besoins/{$besoin->id}",
            ]);
    }

    public function notifyBesoinReminder($besoin)
    {
        $besoin->loadMissing('creator');
        $creatorName = $besoin->creator
            ? trim(($besoin->creator->prenom ?? '') . ' ' . ($besoin->creator->nom ?? ''))
            : 'Le technicien';
        if (empty(trim($creatorName))) {
            $creatorName = 'Le technicien';
        }
        $this->broadcastToRole(6, 'besoin', 'Rappel : besoin en attente',
            "{$creatorName} – {$besoin->title} – En attente de votre traitement.",
            [
                'besoin_id' => $besoin->id,
                'entity_type' => 'besoin',
                'entity_id' => (string) $besoin->id,
                'action_route' => "/besoins/{$besoin->id}",
            ]);
    }

    // Équipement
    public function notifyNewEquipement($equipement)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$equipement->relationLoaded('user') && isset($equipement->user_id)) {
            $equipement->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($equipement->user)) {
            $userName = trim(($equipement->user->nom ?? '') . ' ' . ($equipement->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $equipement->numero_serie ?? $equipement->name ?? $equipement->nom ?? $equipement->id;
        $this->broadcastToRole(6, 'equipement', 'Nouvel équipement', 
            "{$userName} a créé un équipement : {$identifier}", 
            [
                'equipement_id' => $equipement->id,
                'entity_type' => 'equipement',
                'entity_id' => (string)$equipement->id,
                'action_route' => "/equipements/{$equipement->id}"
            ]);
    }

    public function notifyEquipementValidated($equipement)
    {
        $identifier = $equipement->numero_serie ?? $equipement->name ?? $equipement->nom ?? $equipement->id;
        $userId = $equipement->created_by ?? $equipement->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'equipement', 'Équipement validé', 
                "Votre équipement \"{$identifier}\" a été validé", 
                ['equipement_id' => $equipement->id]);
        }
    }

    public function notifyEquipementRejected($equipement, $reason)
    {
        $identifier = $equipement->numero_serie ?? $equipement->name ?? $equipement->nom ?? $equipement->id;
        $userId = $equipement->created_by ?? $equipement->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'equipement', 'Équipement rejeté', 
                "Votre équipement \"{$identifier}\" a été rejeté. Raison : {$reason}", 
                ['equipement_id' => $equipement->id, 'raison' => $reason]);
        }
    }

    // Leave (Congé)
    public function notifyNewLeaveRequest($leave)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$leave->relationLoaded('user') && isset($leave->user_id)) {
            $leave->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($leave->user)) {
            $userName = trim(($leave->user->nom ?? '') . ' ' . ($leave->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $this->broadcastToRole(6, 'leave_request', 'Nouvelle demande de congé', 
            "{$userName} a demandé un congé", 
            [
                'leave_id' => $leave->id,
                'entity_type' => 'leave_request',
                'entity_id' => (string)$leave->id,
                'action_route' => "/conges/{$leave->id}"
            ], 
            isset($leave->urgent) && $leave->urgent ? 'urgente' : 'normale');
    }

    public function notifyLeaveRequestApproved($leave)
    {
        $userId = $leave->employee_id ?? $leave->created_by ?? $leave->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'leave_request', 'Congé approuvé', 
                'Votre demande de congé a été approuvée', 
                ['leave_id' => $leave->id]);
        }
    }

    public function notifyLeaveRequestRejected($leave, $reason)
    {
        $userId = $leave->employee_id ?? $leave->created_by ?? $leave->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'leave_request', 'Congé rejeté', 
                "Votre demande de congé a été rejetée. Raison : {$reason}", 
                ['leave_id' => $leave->id, 'raison' => $reason]);
        }
    }

    // Contrat
    public function notifyNewContrat($contrat)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$contrat->relationLoaded('user') && isset($contrat->user_id)) {
            $contrat->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($contrat->user)) {
            $userName = trim(($contrat->user->nom ?? '') . ' ' . ($contrat->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $contrat->contract_number ?? $contrat->numero_contrat ?? $contrat->id;
        $this->broadcastToRole(6, 'contrat', 'Nouveau contrat', 
            "{$userName} a créé un contrat #{$identifier}", 
            [
                'contrat_id' => $contrat->id,
                'entity_type' => 'contrat',
                'entity_id' => (string)$contrat->id,
                'action_route' => "/contrats/{$contrat->id}"
            ]);
    }

    public function notifyContratValidated($contrat)
    {
        $identifier = $contrat->contract_number ?? $contrat->numero_contrat ?? $contrat->id;
        $userId = $contrat->employee_id ?? $contrat->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'contrat', 'Contrat validé', 
                "Votre contrat #{$identifier} a été validé", 
                ['contrat_id' => $contrat->id]);
        }
    }

    public function notifyContratRejected($contrat, $reason)
    {
        $identifier = $contrat->contract_number ?? $contrat->numero_contrat ?? $contrat->id;
        $userId = $contrat->employee_id ?? $contrat->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'contrat', 'Contrat rejeté', 
                "Votre contrat #{$identifier} a été rejeté. Raison : {$reason}", 
                ['contrat_id' => $contrat->id, 'raison' => $reason]);
        }
    }

    // Recrutement
    public function notifyNewRecrutement($recrutement)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$recrutement->relationLoaded('user') && isset($recrutement->user_id)) {
            $recrutement->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($recrutement->user)) {
            $userName = trim(($recrutement->user->nom ?? '') . ' ' . ($recrutement->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $recrutement->poste ?? $recrutement->id;
        $this->broadcastToRole(6, 'recrutement', 'Nouveau recrutement', 
            "{$userName} a créé une demande de recrutement pour le poste : {$identifier}", 
            [
                'recrutement_id' => $recrutement->id,
                'entity_type' => 'recrutement',
                'entity_id' => (string)$recrutement->id,
                'action_route' => "/recrutements/{$recrutement->id}"
            ]);
    }

    public function notifyRecrutementValidated($recrutement)
    {
        $identifier = $recrutement->poste ?? $recrutement->id;
        $userId = $recrutement->created_by ?? $recrutement->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'recrutement', 'Recrutement validé', 
                "Votre demande de recrutement pour le poste \"{$identifier}\" a été validée", 
                ['recrutement_id' => $recrutement->id]);
        }
    }

    public function notifyRecrutementRejected($recrutement, $reason)
    {
        $identifier = $recrutement->poste ?? $recrutement->id;
        $userId = $recrutement->created_by ?? $recrutement->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'recrutement', 'Recrutement rejeté', 
                "Votre demande de recrutement pour le poste \"{$identifier}\" a été rejetée. Raison : {$reason}", 
                ['recrutement_id' => $recrutement->id, 'raison' => $reason]);
        }
    }

    // Employé
    public function notifyNewEmploye($employe)
    {
        // Charger la relation user si elle n'est pas déjà chargée
        if (!$employe->relationLoaded('user') && isset($employe->user_id)) {
            $employe->load('user');
        }
        
        $userName = 'Un utilisateur';
        if (isset($employe->user)) {
            $userName = trim(($employe->user->nom ?? '') . ' ' . ($employe->user->prenom ?? ''));
            if (empty($userName)) {
                $userName = 'Un utilisateur';
            }
        }
        
        $identifier = $employe->first_name ?? $employe->nom ?? $employe->last_name ?? $employe->prenom ?? $employe->id;
        $this->broadcastToRole(6, 'employe', 'Nouvel employé', 
            "{$userName} a soumis un nouvel employé : {$identifier} pour validation", 
            [
                'employe_id' => $employe->id,
                'entity_type' => 'employe',
                'entity_id' => (string)$employe->id,
                'action_route' => "/employes/{$employe->id}"
            ]);
    }

    public function notifyEmployeValidated($employe)
    {
        $identifier = $employe->first_name ?? $employe->nom ?? $employe->last_name ?? $employe->prenom ?? $employe->id;
        $userId = $employe->created_by ?? $employe->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'employe', 'Employé validé', 
                "L'employé \"{$identifier}\" a été validé", 
                ['employe_id' => $employe->id]);
        }
    }

    public function notifyEmployeRejected($employe, $reason)
    {
        $identifier = $employe->first_name ?? $employe->nom ?? $employe->last_name ?? $employe->prenom ?? $employe->id;
        $userId = $employe->created_by ?? $employe->user_id;
        if ($userId) {
            $this->createAndBroadcast($userId, 'employe', 'Employé rejeté', 
                "L'employé \"{$identifier}\" a été rejeté. Raison : {$reason}", 
                ['employe_id' => $employe->id, 'raison' => $reason]);
        }
    }

    // --- TÂCHES ---

    /**
     * Notifier l'utilisateur à qui une tâche est assignée.
     */
    public function notifyTaskAssigned($task)
    {
        $task->load(['assignedBy', 'assignedTo']);
        $assignerName = 'La direction';
        if ($task->assignedBy) {
            $assignerName = trim(($task->assignedBy->prenom ?? '') . ' ' . ($task->assignedBy->nom ?? ''));
            if (empty($assignerName)) {
                $assignerName = 'La direction';
            }
        }
        $this->createAndBroadcast(
            $task->assigned_to,
            'task',
            'Nouvelle tâche assignée',
            "{$assignerName} vous a assigné une tâche : {$task->titre}",
            [
                'task_id' => $task->id,
                'entity_type' => 'task',
                'entity_id' => (string) $task->id,
                'action_route' => '/tasks/' . $task->id,
            ],
            $task->priority === 'urgent' || $task->priority === 'high' ? 'haute' : 'normale'
        );
    }

    /**
     * Notifier le patron (celui qui a assigné) lorsqu'une tâche est terminée.
     */
    public function notifyTaskCompleted($task)
    {
        $task->load(['assignedBy', 'assignedTo']);
        $assigneeName = 'Un utilisateur';
        if ($task->assignedTo) {
            $assigneeName = trim(($task->assignedTo->prenom ?? '') . ' ' . ($task->assignedTo->nom ?? ''));
            if (empty($assigneeName)) {
                $assigneeName = 'Un utilisateur';
            }
        }
        $this->createAndBroadcast(
            $task->assigned_by,
            'task',
            'Tâche terminée',
            "{$assigneeName} a terminé la tâche : {$task->titre}",
            [
                'task_id' => $task->id,
                'entity_type' => 'task',
                'entity_id' => (string) $task->id,
                'action_route' => '/tasks/' . $task->id,
            ],
            'normale'
        );
    }
}