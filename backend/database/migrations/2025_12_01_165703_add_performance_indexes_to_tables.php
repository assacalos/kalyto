<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Ajoute des index sur user_id, client_id, status, et created_at
     * pour optimiser les performances des requêtes de recherche, tri et jointures.
     */
    public function up(): void
    {
        // Table clients
        if (Schema::hasTable('clients')) {
            Schema::table('clients', function (Blueprint $table) {
                if (Schema::hasColumn('clients', 'user_id') && !$this->hasIndex('clients', 'clients_user_id_index')) {
                    $table->index('user_id', 'clients_user_id_index');
                }
                if (Schema::hasColumn('clients', 'status') && !$this->hasIndex('clients', 'clients_status_index')) {
                    $table->index('status', 'clients_status_index');
                }
                if (Schema::hasColumn('clients', 'created_at') && !$this->hasIndex('clients', 'clients_created_at_index')) {
                    $table->index('created_at', 'clients_created_at_index');
                }
            });
        }

        // Table notifications
        if (Schema::hasTable('notifications')) {
            Schema::table('notifications', function (Blueprint $table) {
                if (Schema::hasColumn('notifications', 'user_id') && !$this->hasIndex('notifications', 'notifications_user_id_index')) {
                    $table->index('user_id', 'notifications_user_id_index');
                }
                if (Schema::hasColumn('notifications', 'created_at') && !$this->hasIndex('notifications', 'notifications_created_at_index')) {
                    $table->index('created_at', 'notifications_created_at_index');
                }
                // Index composite pour les requêtes fréquentes (user_id + created_at)
                if (Schema::hasColumn('notifications', 'user_id') && Schema::hasColumn('notifications', 'created_at') && !$this->hasIndex('notifications', 'notifications_user_id_created_at_index')) {
                    $table->index(['user_id', 'created_at'], 'notifications_user_id_created_at_index');
                }
            });
        }

        // Table factures
        if (Schema::hasTable('factures')) {
            Schema::table('factures', function (Blueprint $table) {
                if (Schema::hasColumn('factures', 'client_id') && !$this->hasIndex('factures', 'factures_client_id_index')) {
                    $table->index('client_id', 'factures_client_id_index');
                }
                if (Schema::hasColumn('factures', 'user_id') && !$this->hasIndex('factures', 'factures_user_id_index')) {
                    $table->index('user_id', 'factures_user_id_index');
                }
                if (Schema::hasColumn('factures', 'statut') && !$this->hasIndex('factures', 'factures_statut_index')) {
                    $table->index('statut', 'factures_statut_index');
                } elseif (Schema::hasColumn('factures', 'status') && !$this->hasIndex('factures', 'factures_status_index')) {
                    $table->index('status', 'factures_status_index');
                }
                if (Schema::hasColumn('factures', 'created_at') && !$this->hasIndex('factures', 'factures_created_at_index')) {
                    $table->index('created_at', 'factures_created_at_index');
                }
            });
        }

        // Table paiements
        if (Schema::hasTable('paiements')) {
            Schema::table('paiements', function (Blueprint $table) {
                if (Schema::hasColumn('paiements', 'client_id') && !$this->hasIndex('paiements', 'paiements_client_id_index')) {
                    $table->index('client_id', 'paiements_client_id_index');
                }
                if (Schema::hasColumn('paiements', 'user_id') && !$this->hasIndex('paiements', 'paiements_user_id_index')) {
                    $table->index('user_id', 'paiements_user_id_index');
                }
                if (Schema::hasColumn('paiements', 'statut') && !$this->hasIndex('paiements', 'paiements_statut_index')) {
                    $table->index('statut', 'paiements_statut_index');
                } elseif (Schema::hasColumn('paiements', 'status') && !$this->hasIndex('paiements', 'paiements_status_index')) {
                    $table->index('status', 'paiements_status_index');
                }
                if (Schema::hasColumn('paiements', 'created_at') && !$this->hasIndex('paiements', 'paiements_created_at_index')) {
                    $table->index('created_at', 'paiements_created_at_index');
                }
            });
        }

        // Table devis
        if (Schema::hasTable('devis')) {
            Schema::table('devis', function (Blueprint $table) {
                if (Schema::hasColumn('devis', 'client_id') && !$this->hasIndex('devis', 'devis_client_id_index')) {
                    $table->index('client_id', 'devis_client_id_index');
                }
                if (Schema::hasColumn('devis', 'user_id') && !$this->hasIndex('devis', 'devis_user_id_index')) {
                    $table->index('user_id', 'devis_user_id_index');
                }
                if (Schema::hasColumn('devis', 'status') && !$this->hasIndex('devis', 'devis_status_index')) {
                    $table->index('status', 'devis_status_index');
                }
                if (Schema::hasColumn('devis', 'created_at') && !$this->hasIndex('devis', 'devis_created_at_index')) {
                    $table->index('created_at', 'devis_created_at_index');
                }
            });
        }

        // Table bordereaus
        if (Schema::hasTable('bordereaus')) {
            Schema::table('bordereaus', function (Blueprint $table) {
                if (Schema::hasColumn('bordereaus', 'client_id') && !$this->hasIndex('bordereaus', 'bordereaus_client_id_index')) {
                    $table->index('client_id', 'bordereaus_client_id_index');
                }
                if (Schema::hasColumn('bordereaus', 'user_id') && !$this->hasIndex('bordereaus', 'bordereaus_user_id_index')) {
                    $table->index('user_id', 'bordereaus_user_id_index');
                }
                if (Schema::hasColumn('bordereaus', 'status') && !$this->hasIndex('bordereaus', 'bordereaus_status_index')) {
                    $table->index('status', 'bordereaus_status_index');
                }
                if (Schema::hasColumn('bordereaus', 'created_at') && !$this->hasIndex('bordereaus', 'bordereaus_created_at_index')) {
                    $table->index('created_at', 'bordereaus_created_at_index');
                }
            });
        }

        // Table conges
        if (Schema::hasTable('conges')) {
            Schema::table('conges', function (Blueprint $table) {
                if (Schema::hasColumn('conges', 'user_id') && !$this->hasIndex('conges', 'conges_user_id_index')) {
                    $table->index('user_id', 'conges_user_id_index');
                }
                if (Schema::hasColumn('conges', 'statut') && !$this->hasIndex('conges', 'conges_statut_index')) {
                    $table->index('statut', 'conges_statut_index');
                }
                if (Schema::hasColumn('conges', 'created_at') && !$this->hasIndex('conges', 'conges_created_at_index')) {
                    $table->index('created_at', 'conges_created_at_index');
                }
            });
        }

        // Table interventions
        if (Schema::hasTable('interventions')) {
            Schema::table('interventions', function (Blueprint $table) {
                if (Schema::hasColumn('interventions', 'client_id') && !$this->hasIndex('interventions', 'interventions_client_id_index')) {
                    $table->index('client_id', 'interventions_client_id_index');
                }
                if (Schema::hasColumn('interventions', 'created_by') && !$this->hasIndex('interventions', 'interventions_created_by_index')) {
                    $table->index('created_by', 'interventions_created_by_index');
                }
                if (Schema::hasColumn('interventions', 'status') && !$this->hasIndex('interventions', 'interventions_status_index')) {
                    $table->index('status', 'interventions_status_index');
                }
                if (Schema::hasColumn('interventions', 'created_at') && !$this->hasIndex('interventions', 'interventions_created_at_index')) {
                    $table->index('created_at', 'interventions_created_at_index');
                }
            });
        }

        // Table employees
        if (Schema::hasTable('employees')) {
            Schema::table('employees', function (Blueprint $table) {
                if (Schema::hasColumn('employees', 'created_by') && !$this->hasIndex('employees', 'employees_created_by_index')) {
                    $table->index('created_by', 'employees_created_by_index');
                }
                if (Schema::hasColumn('employees', 'status') && !$this->hasIndex('employees', 'employees_status_index')) {
                    $table->index('status', 'employees_status_index');
                }
                if (Schema::hasColumn('employees', 'created_at') && !$this->hasIndex('employees', 'employees_created_at_index')) {
                    $table->index('created_at', 'employees_created_at_index');
                }
            });
        }

        // Table bon_de_commandes
        if (Schema::hasTable('bon_de_commandes')) {
            Schema::table('bon_de_commandes', function (Blueprint $table) {
                if (Schema::hasColumn('bon_de_commandes', 'user_id') && !$this->hasIndex('bon_de_commandes', 'bon_de_commandes_user_id_index')) {
                    $table->index('user_id', 'bon_de_commandes_user_id_index');
                }
                if (Schema::hasColumn('bon_de_commandes', 'statut') && !$this->hasIndex('bon_de_commandes', 'bon_de_commandes_statut_index')) {
                    $table->index('statut', 'bon_de_commandes_statut_index');
                }
                if (Schema::hasColumn('bon_de_commandes', 'created_at') && !$this->hasIndex('bon_de_commandes', 'bon_de_commandes_created_at_index')) {
                    $table->index('created_at', 'bon_de_commandes_created_at_index');
                }
            });
        }

        // Table commandes_entreprise
        if (Schema::hasTable('commandes_entreprise')) {
            Schema::table('commandes_entreprise', function (Blueprint $table) {
                if (Schema::hasColumn('commandes_entreprise', 'user_id') && !$this->hasIndex('commandes_entreprise', 'commandes_entreprise_user_id_index')) {
                    $table->index('user_id', 'commandes_entreprise_user_id_index');
                }
                if (Schema::hasColumn('commandes_entreprise', 'status') && !$this->hasIndex('commandes_entreprise', 'commandes_entreprise_status_index')) {
                    $table->index('status', 'commandes_entreprise_status_index');
                }
                if (Schema::hasColumn('commandes_entreprise', 'created_at') && !$this->hasIndex('commandes_entreprise', 'commandes_entreprise_created_at_index')) {
                    $table->index('created_at', 'commandes_entreprise_created_at_index');
                }
            });
        }

        // Table reportings
        if (Schema::hasTable('reportings')) {
            Schema::table('reportings', function (Blueprint $table) {
                if (Schema::hasColumn('reportings', 'user_id') && !$this->hasIndex('reportings', 'reportings_user_id_index')) {
                    $table->index('user_id', 'reportings_user_id_index');
                }
                if (Schema::hasColumn('reportings', 'status') && !$this->hasIndex('reportings', 'reportings_status_index')) {
                    $table->index('status', 'reportings_status_index');
                }
                if (Schema::hasColumn('reportings', 'created_at') && !$this->hasIndex('reportings', 'reportings_created_at_index')) {
                    $table->index('created_at', 'reportings_created_at_index');
                }
            });
        }

        // Table evaluations
        if (Schema::hasTable('evaluations')) {
            Schema::table('evaluations', function (Blueprint $table) {
                if (Schema::hasColumn('evaluations', 'user_id') && !$this->hasIndex('evaluations', 'evaluations_user_id_index')) {
                    $table->index('user_id', 'evaluations_user_id_index');
                }
                // Note: La table evaluations utilise 'statut' et non 'status'
                if (Schema::hasColumn('evaluations', 'statut') && !$this->hasIndex('evaluations', 'evaluations_statut_index')) {
                    $table->index('statut', 'evaluations_statut_index');
                }
                if (Schema::hasColumn('evaluations', 'created_at') && !$this->hasIndex('evaluations', 'evaluations_created_at_index')) {
                    $table->index('created_at', 'evaluations_created_at_index');
                }
            });
        }

        // Table pointages
        if (Schema::hasTable('pointages')) {
            Schema::table('pointages', function (Blueprint $table) {
                if (Schema::hasColumn('pointages', 'user_id') && !$this->hasIndex('pointages', 'pointages_user_id_index')) {
                    $table->index('user_id', 'pointages_user_id_index');
                }
                // Vérifier si la colonne existe avant d'ajouter l'index
                if (Schema::hasColumn('pointages', 'statut') && !$this->hasIndex('pointages', 'pointages_statut_index')) {
                    $table->index('statut', 'pointages_statut_index');
                } elseif (Schema::hasColumn('pointages', 'status') && !$this->hasIndex('pointages', 'pointages_status_index')) {
                    $table->index('status', 'pointages_status_index');
                }
                if (Schema::hasColumn('pointages', 'created_at') && !$this->hasIndex('pointages', 'pointages_created_at_index')) {
                    $table->index('created_at', 'pointages_created_at_index');
                }
            });
        }

        // Table attendances
        if (Schema::hasTable('attendances')) {
            Schema::table('attendances', function (Blueprint $table) {
                if (Schema::hasColumn('attendances', 'user_id') && !$this->hasIndex('attendances', 'attendances_user_id_index')) {
                    $table->index('user_id', 'attendances_user_id_index');
                }
                // Vérifier si la colonne existe avant d'ajouter l'index
                if (Schema::hasColumn('attendances', 'status') && !$this->hasIndex('attendances', 'attendances_status_index')) {
                    $table->index('status', 'attendances_status_index');
                }
                if (Schema::hasColumn('attendances', 'created_at') && !$this->hasIndex('attendances', 'attendances_created_at_index')) {
                    $table->index('created_at', 'attendances_created_at_index');
                }
            });
        }

        // Table contracts
        if (Schema::hasTable('contracts')) {
            Schema::table('contracts', function (Blueprint $table) {
                if (Schema::hasColumn('contracts', 'employee_id') && !$this->hasIndex('contracts', 'contracts_employee_id_index')) {
                    $table->index('employee_id', 'contracts_employee_id_index');
                }
                if (Schema::hasColumn('contracts', 'status') && !$this->hasIndex('contracts', 'contracts_status_index')) {
                    $table->index('status', 'contracts_status_index');
                }
                if (Schema::hasColumn('contracts', 'created_at') && !$this->hasIndex('contracts', 'contracts_created_at_index')) {
                    $table->index('created_at', 'contracts_created_at_index');
                }
            });
        }

        // Table recruitment_requests
        if (Schema::hasTable('recruitment_requests')) {
            Schema::table('recruitment_requests', function (Blueprint $table) {
                if (Schema::hasColumn('recruitment_requests', 'created_by') && !$this->hasIndex('recruitment_requests', 'recruitment_requests_created_by_index')) {
                    $table->index('created_by', 'recruitment_requests_created_by_index');
                }
                if (Schema::hasColumn('recruitment_requests', 'status') && !$this->hasIndex('recruitment_requests', 'recruitment_requests_status_index')) {
                    $table->index('status', 'recruitment_requests_status_index');
                }
                if (Schema::hasColumn('recruitment_requests', 'created_at') && !$this->hasIndex('recruitment_requests', 'recruitment_requests_created_at_index')) {
                    $table->index('created_at', 'recruitment_requests_created_at_index');
                }
            });
        }

        // Table expenses
        if (Schema::hasTable('expenses')) {
            Schema::table('expenses', function (Blueprint $table) {
                if (Schema::hasColumn('expenses', 'employee_id') && !$this->hasIndex('expenses', 'expenses_employee_id_index')) {
                    $table->index('employee_id', 'expenses_employee_id_index');
                } elseif (Schema::hasColumn('expenses', 'user_id') && !$this->hasIndex('expenses', 'expenses_user_id_index')) {
                    $table->index('user_id', 'expenses_user_id_index');
                }
                if (Schema::hasColumn('expenses', 'status') && !$this->hasIndex('expenses', 'expenses_status_index')) {
                    $table->index('status', 'expenses_status_index');
                }
                if (Schema::hasColumn('expenses', 'created_at') && !$this->hasIndex('expenses', 'expenses_created_at_index')) {
                    $table->index('created_at', 'expenses_created_at_index');
                }
            });
        }

        // Table salaries
        if (Schema::hasTable('salaries')) {
            Schema::table('salaries', function (Blueprint $table) {
                // La table salaries utilise employee_id et non user_id
                if (Schema::hasColumn('salaries', 'employee_id') && !$this->hasIndex('salaries', 'salaries_employee_id_index')) {
                    $table->index('employee_id', 'salaries_employee_id_index');
                }
                if (Schema::hasColumn('salaries', 'status') && !$this->hasIndex('salaries', 'salaries_status_index')) {
                    $table->index('status', 'salaries_status_index');
                }
                if (Schema::hasColumn('salaries', 'created_at') && !$this->hasIndex('salaries', 'salaries_created_at_index')) {
                    $table->index('created_at', 'salaries_created_at_index');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Supprimer les index ajoutés
        $tables = [
            'clients' => ['clients_user_id_index', 'clients_status_index', 'clients_created_at_index'],
            'notifications' => ['notifications_user_id_index', 'notifications_created_at_index', 'notifications_user_id_created_at_index'],
            'factures' => ['factures_client_id_index', 'factures_user_id_index', 'factures_statut_index', 'factures_status_index', 'factures_created_at_index'],
            'paiements' => ['paiements_client_id_index', 'paiements_user_id_index', 'paiements_statut_index', 'paiements_status_index', 'paiements_created_at_index'],
            'devis' => ['devis_client_id_index', 'devis_user_id_index', 'devis_status_index', 'devis_created_at_index'],
            'bordereaus' => ['bordereaus_client_id_index', 'bordereaus_user_id_index', 'bordereaus_status_index', 'bordereaus_created_at_index'],
            'conges' => ['conges_user_id_index', 'conges_statut_index', 'conges_created_at_index'],
            'interventions' => ['interventions_client_id_index', 'interventions_created_by_index', 'interventions_status_index', 'interventions_created_at_index'],
            'employees' => ['employees_created_by_index', 'employees_status_index', 'employees_created_at_index'],
            'bon_de_commandes' => ['bon_de_commandes_user_id_index', 'bon_de_commandes_statut_index', 'bon_de_commandes_created_at_index'],
            'commandes_entreprise' => ['commandes_entreprise_user_id_index', 'commandes_entreprise_status_index', 'commandes_entreprise_created_at_index'],
            'reportings' => ['reportings_user_id_index', 'reportings_status_index', 'reportings_created_at_index'],
            'evaluations' => ['evaluations_user_id_index', 'evaluations_statut_index', 'evaluations_created_at_index'],
            'pointages' => ['pointages_user_id_index', 'pointages_statut_index', 'pointages_status_index', 'pointages_created_at_index'],
            'attendances' => ['attendances_user_id_index', 'attendances_status_index', 'attendances_created_at_index'],
            'contracts' => ['contracts_employee_id_index', 'contracts_status_index', 'contracts_created_at_index'],
            'recruitment_requests' => ['recruitment_requests_created_by_index', 'recruitment_requests_status_index', 'recruitment_requests_created_at_index'],
            'expenses' => ['expenses_employee_id_index', 'expenses_user_id_index', 'expenses_status_index', 'expenses_created_at_index'],
            'salaries' => ['salaries_employee_id_index', 'salaries_status_index', 'salaries_created_at_index'],
        ];

        foreach ($tables as $tableName => $indexes) {
            if (Schema::hasTable($tableName)) {
                Schema::table($tableName, function (Blueprint $table) use ($indexes, $tableName) {
                    foreach ($indexes as $indexName) {
                        if ($this->hasIndex($tableName, $indexName)) {
                            $table->dropIndex($indexName);
                        }
                    }
                });
            }
        }
    }

    /**
     * Vérifie si un index existe déjà sur une table
     */
    private function hasIndex(string $table, string $indexName): bool
    {
        try {
            $connection = Schema::getConnection();
            $databaseName = $connection->getDatabaseName();
            
            // Pour SQLite, utiliser une approche différente
            if ($connection->getDriverName() === 'sqlite') {
                $indexes = DB::select("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name=? AND name=?", [$table, $indexName]);
                return count($indexes) > 0;
            }
            
            // Pour MySQL/MariaDB
            $result = DB::select(
                "SELECT COUNT(*) as count 
                 FROM information_schema.statistics 
                 WHERE table_schema = ? 
                 AND table_name = ? 
                 AND index_name = ?",
                [$databaseName, $table, $indexName]
            );

            return isset($result[0]) && $result[0]->count > 0;
        } catch (\Exception $e) {
            // En cas d'erreur, supposer que l'index n'existe pas
            return false;
        }
    }
};
