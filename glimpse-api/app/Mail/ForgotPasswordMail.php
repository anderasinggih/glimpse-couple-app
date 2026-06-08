<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class ForgotPasswordMail extends Mailable
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
            subject: 'Reset Your Glimpse Password',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.forgot_password',
        );
    }
}
