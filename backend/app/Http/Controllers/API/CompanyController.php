<?php

namespace App\Http\Controllers\API;

use App\Models\Company;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class CompanyController extends Controller
{
    /**
     * Liste des sociétés (pour le sélecteur multi-société).
     * Inclut logo_url et signature_url pour les PDF.
     * GET /api/companies
     */
    public function index(Request $request)
    {
        $companies = Company::orderBy('name')->get();

        return response()->json([
            'success' => true,
            'data' => $companies,
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Upload du logo de la société (pour en-tête PDF).
     * POST /api/companies/{id}/logo
     */
    public function uploadLogo(Request $request, int $id)
    {
        $request->validate([
            'logo' => 'required|image|mimes:jpeg,jpg,png,gif,webp|max:2048',
        ]);

        $company = Company::findOrFail($id);
        $file = $request->file('logo');
        $dir = 'company/' . $id;
        $oldPath = $company->logo_path;

        $path = $file->storeAs($dir, 'logo.' . Str::lower($file->getClientOriginalExtension() ?: 'png'), 'public');
        $company->update(['logo_path' => $path]);

        if ($oldPath && $oldPath !== $path) {
            Storage::disk('public')->delete($oldPath);
        }

        return response()->json([
            'success' => true,
            'message' => 'Logo enregistré.',
            'logo_url' => $company->fresh()->logo_url,
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Upload de la signature (pour pied de page PDF).
     * POST /api/companies/{id}/signature
     */
    public function uploadSignature(Request $request, int $id)
    {
        $request->validate([
            'signature' => 'required|image|mimes:jpeg,jpg,png,gif,webp|max:2048',
        ]);

        $company = Company::findOrFail($id);
        $file = $request->file('signature');
        $dir = 'company/' . $id;
        $oldPath = $company->signature_path;

        $path = $file->storeAs($dir, 'signature.' . Str::lower($file->getClientOriginalExtension() ?: 'png'), 'public');
        $company->update(['signature_path' => $path]);

        if ($oldPath && $oldPath !== $path) {
            Storage::disk('public')->delete($oldPath);
        }

        return response()->json([
            'success' => true,
            'message' => 'Signature enregistrée.',
            'signature_url' => $company->fresh()->signature_url,
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Servir le logo (GET avec auth pour les PDF).
     * GET /api/companies/{id}/logo
     */
    public function showLogo(int $id)
    {
        $company = Company::findOrFail($id);
        if (empty($company->logo_path)) {
            return response()->json(['message' => 'Logo non configuré'], 404);
        }
        $path = Storage::disk('public')->path($company->logo_path);
        if (!is_file($path)) {
            return response()->json(['message' => 'Fichier introuvable'], 404);
        }
        $mime = mime_content_type($path) ?: 'image/png';
        return response()->file($path, ['Content-Type' => $mime]);
    }

    /**
     * Servir la signature (GET avec auth pour les PDF).
     * GET /api/companies/{id}/signature
     */
    public function showSignature(int $id)
    {
        $company = Company::findOrFail($id);
        if (empty($company->signature_path)) {
            return response()->json(['message' => 'Signature non configurée'], 404);
        }
        $path = Storage::disk('public')->path($company->signature_path);
        if (!is_file($path)) {
            return response()->json(['message' => 'Fichier introuvable'], 404);
        }
        $mime = mime_content_type($path) ?: 'image/png';
        return response()->file($path, ['Content-Type' => $mime]);
    }
}
