<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'invite_code')) {
                $table->string('invite_code')->nullable()->unique();
            }
            if (!Schema::hasColumn('users', 'couple_id')) {
                $table->string('couple_id')->nullable();
            }
            if (!Schema::hasColumn('users', 'latitude')) {
                $table->decimal('latitude', 10, 8)->nullable();
            }
            if (!Schema::hasColumn('users', 'longitude')) {
                $table->decimal('longitude', 11, 8)->nullable();
            }
            if (!Schema::hasColumn('users', 'battery_level')) {
                $table->integer('battery_level')->nullable();
            }
            if (!Schema::hasColumn('users', 'status_note')) {
                $table->string('status_note')->nullable();
            }
            if (!Schema::hasColumn('users', 'latest_photo_url')) {
                $table->string('latest_photo_url')->nullable();
            }
            if (!Schema::hasColumn('users', 'profile_photo_url')) {
                $table->string('profile_photo_url')->nullable();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'invite_code', 'couple_id', 'latitude', 'longitude', 
                'battery_level', 'status_note', 'latest_photo_url', 'profile_photo_url'
            ]);
        });
    }
};
