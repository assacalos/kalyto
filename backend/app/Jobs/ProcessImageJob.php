<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class ProcessImageJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Le nombre de fois que le job peut être tenté.
     *
     * @var int
     */
    public $tries = 3;

    /**
     * Le nombre de secondes à attendre avant de réessayer le job.
     *
     * @var int
     */
    public $backoff = [10, 30, 60];

    /**
     * Chemin de l'image source
     *
     * @var string
     */
    protected $imagePath;

    /**
     * Options de traitement
     *
     * @var array
     */
    protected $options;

    /**
     * Créer une nouvelle instance du job.
     *
     * @param string $imagePath
     * @param array $options
     */
    public function __construct(string $imagePath, array $options = [])
    {
        $this->imagePath = $imagePath;
        $this->options = $options;
    }

    /**
     * Exécuter le job.
     *
     * @return void
     */
    public function handle()
    {
        try {
            $disk = $this->options['disk'] ?? 'public';
            $fullPath = Storage::disk($disk)->path($this->imagePath);

            // Vérifier que le fichier existe
            if (!Storage::disk($disk)->exists($this->imagePath)) {
                Log::warning("Image non trouvée: {$this->imagePath}");
                return;
            }

            // Si Intervention Image est disponible, traiter l'image
            if (class_exists('Intervention\Image\ImageManager')) {
                try {
                    $manager = new \Intervention\Image\ImageManager(['driver' => 'gd']);
                    $image = $manager->make($fullPath);

                    // Redimensionner si nécessaire
                    if (isset($this->options['width']) || isset($this->options['height'])) {
                        $width = $this->options['width'] ?? null;
                        $height = $this->options['height'] ?? null;
                        $image->resize($width, $height, function ($constraint) {
                            $constraint->aspectRatio();
                            $constraint->upsize();
                        });
                    }

                    // Créer une miniature si demandée
                    if (isset($this->options['thumbnail'])) {
                        $thumbnailPath = $this->getThumbnailPath($this->imagePath);
                        $thumbnail = $manager->make($fullPath);
                        $thumbnail->fit(
                            $this->options['thumbnail']['width'] ?? 200,
                            $this->options['thumbnail']['height'] ?? 200
                        );
                        $thumbnail->save(Storage::disk($disk)->path($thumbnailPath));
                    }

                    // Optimiser la qualité si demandée
                    if (isset($this->options['quality'])) {
                        $image->save($fullPath, $this->options['quality']);
                    } else {
                        $image->save();
                    }

                    Log::info("Image traitée avec succès", ['path' => $this->imagePath]);
                } catch (\Exception $e) {
                    Log::warning("Erreur lors du traitement de l'image avec Intervention Image", [
                        'error' => $e->getMessage(),
                        'path' => $this->imagePath
                    ]);
                }
            } else {
                Log::info("Intervention Image non disponible, image sauvegardée sans traitement", ['path' => $this->imagePath]);
            }

        } catch (\Exception $e) {
            Log::error('Erreur lors du traitement de l\'image', [
                'error' => $e->getMessage(),
                'path' => $this->imagePath
            ]);
            throw $e;
        }
    }

    /**
     * Générer le chemin de la miniature
     *
     * @param string $originalPath
     * @return string
     */
    protected function getThumbnailPath(string $originalPath): string
    {
        $pathInfo = pathinfo($originalPath);
        return $pathInfo['dirname'] . '/' . $pathInfo['filename'] . '_thumb.' . $pathInfo['extension'];
    }

    /**
     * Gérer l'échec du job.
     *
     * @param \Throwable $exception
     * @return void
     */
    public function failed(\Throwable $exception)
    {
        Log::error('Échec du traitement de l\'image', [
            'error' => $exception->getMessage(),
            'path' => $this->imagePath
        ]);
    }
}
