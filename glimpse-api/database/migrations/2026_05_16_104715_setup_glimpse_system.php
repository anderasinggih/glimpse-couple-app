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
            $table->timestamps();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('couple_id')->nullable()->constrained('couples');
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->string('location_name')->nullable();
            $table->string('status_note')->nullable();
            $table->integer('battery_level')->default(100);
            $table->string('latest_photo_url')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['couple_id']);
            $table->dropColumn(['couple_id', 'latitude', 'longitude', 'location_name', 'status_note', 'battery_level', 'latest_photo_url']);
        });
        Schema::dropIfExists('couples');
    }
};
