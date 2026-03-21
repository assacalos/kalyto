<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Models\RecruitmentDocument;
use App\Models\RecruitmentApplication;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;

class RecruitmentDocumentController extends Controller
{
    /**
     * Liste des documents
     */
    public function index(Request $request)
    {
        try {
            $query = RecruitmentDocument::with(['application']);

            // Filtrage par candidature
            if ($request->has('application_id')) {
                $query->where('application_id', $request->application_id);
            }

            // Filtrage par type
            if ($request->has('file_type')) {
                $query->where('file_type', $request->file_type);
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $documents = $query->orderBy('uploaded_at', 'desc')->paginate($perPage);

            $data = $documents->getCollection()->map(function ($document) {
                return $this->formatDocument($document);
            })->values();

            return response()->json([
                'success' => true,
                'data' => $data,
                'pagination' => [
                    'current_page' => $documents->currentPage(),
                    'last_page' => $documents->lastPage(),
                    'per_page' => $documents->perPage(),
                    'total' => $documents->total(),
                    'from' => $documents->firstItem(),
                    'to' => $documents->lastItem(),
                ],
                'message' => 'Liste des documents récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des documents: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un document spécifique
     */
    public function show($id)
    {
        try {
            $document = RecruitmentDocument::with(['application'])->find($id);

            if (!$document) {
                return response()->json([
                    'success' => false,
                    'message' => 'Document non trouvé'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $this->formatDocument($document),
                'message' => 'Document récupéré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération du document: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouveau document
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'application_id' => 'required|exists:recruitment_applications,id',
                'file' => 'required|file|max:10240', // 10MB max
            ]);

            // Vérifier que la candidature existe
            $application = RecruitmentApplication::find($validated['application_id']);
            if (!$application) {
                return response()->json([
                    'success' => false,
                    'message' => 'Candidature non trouvée'
                ], 404);
            }

            DB::beginTransaction();

            $file = $request->file('file');
            $fileName = time() . '_' . $file->getClientOriginalName();
            $filePath = $file->storeAs('recruitment/documents', $fileName, 'public');
            $fileType = $file->getClientMimeType();
            $fileSize = $file->getSize();

            $document = RecruitmentDocument::create([
                'application_id' => $validated['application_id'],
                'file_name' => $file->getClientOriginalName(),
                'file_path' => $filePath,
                'file_type' => $fileType,
                'file_size' => $fileSize,
                'uploaded_at' => now()
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $this->formatDocument($document->load(['application'])),
                'message' => 'Document créé avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du document: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un document
     */
    public function update(Request $request, $id)
    {
        try {
            $document = RecruitmentDocument::find($id);

            if (!$document) {
                return response()->json([
                    'success' => false,
                    'message' => 'Document non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'file' => 'sometimes|file|max:10240',
            ]);

            if ($request->hasFile('file')) {
                // Supprimer l'ancien fichier
                if (Storage::disk('public')->exists($document->file_path)) {
                    Storage::disk('public')->delete($document->file_path);
                }

                $file = $request->file('file');
                $fileName = time() . '_' . $file->getClientOriginalName();
                $filePath = $file->storeAs('recruitment/documents', $fileName, 'public');
                $fileType = $file->getClientMimeType();
                $fileSize = $file->getSize();

                $document->updateFile(
                    $file->getClientOriginalName(),
                    $filePath,
                    $fileType,
                    $fileSize
                );
            }

            return response()->json([
                'success' => true,
                'data' => $this->formatDocument($document->load(['application'])),
                'message' => 'Document mis à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du document: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un document
     */
    public function destroy($id)
    {
        try {
            $document = RecruitmentDocument::find($id);

            if (!$document) {
                return response()->json([
                    'success' => false,
                    'message' => 'Document non trouvé'
                ], 404);
            }

            // Supprimer le fichier
            if (Storage::disk('public')->exists($document->file_path)) {
                Storage::disk('public')->delete($document->file_path);
            }

            $document->delete();

            return response()->json([
                'success' => true,
                'message' => 'Document supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression du document: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Télécharger un document
     */
    public function download($id)
    {
        try {
            $document = RecruitmentDocument::find($id);

            if (!$document) {
                return response()->json([
                    'success' => false,
                    'message' => 'Document non trouvé'
                ], 404);
            }

            if (!Storage::disk('public')->exists($document->file_path)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Fichier non trouvé'
                ], 404);
            }

            // Utiliser streamDownload pour éviter les problèmes de mémoire
            // Ajouter les headers appropriés pour les téléchargements
            return Storage::disk('public')->download($document->file_path, $document->file_name, [
                'Content-Type' => $document->file_type ?? 'application/octet-stream',
                'Content-Disposition' => 'attachment; filename="' . $document->file_name . '"',
                'Content-Length' => $document->file_size ?? Storage::disk('public')->size($document->file_path),
            ]);

        } catch (\Exception $e) {
            \Log::error('Recruitment document download error', [
                'document_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du téléchargement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Formater un document au format Flutter
     */
    private function formatDocument($document)
    {
        return [
            'id' => $document->id,
            'application_id' => $document->application_id,
            'file_name' => $document->file_name,
            'file_path' => $document->file_path,
            'file_type' => $document->file_type,
            'file_size' => $document->file_size,
            'uploaded_at' => $document->uploaded_at->format('Y-m-d\TH:i:s'),
        ];
    }
}

