<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('admin_tokens', function (Blueprint $table) {
            $table->id();
            $table->string('token_hash');
            $table->timestamps();
        });

        // Seed with the default token hashed: "LVNPC2026123"
        DB::table('admin_tokens')->insert([
            'token_hash' => password_hash('LVNPC2026123', PASSWORD_BCRYPT),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('admin_tokens');
    }
};
