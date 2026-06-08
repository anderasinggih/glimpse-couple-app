<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class EmailVerificationMail extends Mailable
{
    use Queueable, SerializesModels;

    public $name;
    public $otp;

    public function __construct($user, $otp)
    {
        $this->name = $user->name;
        $this->otp = $otp;
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Verify Your Glimpse Account',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.verification',
        );
    }
}
