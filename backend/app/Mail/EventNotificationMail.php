<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class EventNotificationMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $titre;

    /** Corps du message (nommé $body pour éviter le conflit avec la variable réservée $message de Laravel Mail). */
    public string $body;

    public ?string $actionUrl;
    public ?string $actionLabel;
    public ?string $recipientName;

    /**
     * @param string $titre Titre de l'email / sujet
     * @param string $body Corps du message
     * @param string|null $actionUrl URL optionnelle (ex: lien vers l'app ou une page)
     * @param string|null $actionLabel Libellé du bouton (ex: "Voir dans l'application")
     * @param string|null $recipientName Nom du destinataire pour personnaliser
     */
    public function __construct(
        string $titre,
        string $body,
        ?string $actionUrl = null,
        ?string $actionLabel = null,
        ?string $recipientName = null
    ) {
        $this->titre = $titre;
        $this->body = $body;
        $this->actionUrl = $actionUrl;
        $this->actionLabel = $actionLabel ?? 'Voir dans l\'application';
        $this->recipientName = $recipientName;
    }

    public function envelope(): Envelope
    {
        $appName = config('app.name', 'EasyConnect');
        return new Envelope(
            subject: "[{$appName}] {$this->titre}",
            from: config('mail.from.address'),
            replyTo: [config('mail.from.address')],
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.event_notification',
        );
    }
}
