<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->index(['couple_id', 'room_id', 'created_at'], 'idx_messages_couple_room_created');
        });

        Schema::table('flashes', function (Blueprint $table) {
            $table->index(['couple_id', 'created_at'], 'idx_flashes_couple_created');
        });

        Schema::table('schedules', function (Blueprint $table) {
            $table->index(['couple_id', 'scheduled_at'], 'idx_schedules_couple_scheduled');
        });
    }

    public function down(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->dropIndex('idx_messages_couple_room_created');
        });

        Schema::table('flashes', function (Blueprint $table) {
            $table->dropIndex('idx_flashes_couple_created');
        });

        Schema::table('schedules', function (Blueprint $table) {
            $table->dropIndex('idx_schedules_couple_scheduled');
        });
    }
};
