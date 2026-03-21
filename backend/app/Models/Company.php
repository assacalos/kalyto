<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;

class Company extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'code',
        'ninea',
        'address',
        'logo_path',
        'signature_path',
    ];

    protected $appends = ['logo_url', 'signature_url'];

    /**
     * URL du logo via l'API (authentifiée), pour l'app et les PDF.
     */
    public function getLogoUrlAttribute(): ?string
    {
        if (empty($this->logo_path) || !Storage::disk('public')->exists($this->logo_path)) {
            return null;
        }
        return url('/api/companies/' . $this->id . '/logo');
    }

    /**
     * URL de la signature via l'API (authentifiée), pour les PDF.
     */
    public function getSignatureUrlAttribute(): ?string
    {
        if (empty($this->signature_path) || !Storage::disk('public')->exists($this->signature_path)) {
            return null;
        }
        return url('/api/companies/' . $this->id . '/signature');
    }
}
