<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('couples', function (Blueprint $table) {
            $table->id();
            $table->timestamp('anniversary_start_date');
            $table->boolean('is_active')->default(false);
            $table->unsignedBigInteger('invited_by')->nullable();
            $table->unsignedBigInteger('disconnect_requested_by')->nullable();
            $table->timestamps();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('couple_id')->nullable()->constrained('couples');
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->string('location_name')->nullable();
            $table->string('status_note')->nullable();
            $table->integer('battery_level')->default(100);
            $table->boolean('is_charging')->default(false);
            $table->string('latest_photo_url')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['couple_id']);
            $table->dropColumn(['couple_id', 'latitude', 'longitude', 'location_name', 'status_note', 'battery_level', 'is_charging', 'latest_photo_url']);
        });
        Schema::dropIfExists('couples');
    }
};
