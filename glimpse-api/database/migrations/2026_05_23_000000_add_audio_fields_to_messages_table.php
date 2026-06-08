<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->boolean('is_audio')->default(false);
            $table->string('audio_path')->nullable();
            $table->double('audio_duration')->nullable();
            $table->boolean('audio_expired')->default(false);
        });
    }

    public function down(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->dropColumn(['is_audio', 'audio_path', 'audio_duration', 'audio_expired']);
        });
    }
};
