<!DOCTYPE html>
<html lang="en" class="h-full bg-slate-950">
<head>
    <script>
        // Active Authentication Protection Guard
        (function() {
            const token = localStorage.getItem('glimpse_admin_token');
            if (!token || token === 'undefined' || token === 'null' || token.trim() === '') {
                localStorage.removeItem('glimpse_admin_token');
                window.location.href = '/admin/login';
            }
        })();
    </script>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Glimpse Console — Admin Control Suite</title>
    <!-- Google Fonts & Tailwind CDN -->
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Outfit', 'sans-serif'],
                    },
                    colors: {
                        deepVelvet: '#0D001A',
                        electricPurple: '#BF80FF',
                        activeCyan: '#00FFFF',
                        royalPurple: '#7A28FF',
                    }
                }
            }
        }
    </script>
    <style>
        body {
            background-color: #0D001A;
            font-family: 'Outfit', sans-serif;
            color: #FFFFFF;
            overflow-x: hidden;
        }
        /* Custom Scrollbar */
        ::-webkit-scrollbar {
            width: 8px;
        }
        ::-webkit-scrollbar-track {
            background: rgba(255, 255, 255, 0.02);
        }
        ::-webkit-scrollbar-thumb {
            background: rgba(191, 128, 255, 0.3);
            border-radius: 4px;
        }
        ::-webkit-scrollbar-thumb:hover {
            background: rgba(191, 128, 255, 0.5);
        }
    </style>
</head>
<body class="h-full antialiased">
    
    <!-- Dynamic Futuristic Glowing Background Spheres -->
    <div class="fixed inset-0 z-0 pointer-events-none overflow-hidden">
        <div class="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] rounded-full bg-electricPurple/10 blur-[100px]"></div>
        <div class="absolute bottom-[-10%] right-[-10%] w-[600px] h-[600px] rounded-full bg-royalPurple/10 blur-[120px]"></div>
        <div class="absolute top-[40%] right-[20%] w-[400px] h-[400px] rounded-full bg-activeCyan/5 blur-[90px]"></div>
    </div>

    <!-- ================= MAIN APP SCREEN (Dashboard) ================= -->
    <div id="mainDashboard" class="min-h-screen flex flex-col relative z-10">
        
        <!-- Premium Navigation Header -->
        <header class="border-b border-white/10 bg-deepVelvet/60 backdrop-blur-md sticky top-0 z-30">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between">
                <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 rounded-xl bg-gradient-to-tr from-electricPurple to-royalPurple flex items-center justify-center shadow-lg">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" class="w-5 h-5 text-white" viewBox="0 0 24 24">
                            <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
                        </svg>
                    </div>
                    <div>
                        <h2 class="font-bold text-lg leading-tight tracking-tight">Glimpse Console</h2>
                        <span class="text-[10px] uppercase font-bold tracking-widest text-activeCyan">Admin Mode</span>
                    </div>
                </div>

                <!-- Navigation Tabs -->
                <nav class="hidden md:flex space-x-1 p-1 bg-white/5 border border-white/10 rounded-xl">
                    <button onclick="switchTab('overview')" id="tab-overview" class="tab-btn px-4 py-2 rounded-lg text-sm font-medium transition-all bg-white/10 text-white">Overview</button>
                    <button onclick="switchTab('users')" id="tab-users" class="tab-btn px-4 py-2 rounded-lg text-sm font-medium transition-all text-white/60 hover:text-white">User Management</button>
                    <button onclick="switchTab('couples')" id="tab-couples" class="tab-btn px-4 py-2 rounded-lg text-sm font-medium transition-all text-white/60 hover:text-white">Couple Pairs</button>
                    <button onclick="switchTab('control')" id="tab-control" class="tab-btn px-4 py-2 rounded-lg text-sm font-medium transition-all text-white/60 hover:text-white">Control Center</button>
                    <button onclick="switchTab('diagnostics')" id="tab-diagnostics" class="tab-btn px-4 py-2 rounded-lg text-sm font-medium transition-all text-white/60 hover:text-white flex items-center space-x-1.5"><span class="w-1.5 h-1.5 rounded-full bg-activeCyan animate-pulse"></span><span>Live Debugger</span></button>
                </nav>

                <div class="flex items-center space-x-3">
                    <div class="flex items-center space-x-2 px-3 py-1.5 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-semibold">
                        <span class="w-2 h-2 rounded-full bg-emerald-400 animate-ping"></span>
                        <span>API Live</span>
                    </div>
                    <button onclick="handleLogout()" class="p-2 rounded-lg bg-white/5 border border-white/10 hover:bg-rose-500/20 hover:border-rose-500/30 text-white/60 hover:text-rose-400 transition-all">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
                             <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15M12 9l-3 3m0 0l3 3m-3-3h12.75" />
                        </svg>
                    </button>
                </div>
            </div>
        </header>

        <!-- Mobile Navigation bar -->
        <div class="md:hidden border-b border-white/5 bg-deepVelvet/40 p-2 flex justify-around">
            <button onclick="switchTab('overview')" class="tab-btn-mob px-3 py-1.5 rounded-lg text-xs font-medium bg-white/10 text-white" id="tab-mob-overview">Overview</button>
            <button onclick="switchTab('users')" class="tab-btn-mob px-3 py-1.5 rounded-lg text-xs font-medium text-white/60" id="tab-mob-users">Users</button>
            <button onclick="switchTab('couples')" class="tab-btn-mob px-3 py-1.5 rounded-lg text-xs font-medium text-white/60" id="tab-mob-couples">Couples</button>
            <button onclick="switchTab('control')" class="tab-btn-mob px-3 py-1.5 rounded-lg text-xs font-medium text-white/60" id="tab-mob-control">Control</button>
            <button onclick="switchTab('diagnostics')" class="tab-btn-mob px-3 py-1.5 rounded-lg text-xs font-medium text-white/60" id="tab-mob-diagnostics">Debug</button>
        </div>

        <!-- MAIN LAYOUT -->
        <main class="flex-grow max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8">
            
            <!-- OVERVIEW TAB -->
            <div id="content-overview" class="tab-content space-y-8">
                <!-- Welcome Banner -->
                <div class="p-6 sm:p-8 rounded-3xl border border-white/10 bg-gradient-to-tr from-white/5 to-white/0 backdrop-blur-xl relative overflow-hidden flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
                    <div>
                        <h2 class="text-3xl font-extrabold text-white mb-2">Welcome Back, Admin</h2>
                        <p class="text-white/60 text-sm max-w-xl">Monitor your Glimpse companion API, couples connections, battery levels, reverse geocoded coordinates, and system performance diagnostics.</p>
                    </div>
                    <button onclick="fetchData()" class="px-5 py-2.5 rounded-xl border border-electricPurple/30 bg-electricPurple/10 hover:bg-electricPurple/20 text-electricPurple text-sm font-semibold transition-all flex items-center space-x-2">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99" />
                        </svg>
                        <span>Sync System</span>
                    </button>
                </div>

                <!-- Stats Grid -->
                <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
                    <!-- Total Users -->
                    <div class="p-5 rounded-2xl border border-white/10 bg-white/5 shadow-lg relative group overflow-hidden">
                        <div class="absolute -right-4 -bottom-4 w-20 h-20 rounded-full bg-electricPurple/5 blur-xl group-hover:scale-150 transition-all"></div>
                        <div class="text-white/50 text-xs font-semibold uppercase tracking-wider mb-2">Total Users</div>
                        <div id="stat-users" class="text-4xl font-extrabold text-white tracking-tight">-</div>
                        <div class="text-[10px] text-emerald-400 mt-2 font-medium">Registered Accounts</div>
                    </div>
                    
                    <!-- Connected Couples -->
                    <div class="p-5 rounded-2xl border border-white/10 bg-white/5 shadow-lg relative group overflow-hidden">
                        <div class="absolute -right-4 -bottom-4 w-20 h-20 rounded-full bg-activeCyan/5 blur-xl group-hover:scale-150 transition-all"></div>
                        <div class="text-white/50 text-xs font-semibold uppercase tracking-wider mb-2">Connected Couples</div>
                        <div id="stat-couples" class="text-4xl font-extrabold text-white tracking-tight">-</div>
                        <div class="text-[10px] text-activeCyan mt-2 font-medium">Active couples</div>
                    </div>

                    <!-- Total Messages -->
                    <div class="p-5 rounded-2xl border border-white/10 bg-white/5 shadow-lg relative group overflow-hidden">
                        <div class="absolute -right-4 -bottom-4 w-20 h-20 rounded-full bg-royalPurple/5 blur-xl group-hover:scale-150 transition-all"></div>
                        <div class="text-white/50 text-xs font-semibold uppercase tracking-wider mb-2">Total Messages</div>
                        <div id="stat-messages" class="text-4xl font-extrabold text-white tracking-tight">-</div>
                        <div class="text-[10px] text-electricPurple mt-2 font-medium">Shared chat messages</div>
                    </div>

                    <!-- Active Sessions -->
                    <div class="p-5 rounded-2xl border border-white/10 bg-white/5 shadow-lg relative group overflow-hidden">
                        <div class="absolute -right-4 -bottom-4 w-20 h-20 rounded-full bg-emerald-500/5 blur-xl group-hover:scale-150 transition-all"></div>
                        <div class="text-white/50 text-xs font-semibold uppercase tracking-wider mb-2">Active Sessions</div>
                        <div id="stat-active" class="text-4xl font-extrabold text-white tracking-tight">-</div>
                        <div class="text-[10px] text-emerald-400 mt-2 font-medium">Active recently</div>
                    </div>
                </div>

                <!-- Server Info Cards -->
                <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    <!-- Environment Info -->
                    <div class="p-6 rounded-2xl border border-white/10 bg-white/5 shadow-lg space-y-4">
                        <h3 class="text-lg font-bold flex items-center space-x-2">
                            <span class="w-1.5 h-6 rounded bg-electricPurple inline-block"></span>
                            <span>System & Environment</span>
                        </h3>
                        <div class="grid grid-cols-2 gap-4 text-sm">
                            <div class="p-3 bg-white/5 rounded-xl border border-white/5">
                                <span class="block text-[10px] text-white/50 uppercase font-semibold">Laravel Engine</span>
                                <span class="font-bold text-white">v{{ App::version() }}</span>
                            </div>
                            <div class="p-3 bg-white/5 rounded-xl border border-white/5">
                                <span class="block text-[10px] text-white/50 uppercase font-semibold">PHP Environment</span>
                                <span class="font-bold text-white">v{{ PHP_VERSION }}</span>
                            </div>
                            <div class="p-3 bg-white/5 rounded-xl border border-white/5">
                                <span class="block text-[10px] text-white/50 uppercase font-semibold">Database Connection</span>
                                @php
                                    $dbDriver = 'Unknown';
                                    try {
                                        $dbDriver = DB::connection()->getDriverName();
                                    } catch (\Exception $e) {
                                        $dbDriver = 'Offline/Pending';
                                    }
                                @endphp
                                <span class="font-bold text-white">{{ $dbDriver }}</span>
                            </div>
                            <div class="p-3 bg-white/5 rounded-xl border border-white/5">
                                <span class="block text-[10px] text-white/50 uppercase font-semibold">Server Host</span>
                                <span class="font-bold text-white">Octane (Swoole/Roadrunner)</span>
                            </div>
                        </div>
                    </div>

                    <!-- WebSocket Diagnostics -->
                    <div class="p-6 rounded-2xl border border-white/10 bg-white/5 shadow-lg space-y-4 flex flex-col">
                        <h3 class="text-lg font-bold flex items-center space-x-2">
                            <span class="w-1.5 h-6 rounded bg-emerald-500 inline-block"></span>
                            <span>WebSocket Monitor</span>
                        </h3>
                        
                        <div class="space-y-3 flex-grow text-sm">
                            <div class="flex items-center justify-between p-3 bg-white/5 rounded-xl border border-white/5">
                                <span class="text-xs text-white/60">Socket Connection</span>
                                <div class="flex items-center space-x-2">
                                    <span id="ws-diag-indicator" class="w-2.5 h-2.5 rounded-full bg-amber-500 animate-pulse"></span>
                                    <span id="ws-diag-status" class="text-xs font-bold text-amber-400">Connecting...</span>
                                </div>
                            </div>
                            
                            <div class="flex items-center justify-between p-3 bg-white/5 rounded-xl border border-white/5">
                                <span class="text-xs text-white/60">Reverb Local Endpoint</span>
                                <span class="text-xs font-mono text-white/80 bg-white/5 px-2 py-0.5 rounded border border-white/10">127.0.0.1:8080</span>
                            </div>

                            <div class="flex items-center justify-between p-3 bg-white/5 rounded-xl border border-white/5">
                                <span class="text-xs text-white/60">Active Subscriptions</span>
                                <span id="ws-diag-channels" class="text-xs font-bold text-white">0 active channels</span>
                            </div>
                            
                            <div class="flex items-center justify-between p-3 bg-white/5 rounded-xl border border-white/5">
                                <span class="text-xs text-white/60">Last Ping/Latency</span>
                                <span id="ws-diag-latency" class="text-xs font-mono text-white/80">-</span>
                            </div>
                        </div>
                        
                        <!-- Live WebSocket Diagnostics Log Stream -->
                        <div class="mt-2 border-t border-white/10 pt-4 flex flex-col space-y-2">
                            <div class="flex justify-between items-center">
                                <span class="text-[10px] uppercase font-bold text-electricPurple tracking-wider flex items-center space-x-1">
                                    <span class="w-1.5 h-1.5 rounded-full bg-electricPurple animate-ping"></span>
                                    <span>Live Broadcast Stream</span>
                                </span>
                                <button onclick="clearWSLogs()" class="text-[9px] text-white/40 hover:text-white transition-all underline">Clear Logs</button>
                            </div>
                            <div id="ws-log-stream" class="h-44 overflow-y-auto bg-slate-950/70 border border-white/5 rounded-xl p-2.5 font-mono text-[9px] space-y-1.5 scrollbar-thin">
                                <div class="text-white/40 italic">Waiting for events...</div>
                            </div>
                        </div>
                    </div>

                    <!-- Developer Logs -->
                    <div class="p-6 rounded-2xl border border-white/10 bg-white/5 shadow-lg space-y-4 flex flex-col">
                        <h3 class="text-lg font-bold flex items-center space-x-2">
                            <span class="w-1.5 h-6 rounded bg-activeCyan inline-block"></span>
                            <span>Quick Developer Actions</span>
                        </h3>
                        <div class="flex-grow grid grid-cols-1 gap-4">
                            <button onclick="switchTab('control')" class="p-4 bg-electricPurple/10 hover:bg-electricPurple/20 border border-electricPurple/20 hover:border-electricPurple/30 rounded-xl text-left transition-all group">
                                <span class="block font-bold text-white group-hover:text-electricPurple transition-all">Pusher Emulator</span>
                                <span class="block text-xs text-white/50 mt-1">Force device triggers and location updates.</span>
                            </button>
                            <button onclick="switchTab('users')" class="p-4 bg-activeCyan/10 hover:bg-activeCyan/20 border border-activeCyan/20 hover:border-activeCyan/30 rounded-xl text-left transition-all group">
                                <span class="block font-bold text-white group-hover:text-activeCyan transition-all">Mock Battery Levels</span>
                                <span class="block text-xs text-white/50 mt-1">Edit custom battery levels to trigger low-battery warning alerts.</span>
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Live Analytics & Server Resources Row -->
                <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    <!-- Disk Storage Space Analyser -->
                    <div class="p-6 rounded-2xl border border-white/10 bg-white/5 shadow-lg space-y-4">
                        <h3 class="text-lg font-bold flex items-center space-x-2">
                            <span class="w-1.5 h-6 rounded bg-royalPurple inline-block"></span>
                            <span>Disk Storage Analyser</span>
                        </h3>
                        
                        @php
                            $diskTotal = disk_total_space("/");
                            $diskFree = disk_free_space("/");
                            $diskUsed = $diskTotal - $diskFree;
                            $diskPercentage = ($diskTotal > 0) ? round(($diskUsed / $diskTotal) * 100, 1) : 0;
                            
                            if (!function_exists('formatBytesPHPAdmin')) {
                                function formatBytesPHPAdmin($bytes, $precision = 2) {
                                    $units = ['B', 'KB', 'MB', 'GB', 'TB'];
                                    $bytes = max($bytes, 0);
                                    $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
                                    $pow = min($pow, count($units) - 1);
                                    $bytes /= pow(1024, $pow);
                                    return round($bytes, $precision) . ' ' . $units[$pow];
                                }
                            }
                        @endphp

                        <div class="space-y-6">
                            <!-- Circular Progress Bar -->
                            <div class="flex items-center justify-center py-4">
                                <div class="relative w-36 h-36 flex items-center justify-center">
                                    <svg class="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
                                        <circle cx="50" cy="50" r="40" stroke="rgba(255,255,255,0.05)" stroke-width="8" fill="transparent" />
                                        <circle cx="50" cy="50" r="40" stroke="url(#diskGradientAdmin)" stroke-width="8" fill="transparent" 
                                            stroke-dasharray="251.2" stroke-dashoffset="{{ 251.2 - (251.2 * $diskPercentage) / 100 }}" stroke-linecap="round" />
                                        
                                        <defs>
                                            <linearGradient id="diskGradientAdmin" x1="0%" y1="0%" x2="100%" y2="100%">
                                                <stop offset="0%" stop-color="#bf80ff" />
                                                <stop offset="100%" stop-color="#00f3ff" />
                                            </linearGradient>
                                        </defs>
                                    </svg>
                                    <div class="absolute text-center">
                                        <span class="block text-2xl font-extrabold text-white">{{ $diskPercentage }}%</span>
                                        <span class="block text-[10px] text-white/50 uppercase font-semibold">Disk Used</span>
                                    </div>
                                </div>
                            </div>
                            
                            <!-- Detailed metrics -->
                            <div class="grid grid-cols-3 gap-2 text-center text-xs">
                                <div class="p-2 bg-white/5 rounded-xl border border-white/5">
                                    <span class="block text-[9px] text-white/50 uppercase font-medium">Used</span>
                                    <span class="font-bold text-white text-[10px]">{{ formatBytesPHPAdmin($diskUsed) }}</span>
                                </div>
                                <div class="p-2 bg-white/5 rounded-xl border border-white/5">
                                    <span class="block text-[9px] text-white/50 uppercase font-medium">Free</span>
                                    <span class="font-bold text-emerald-400 text-[10px]">{{ formatBytesPHPAdmin($diskFree) }}</span>
                                </div>
                                <div class="p-2 bg-white/5 rounded-xl border border-white/5">
                                    <span class="block text-[9px] text-white/50 uppercase font-medium">Total</span>
                                    <span class="font-bold text-white text-[10px]">{{ formatBytesPHPAdmin($diskTotal) }}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Real-time Bandwidth & Network Monitor -->
                    <div class="lg:col-span-2 p-6 rounded-2xl border border-white/10 bg-white/5 shadow-lg space-y-4 flex flex-col">
                        <div class="flex items-center justify-between">
                            <h3 class="text-lg font-bold flex items-center space-x-2">
                                <span class="w-1.5 h-6 rounded bg-activeCyan inline-block"></span>
                                <span>Real-time Bandwidth & Traffic</span>
                            </h3>
                            <div class="flex items-center space-x-2 text-[10px] font-semibold text-emerald-400 uppercase bg-emerald-500/10 border border-emerald-500/20 px-2 py-1 rounded-md">
                                <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping"></span>
                                <span>Live Traffic</span>
                            </div>
                        </div>
                        
                        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-xs">
                            <div class="p-3 bg-white/5 rounded-xl border border-white/5 flex flex-col justify-between">
                                <span class="text-white/50 uppercase font-semibold text-[9px] tracking-wider">Inbound Speed (RX)</span>
                                <span id="rx-speed" class="text-lg font-extrabold text-activeCyan mt-1">-</span>
                            </div>
                            <div class="p-3 bg-white/5 rounded-xl border border-white/5 flex flex-col justify-between">
                                <span class="text-white/50 uppercase font-semibold text-[9px] tracking-wider">Outbound Speed (TX)</span>
                                <span id="tx-speed" class="text-lg font-extrabold text-electricPurple mt-1">-</span>
                            </div>
                            <div class="p-3 bg-white/5 rounded-xl border border-white/5 flex flex-col justify-between">
                                <span class="text-white/50 uppercase font-semibold text-[9px] tracking-wider">Total Received (Today)</span>
                                <span id="rx-total" class="text-lg font-extrabold text-white mt-1">-</span>
                            </div>
                            <div class="p-3 bg-white/5 rounded-xl border border-white/5 flex flex-col justify-between">
                                <span class="text-white/50 uppercase font-semibold text-[9px] tracking-wider">Total Transmitted (Today)</span>
                                <span id="tx-total" class="text-lg font-extrabold text-white mt-1">-</span>
                            </div>
                        </div>

                        <!-- Beautiful Live Canvas Graph -->
                        <div class="relative flex-grow min-h-[140px] bg-slate-950/40 rounded-2xl border border-white/5 p-2 overflow-hidden flex items-end">
                            <canvas id="bandwidthCanvas" class="w-full h-full"></canvas>
                        </div>
                    </div>
                </div>
            </div>

            <!-- USERS TAB -->
            <div id="content-users" class="tab-content space-y-6 hidden">
                <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                    <div>
                        <h3 class="text-2xl font-bold">User Management</h3>
                        <p class="text-white/50 text-sm">Create mock states, battery warning triggers, and fake real-time coordinate logs.</p>
                    </div>
                    <div class="relative w-full sm:w-64">
                        <input type="text" id="userSearch" onkeyup="filterUsers()" placeholder="Search users by name..." 
                            class="w-full px-4 py-2 rounded-xl border border-white/10 bg-white/5 text-white placeholder-white/30 text-sm focus:outline-none focus:border-electricPurple transition-all">
                    </div>
                </div>

                <!-- Users Table -->
                <div class="border border-white/10 rounded-2xl bg-white/5 overflow-hidden">
                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-sm border-collapse">
                            <thead>
                                <tr class="bg-white/5 border-b border-white/10 text-white/60 font-semibold">
                                    <th class="p-4">Profile</th>
                                    <th class="p-4">Invite Code</th>
                                    <th class="p-4">Battery Level</th>
                                    <th class="p-4">Mock Location</th>
                                    <th class="p-4 text-right">Actions</th>
                                </tr>
                            </thead>
                            <tbody id="userTableBody">
                                <tr>
                                    <td colspan="5" class="p-8 text-center text-white/40">Syncing database and users list...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- COUPLES TAB -->
            <div id="content-couples" class="tab-content space-y-6 hidden">
                <div>
                    <h3 class="text-2xl font-bold">Connected Couples Mapping</h3>
                    <p class="text-white/50 text-sm">Observe connected intimate bonds, anniversary date details, and clear chat history logs.</p>
                </div>

                <!-- Couples Grid -->
                <div id="couplesContainer" class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="md:col-span-2 p-8 text-center border border-white/10 bg-white/5 rounded-2xl text-white/40">Syncing connected couple pairs...</div>
                </div>
            </div>

            <!-- CONTROL CENTER TAB -->
            <div id="content-control" class="tab-content space-y-6 hidden">
                <div>
                    <h3 class="text-2xl font-bold">Control Center & Utilities</h3>
                    <p class="text-white/50 text-sm">Simulate live system states, force live broadcasts, and trigger test state pushes.</p>
                </div>

                <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <!-- Simulate State Updates -->
                    <div class="p-6 rounded-2xl border border-white/10 bg-white/5 space-y-4">
                        <h4 class="text-lg font-bold flex items-center space-x-2">
                            <span class="w-1.5 h-6 rounded bg-electricPurple"></span>
                            <span>WebSocket Broadcasting Simulator</span>
                        </h4>
                        <p class="text-sm text-white/60">Choose a registered user and trigger a simulated WebSocket broadcast event. Glimpse mobile apps running on connected devices will immediately animate and update in real-time!</p>
                        
                        <div class="space-y-4 pt-2">
                            <div>
                                <label class="block text-xs font-semibold text-white/50 uppercase mb-2">Simulate User Profile</label>
                                <select id="simulatorUserSelect" class="w-full px-4 py-2.5 rounded-xl border border-white/10 bg-slate-900 text-white focus:outline-none focus:border-electricPurple text-sm">
                                    <!-- Dynamic populated options -->
                                </select>
                            </div>
                            
                            <div class="grid grid-cols-2 gap-4">
                                <button onclick="triggerSimulatedUpdate('battery_low')" class="py-2.5 rounded-xl bg-amber-500/10 hover:bg-amber-500/20 border border-amber-500/30 text-amber-400 font-semibold text-xs transition-all">
                                    Simulate Low Battery (12%)
                                </button>
                                <button onclick="triggerSimulatedUpdate('is_charging')" class="py-2.5 rounded-xl bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/30 text-emerald-400 font-semibold text-xs transition-all">
                                    Toggle Charging Active
                                </button>
                                <button onclick="triggerSimulatedUpdate('online')" class="py-2.5 rounded-xl bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/30 text-emerald-400 font-semibold text-xs transition-all col-span-2">
                                    Simulate Active Location Pulsing
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Developer Utilities -->
                    <div class="p-6 rounded-2xl border border-white/10 bg-white/5 space-y-4">
                        <h4 class="text-lg font-bold flex items-center space-x-2">
                            <span class="w-1.5 h-6 rounded bg-activeCyan"></span>
                            <span>Developer Utilities</span>
                        </h4>
                        <p class="text-sm text-white/60">System management actions for resetting databases or clearing chat logs safely in staging environments.</p>
                        
                        <div class="space-y-3 pt-2">
                            <div class="p-4 bg-rose-500/10 border border-rose-500/20 rounded-xl space-y-2">
                                <span class="block font-bold text-rose-400 text-sm">Clear Couple Conversations</span>
                                <span class="block text-xs text-white/50">Deletes all chat messages, flash attachments, and media references.</span>
                                <div class="flex space-x-2 mt-2">
                                    <select id="clearChatCoupleSelect" class="flex-grow px-3 py-1.5 rounded-lg border border-white/10 bg-slate-900 text-white text-xs focus:outline-none">
                                        <!-- Dynamic populated options -->
                                    </select>
                                    <button onclick="clearChat()" class="px-4 py-1.5 rounded-lg bg-rose-500 hover:bg-rose-600 text-white font-semibold text-xs transition-all">
                                        Execute Purge
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- ================= DEWA (GOD MODE) CONTROL PANEL ================= -->
                <div class="p-6 rounded-2xl border border-white/10 bg-white/5 space-y-6">
                    <div class="flex items-center justify-between border-b border-white/10 pb-4">
                        <h4 class="text-xl font-bold flex items-center space-x-2 text-activeCyan">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" class="w-6 h-6 text-activeCyan animate-pulse" viewBox="0 0 24 24">
                                <path d="M12 2L2 22h20L12 2zm0 3.99L19.53 19H4.47L12 5.99zM13 16h-2v2h2v-2zm0-6h-2v4h2v-4z"/>
                            </svg>
                            <span>Dewa God Mode Command Center</span>
                        </h4>
                        <span class="text-[10px] uppercase font-bold tracking-widest text-rose-400 bg-rose-500/10 border border-rose-500/20 px-2 py-1 rounded">God Level Access</span>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <!-- God Command 1: Glimpse Flash Exterminator -->
                        <div class="p-4 bg-slate-950/40 border border-white/5 rounded-xl space-y-4">
                            <div>
                                <span class="block font-bold text-white text-sm">Glimpse Flash Exterminator</span>
                                <span class="block text-xs text-white/50 mt-1">Directly wipe and prune flash history files from the server's disk based on expiration age.</span>
                            </div>

                            <div class="space-y-3">
                                <div>
                                    <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">Target User</label>
                                    <select id="dewaPruneUserSelect" class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white text-xs focus:outline-none focus:border-activeCyan">
                                        <option value="all">All Users (Global Wipeout)</option>
                                    </select>
                                </div>
                                <div>
                                    <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">Age Filter (Threshold)</label>
                                    <select id="dewaPruneDaysSelect" class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white text-xs focus:outline-none focus:border-activeCyan">
                                        <option value="1">Older than 1 Day (H-1)</option>
                                        <option value="2">Older than 2 Days (H-2)</option>
                                        <option value="3">Older than 3 Days (H-3)</option>
                                        <option value="5">Older than 5 Days (H-5)</option>
                                        <option value="7" selected>Older than 7 Days (Default Expired H-7)</option>
                                        <option value="0">All Flashes (Instant Wipe - 0 Days!)</option>
                                    </select>
                                </div>
                                <button onclick="executeFlashPrune()" class="w-full py-2 rounded-lg bg-rose-500/10 hover:bg-rose-500 text-rose-400 hover:text-white border border-rose-500/30 font-bold text-xs transition-all flex items-center justify-center space-x-2">
                                    <span>Purge selected flashes</span>
                                </button>
                            </div>
                        </div>

                        <!-- God Command 2: Forced Couple Linker -->
                        <div class="p-4 bg-slate-950/40 border border-white/5 rounded-xl space-y-4">
                            <div>
                                <span class="block font-bold text-white text-sm">Forced Couple Linker</span>
                                <span class="block text-xs text-white/50 mt-1">Forcefully bind two users as a connected couple pair immediately, bypassing invite codes.</span>
                            </div>

                            <div class="space-y-3">
                                <div class="grid grid-cols-2 gap-2">
                                    <div>
                                        <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">User A</label>
                                        <select id="dewaLinkUser1Select" class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white text-xs focus:outline-none focus:border-activeCyan">
                                            <!-- Dynamic populated -->
                                        </select>
                                    </div>
                                    <div>
                                        <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">User B</label>
                                        <select id="dewaLinkUser2Select" class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white text-xs focus:outline-none focus:border-activeCyan">
                                            <!-- Dynamic populated -->
                                        </select>
                                    </div>
                                </div>
                                <button onclick="executeGodLink()" class="w-full py-2 rounded-lg bg-activeCyan/10 hover:bg-activeCyan text-activeCyan hover:text-slate-950 border border-activeCyan/30 font-bold text-xs transition-all flex items-center justify-center space-x-2">
                                    <span>Establish God-Link Connection</span>
                                </button>
                            </div>
                        </div>

                        <!-- God Command 3: Global System Live Broadcast -->
                        <div class="p-4 bg-slate-950/40 border border-white/5 rounded-xl space-y-4">
                            <div>
                                <span class="block font-bold text-white text-sm">Global System Broadcast</span>
                                <span class="block text-xs text-white/50 mt-1">Send a live system announcement bubble that flashes immediately on all active couple devices.</span>
                            </div>

                            <div class="space-y-3">
                                <div>
                                    <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">Broadcast Message</label>
                                    <textarea id="dewaBroadcastText" placeholder="Attention: Glimpse API Server Maintenance in 10 minutes..." rows="2" class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white text-xs focus:outline-none focus:border-activeCyan resize-none"></textarea>
                                </div>
                                <button onclick="executeGlobalBroadcast()" class="w-full py-2 rounded-lg bg-electricPurple/10 hover:bg-electricPurple text-electricPurple hover:text-white border border-electricPurple/30 font-bold text-xs transition-all flex items-center justify-center space-x-2">
                                    <span>Broadcast System Message</span>
                                </button>
                            </div>
                        </div>

                        <!-- God Command 4: System Optimizer & Orphan Sweeper -->
                        <div class="p-4 bg-slate-950/40 border border-white/5 rounded-xl space-y-4 flex flex-col justify-between">
                            <div>
                                <span class="block font-bold text-white text-sm">System Engine Optimizer</span>
                                <span class="block text-xs text-white/50 mt-1">Recalibrate indices, optimize tables, and purge orphan couple connection remnants from database.</span>
                            </div>

                            <div class="space-y-3 pt-4">
                                <button onclick="executeDatabaseOptimize()" class="w-full py-3 rounded-lg bg-emerald-500/10 hover:bg-emerald-500 text-emerald-400 hover:text-slate-950 border border-emerald-500/30 font-bold text-xs transition-all flex items-center justify-center space-x-2">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
                                    </svg>
                                    <span>Optimize & Purge Stale Remnants</span>
                                </button>
                            </div>
                        </div>

                        <!-- God Command 5: Secure Token Changer -->
                        <div class="p-4 bg-slate-950/40 border border-white/5 rounded-xl space-y-4 flex flex-col justify-between">
                            <div>
                                <span class="block font-bold text-white text-sm">Secure Admin Token Changer</span>
                                <span class="block text-xs text-white/50 mt-1">Directly update and re-hash the master Admin Access Token in the database. Instantly updates validation.</span>
                            </div>

                            <div class="space-y-3">
                                <div>
                                    <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">New Access Token</label>
                                    <input type="password" id="dewaNewTokenInput" placeholder="Enter new secret token..." class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white text-xs focus:outline-none focus:border-activeCyan">
                                </div>
                                <button onclick="executeChangeAdminToken()" class="w-full py-2 rounded-lg bg-rose-500/10 hover:bg-rose-500 text-rose-400 hover:text-white border border-rose-500/30 font-bold text-xs transition-all flex items-center justify-center space-x-2">
                                    <span>Update Admin Token</span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- LIVE DIAGNOSTICS & PROTOBUF DEBUGGER TAB -->
            <div id="content-diagnostics" class="tab-content space-y-6 hidden">
                <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                    <div>
                        <h3 class="text-2xl font-bold flex items-center space-x-2">
                            <span class="w-1.5 h-6 rounded bg-activeCyan inline-block animate-pulse"></span>
                            <span>Live Diagnostic & Protobuf Console</span>
                        </h3>
                        <p class="text-white/50 text-sm">Monitor real-time network packets, inspect pure Protobuf payloads, and run end-to-end API serialization tests.</p>
                    </div>
                    <div class="flex space-x-3">
                        <div class="flex items-center space-x-2 px-3 py-1.5 rounded-lg bg-slate-900 border border-white/10 text-xs">
                            <span class="text-white/50">Decoder:</span>
                            <span class="text-activeCyan font-bold">Pure Protobuf v3</span>
                        </div>
                    </div>
                </div>

                <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
                    
                    <!-- LEFT & CENTER: High-Capacity WebSocket Console -->
                    <div class="xl:col-span-2 p-6 rounded-2xl border border-white/10 bg-white/5 space-y-4 flex flex-col min-h-[600px]">
                        <div class="flex items-center justify-between border-b border-white/5 pb-3">
                            <h4 class="text-lg font-bold flex items-center space-x-2">
                                <span class="w-2.5 h-2.5 rounded-full bg-electricPurple animate-ping"></span>
                                <span>Real-time WebSocket Broadcast Inspector</span>
                            </h4>
                            <div class="flex items-center space-x-3">
                                <button onclick="clearDiagWSLogs()" class="text-xs text-white/50 hover:text-white transition-all underline">Clear Term</button>
                            </div>
                        </div>

                        <!-- Filter Bar -->
                        <div class="flex flex-wrap items-center gap-4 p-3 bg-slate-950/40 rounded-xl border border-white/5 text-xs text-white/70">
                            <span class="font-bold text-white/40 uppercase text-[9px] tracking-wider">Filter Events:</span>
                            <label class="flex items-center space-x-1.5 cursor-pointer hover:text-white">
                                <input type="checkbox" id="filter-pb" checked class="rounded border-white/10 bg-slate-900 text-activeCyan focus:ring-0" />
                                <span>MessageSent (Protobuf)</span>
                            </label>
                            <label class="flex items-center space-x-1.5 cursor-pointer hover:text-white">
                                <input type="checkbox" id="filter-state" checked class="rounded border-white/10 bg-slate-900 text-emerald-400 focus:ring-0" />
                                <span>PartnerStateUpdated</span>
                            </label>
                            <label class="flex items-center space-x-1.5 cursor-pointer hover:text-white">
                                <input type="checkbox" id="filter-burst" checked class="rounded border-white/10 bg-slate-900 text-rose-400 focus:ring-0" />
                                <span>LoveBurstSent</span>
                            </label>
                            <label class="flex items-center space-x-1.5 cursor-pointer hover:text-white">
                                <input type="checkbox" id="filter-typing" checked class="rounded border-white/10 bg-slate-900 text-amber-400 focus:ring-0" />
                                <span>TypingStatus</span>
                            </label>
                        </div>

                        <!-- Main IDE-Style Diagnostic Log Console -->
                        <div id="diag-ws-log-stream" class="flex-grow h-[450px] overflow-y-auto bg-slate-950/85 border border-white/5 rounded-2xl p-4 font-mono text-[10px] space-y-2.5 scrollbar-thin select-all">
                            <div class="text-white/40 italic">Waiting for events from active couple channels...</div>
                        </div>
                    </div>

                    <!-- RIGHT COLUMN: Sandbox & Live Compiler -->
                    <div class="space-y-6">
                        
                        <!-- Box 1: E2E HTTP Protobuf API Sandbox -->
                        <div class="p-6 rounded-2xl border border-white/10 bg-white/5 space-y-4">
                            <h4 class="text-lg font-bold flex items-center space-x-2">
                                <span class="w-1.5 h-6 rounded bg-activeCyan inline-block"></span>
                                <span>HTTP Protobuf API Simulator</span>
                            </h4>
                            <p class="text-xs text-white/50">Directly construct and send simulated Protobuf binary requests to the Laravel API from the browser. Inspect raw request/response bytes!</p>
                            
                            <div class="space-y-3 pt-2 text-xs">
                                <div>
                                    <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">Select Sender User</label>
                                    <select id="diagUserSelect" onchange="updateDiagRooms()" class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white focus:outline-none focus:border-activeCyan">
                                        <!-- Populated dynamically -->
                                    </select>
                                </div>
                                <div>
                                    <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">Target Room</label>
                                    <select id="diagRoomSelect" class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white focus:outline-none focus:border-activeCyan">
                                        <!-- Populated dynamically -->
                                    </select>
                                </div>
                                <div>
                                    <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">Message Text</label>
                                    <input type="text" id="diagMessageText" placeholder="Enter message text..." class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white focus:outline-none focus:border-activeCyan">
                                </div>
                                <button onclick="sendHTTPProtobufRequest()" class="w-full py-2.5 rounded-xl bg-activeCyan/10 hover:bg-activeCyan text-activeCyan hover:text-slate-950 border border-activeCyan/30 font-bold transition-all flex items-center justify-center space-x-2">
                                    <span class="w-1.5 h-1.5 rounded-full bg-activeCyan animate-ping"></span>
                                    <span>POST Binary Protobuf</span>
                                </button>
                            </div>

                            <!-- REST API Output Box -->
                            <div id="diag-http-output" class="hidden p-3 rounded-xl bg-slate-950/70 border border-white/5 text-[9px] font-mono space-y-2">
                                <div>
                                    <span class="text-amber-400 block font-bold uppercase text-[8px]">Request Hex Bytes</span>
                                    <span id="diag-http-req-hex" class="text-amber-300/80 break-all block"></span>
                                </div>
                                <div>
                                    <span class="text-emerald-400 block font-bold uppercase text-[8px]">Response Decoded</span>
                                    <span id="diag-http-resp-json" class="text-white break-all block whitespace-pre-wrap"></span>
                                </div>
                                <div class="text-[8px] text-white/30 text-right" id="diag-http-stats"></div>
                            </div>
                        </div>

                        <!-- Box 1.5: Glimpse Flash Debugger & Simulator -->
                        <div class="p-6 rounded-2xl border border-white/10 bg-white/5 space-y-4">
                            <h4 class="text-lg font-bold flex items-center space-x-2">
                                <span class="w-1.5 h-6 rounded bg-orange-500 inline-block"></span>
                                <span>Glimpse Flash Simulator & Storage Doctor</span>
                            </h4>
                            <p class="text-xs text-white/50">Diagnose media uploads, simulate high-fidelity photo Flash timeline postings, and check server-side physical storage symlink connectivity.</p>
                            
                            <div class="space-y-3 pt-2 text-xs">
                                <div class="grid grid-cols-2 gap-2">
                                    <div>
                                        <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">Sender User</label>
                                        <select id="flashSenderSelect" class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white focus:outline-none focus:border-orange-500">
                                            <!-- Dynamically populated -->
                                        </select>
                                    </div>
                                    <div>
                                        <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">Battery Level</label>
                                        <input type="number" id="flashBattery" value="88" min="0" max="100" class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white focus:outline-none focus:border-orange-500">
                                    </div>
                                </div>

                                <div class="grid grid-cols-2 gap-2">
                                    <div>
                                        <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">Latitude</label>
                                        <input type="text" id="flashLat" value="-6.9740" class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white focus:outline-none focus:border-orange-500">
                                    </div>
                                    <div>
                                        <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">Longitude</label>
                                        <input type="text" id="flashLon" value="107.6303" class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white focus:outline-none focus:border-orange-500">
                                    </div>
                                </div>

                                <div>
                                    <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">Location Name</label>
                                    <input type="text" id="flashLocName" value="Dewa Diagnostic Lab" class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white focus:outline-none focus:border-orange-500">
                                </div>

                                <div>
                                    <label class="block text-[10px] text-white/50 uppercase font-semibold mb-1">Status Note</label>
                                    <input type="text" id="flashStatus" value="Testing Glimpse Flash 📸" class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white focus:outline-none focus:border-orange-500">
                                </div>

                                <div class="p-3 bg-slate-900/60 border border-white/5 rounded-xl space-y-3">
                                    <label class="block text-[10px] text-orange-400 uppercase font-semibold">Flash Media File Source</label>
                                    <input type="file" id="flashFileInput" accept="image/*" class="block w-full text-xs text-white/50 file:mr-3 file:py-1 file:px-2.5 file:rounded-lg file:border-0 file:text-[10px] file:font-semibold file:bg-white/10 file:text-white hover:file:bg-white/20 file:cursor-pointer">
                                    <div class="flex items-center space-x-2">
                                        <span class="text-[9px] text-white/30">Or use instant generator:</span>
                                        <button onclick="generateMockFlashImage()" class="px-2 py-0.5 rounded bg-orange-500/10 hover:bg-orange-500/20 text-orange-400 text-[9px] font-bold border border-orange-500/20 transition-all">
                                            Generate 1-Click Aesthetic Image
                                        </button>
                                    </div>
                                    <div id="flashImagePreviewWrapper" class="hidden flex items-center space-x-3 pt-1">
                                        <img id="flashImagePreview" src="" class="w-12 h-12 rounded-lg object-cover border border-white/20">
                                        <span class="text-[9px] text-emerald-400 font-mono">Image loaded & optimized successfully!</span>
                                    </div>
                                </div>

                                <button onclick="sendSimulatedFlash()" class="w-full py-2.5 rounded-xl bg-orange-500/10 hover:bg-orange-500 text-orange-500 hover:text-slate-950 border border-orange-500/30 font-bold transition-all flex items-center justify-center space-x-2">
                                    <span class="w-1.5 h-1.5 rounded-full bg-orange-500 animate-ping"></span>
                                    <span>POST Simulated Glimpse Flash</span>
                                </button>
                            </div>

                            <!-- Flash Diagnostic Output Box -->
                            <div id="diag-flash-output" class="hidden p-3 rounded-xl bg-slate-950/70 border border-white/5 text-[9px] font-mono space-y-2">
                                <div>
                                    <span class="text-orange-400 block font-bold uppercase text-[8px]">Upload Trace & File Info</span>
                                    <span id="diag-flash-trace" class="text-white break-all block whitespace-pre-wrap"></span>
                                </div>
                            </div>

                            <!-- Symlink Doctor Widget -->
                            <div class="p-3 bg-slate-950/40 border border-white/5 rounded-xl space-y-2.5">
                                <div class="flex items-center justify-between">
                                    <span class="text-[10px] text-white font-bold uppercase tracking-wider">Storage Symlink Status</span>
                                    <button onclick="diagnoseStorageSymlink()" class="text-[9px] text-activeCyan hover:underline font-semibold">Refresh Diagnostics</button>
                                </div>
                                <div class="grid grid-cols-2 gap-2 text-[9px] font-mono">
                                    <div class="p-2 rounded bg-slate-900 border border-white/5 flex flex-col">
                                        <span class="text-white/40">public/storage:</span>
                                        <span id="symlinkStatusExists" class="font-bold text-white">Loading...</span>
                                    </div>
                                    <div class="p-2 rounded bg-slate-900 border border-white/5 flex flex-col">
                                        <span class="text-white/40">Writeable:</span>
                                        <span id="symlinkStatusWriteable" class="font-bold text-white">Loading...</span>
                                    </div>
                                </div>
                                <div id="symlinkFixerPanel" class="hidden pt-1.5">
                                    <button onclick="fixStorageSymlink()" class="w-full py-1.5 rounded bg-emerald-500/10 hover:bg-emerald-500 text-emerald-400 hover:text-slate-950 border border-emerald-500/20 font-bold text-[10px] transition-all flex items-center justify-center space-x-1.5">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                        </svg>
                                        <span>Run Symlink Doctor Fixer</span>
                                    </button>
                                </div>
                            </div>
                        </div>

                        <!-- Box 2: Protobuf Interactive Sandbox -->
                        <div class="p-6 rounded-2xl border border-white/10 bg-white/5 space-y-4">
                            <h4 class="text-lg font-bold flex items-center space-x-2">
                                <span class="w-1.5 h-6 rounded bg-electricPurple inline-block"></span>
                                <span>Protobuf Decoder Sandbox</span>
                            </h4>
                            <p class="text-xs text-white/50">Paste raw Base64 payloads or spaced Hexadecimal bytes (e.g. `08 C0 0C 1A 05 68 65 6C 6C 6F`) to decode them instantly in the browser!</p>
                            
                            <div class="space-y-3 pt-2">
                                <textarea id="sandboxInput" rows="2" placeholder="Paste Base64 payload or Hex bytes here..." class="w-full px-3 py-2 rounded-lg border border-white/10 bg-slate-900 text-white text-xs focus:outline-none focus:border-electricPurple font-mono resize-none"></textarea>
                                
                                <div class="grid grid-cols-2 gap-2">
                                    <button onclick="decodeSandbox('base64')" class="py-1.5 rounded-lg bg-electricPurple/10 hover:bg-electricPurple text-electricPurple hover:text-white border border-electricPurple/30 font-semibold text-xs transition-all">
                                        Decode Base64
                                    </button>
                                    <button onclick="decodeSandbox('hex')" class="py-1.5 rounded-lg bg-activeCyan/10 hover:bg-activeCyan text-activeCyan hover:text-slate-950 border border-activeCyan/30 font-semibold text-xs transition-all">
                                        Decode Hex
                                    </button>
                                </div>

                                <div id="sandboxOutputWrapper" class="hidden p-3 bg-slate-950/70 border border-white/5 rounded-xl text-[9px] font-mono whitespace-pre-wrap text-activeCyan max-h-36 overflow-y-auto"></div>
                            </div>
                        </div>

                    </div>

                </div>
            </div>
        </main>
    </div>

    <!-- MOCK STATE MODALS -->
    <!-- Edit Location Modal -->
    <div id="locationModal" class="fixed inset-0 z-40 hidden flex items-center justify-center bg-black/60 backdrop-blur-sm">
        <div class="w-full max-w-md p-6 rounded-2xl border border-white/10 bg-slate-900 shadow-xl space-y-4">
            <h4 class="text-lg font-bold text-white flex items-center space-x-2">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5 text-electricPurple">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
                </svg>
                <span>Edit Mock Location</span>
            </h4>
            <input type="hidden" id="locModalUserId">
            <div class="space-y-3">
                <div>
                    <label class="block text-xs text-white/50 mb-1">Latitude</label>
                    <input type="number" step="0.000001" id="locModalLat" class="w-full px-4 py-2 rounded-xl bg-white/5 border border-white/10 text-white focus:outline-none text-sm">
                </div>
                <div>
                    <label class="block text-xs text-white/50 mb-1">Longitude</label>
                    <input type="number" step="0.000001" id="locModalLon" class="w-full px-4 py-2 rounded-xl bg-white/5 border border-white/10 text-white focus:outline-none text-sm">
                </div>
                <div>
                    <label class="block text-xs text-white/50 mb-1">Address / Landmark Name</label>
                    <input type="text" id="locModalName" placeholder="Grand Indonesia Mall, Jakarta" class="w-full px-4 py-2 rounded-xl bg-white/5 border border-white/10 text-white focus:outline-none text-sm">
                </div>
            </div>
            <div class="flex space-x-3 pt-2">
                <button onclick="closeModal('locationModal')" class="flex-1 py-2 rounded-xl border border-white/10 hover:bg-white/5 text-white text-xs font-semibold transition-all">Cancel</button>
                <button onclick="submitLocationUpdate()" class="flex-1 py-2 rounded-xl bg-gradient-to-r from-electricPurple to-royalPurple text-white text-xs font-semibold transition-all">Save Changes</button>
            </div>
        </div>
    </div>

    <!-- Edit Battery Modal -->
    <div id="batteryModal" class="fixed inset-0 z-40 hidden flex items-center justify-center bg-black/60 backdrop-blur-sm">
        <div class="w-full max-w-sm p-6 rounded-2xl border border-white/10 bg-slate-900 shadow-xl space-y-4">
            <h4 class="text-lg font-bold text-white flex items-center space-x-2">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5 text-activeCyan">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
                </svg>
                <span>Edit Battery Level</span>
            </h4>
            <input type="hidden" id="battModalUserId">
            <div>
                <label class="block text-xs text-white/50 mb-2">Battery Percentage (%)</label>
                <div class="flex items-center space-x-4">
                    <input type="range" min="1" max="100" id="battModalSlider" oninput="document.getElementById('battModalVal').innerText = this.value + '%'" class="flex-grow accent-activeCyan">
                    <span id="battModalVal" class="font-bold text-activeCyan text-lg">50%</span>
                </div>
            </div>
            <div class="flex space-x-3 pt-2">
                <button onclick="closeModal('batteryModal')" class="flex-1 py-2 rounded-xl border border-white/10 hover:bg-white/5 text-white text-xs font-semibold transition-all">Cancel</button>
                <button onclick="submitBatteryUpdate()" class="flex-1 py-2 rounded-xl bg-activeCyan hover:bg-activeCyan/80 text-slate-950 text-xs font-bold transition-all">Save Changes</button>
            </div>
        </div>
    </div>

    <!-- ================= DEWA CHAT SPYGLASS MODAL ================= -->
    <div id="chatSpyModal" class="fixed inset-0 z-50 hidden flex items-center justify-center bg-black/80 backdrop-blur-md">
        <div class="w-full max-w-lg p-6 rounded-2xl border border-white/10 bg-slate-900 shadow-2xl space-y-4 flex flex-col h-[80vh]">
            <!-- Header -->
            <div class="flex items-center justify-between border-b border-white/10 pb-3 flex-shrink-0">
                <div class="flex items-center space-x-2 text-activeCyan">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6 animate-pulse">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    <div>
                        <h4 class="text-lg font-bold text-white" id="spyModalTitle">Live Chat Spyglass</h4>
                        <span class="text-[10px] uppercase font-bold text-activeCyan tracking-wider">God Spy Mode</span>
                    </div>
                </div>
                <button onclick="closeChatSpy()" class="p-1.5 rounded-lg bg-white/5 hover:bg-white/10 text-white/70 hover:text-white transition-all">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <!-- Chat Stream Body -->
            <div id="spyChatStream" class="flex-grow overflow-y-auto space-y-4 pr-1 p-2 rounded-xl bg-slate-950/50 border border-white/5 min-h-0">
                <!-- Chat bubbles will be dynamically injected here -->
            </div>

            <!-- Footer: Mock Sending Injection -->
            <div class="flex-shrink-0 pt-2 border-t border-white/10 flex items-center space-x-2">
                <input type="text" id="spyMockMessageInput" placeholder="Inject mock message into conversation..." class="flex-grow px-4 py-2.5 rounded-xl border border-white/10 bg-slate-950 text-white text-xs focus:outline-none focus:border-activeCyan">
                <select id="spySenderSelect" class="px-3 py-2.5 rounded-xl border border-white/10 bg-slate-950 text-white text-xs focus:outline-none focus:border-activeCyan">
                    <!-- populated dynamically -->
                </select>
                <button onclick="injectSpyMessage()" class="px-4 py-2.5 rounded-xl bg-activeCyan text-slate-950 hover:bg-activeCyan/80 font-bold text-xs transition-all">
                    Inject
                </button>
            </div>
        </div>
    </div>

    <!-- JAVASCRIPT APP LOGIC -->
    <script>
        let appData = {
            users: [],
            couples: [],
            stats: {}
        };

        const mainDashboard = document.getElementById('mainDashboard');

        // Check if already authenticated on load
        window.addEventListener('DOMContentLoaded', () => {
            const savedToken = localStorage.getItem('glimpse_admin_token');
            if (savedToken && savedToken !== 'undefined' && savedToken !== 'null' && savedToken.trim() !== '') {
                fetchData();
                startWebSocketDiagnostics();
                startBandwidthMonitor();
            } else {
                localStorage.removeItem('glimpse_admin_token');
                window.location.href = '/admin/login';
            }
        });

        function handleLogout() {
            localStorage.removeItem('glimpse_admin_token');
            if (liveWS) {
                try { liveWS.close(); } catch(e) {}
                liveWS = null;
            }
            clearInterval(wsPingInterval);
            window.location.href = '/admin/login';
        }

        async function fetchData() {
            const token = localStorage.getItem('glimpse_admin_token');
            try {
                const response = await fetch(`/admin/api?token=${encodeURIComponent(token)}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({ action: 'get_data' })
                });

                if (response.ok) {
                    const data = await response.json();
                    updateUI(data);
                    // Defer to prevent blocking UI load
                    setTimeout(diagnoseStorageSymlink, 100);
                } else if (response.status === 401) {
                    handleLogout();
                }
            } catch (err) {
                console.error(err);
            }
        }

        function updateUI(data) {
            appData = data;
            
            // Stats
            document.getElementById('stat-users').innerText = data.stats.total_users;
            document.getElementById('stat-couples').innerText = data.stats.total_couples;
            document.getElementById('stat-messages').innerText = data.stats.total_messages;
            document.getElementById('stat-active').innerText = data.stats.active_sessions;

            // Populate forms / select values
            populateSelects(data);

            // Render tables & grids
            renderUsersTable(data.users);
            renderCouplesGrid(data.couples);
            
            // Auto-subscribe to all active couples' channels on websocket to monitor broadcasts
            if (data.couples && liveWS && liveWS.readyState === WebSocket.OPEN) {
                data.couples.forEach(c => {
                    liveWS.send(JSON.stringify({
                        event: 'pusher:subscribe',
                        data: { channel: `couple.${c.id}` }
                    }));
                });
                document.getElementById('ws-diag-channels').innerText = `${data.couples.length} channels monitored`;
            }
        }

        function populateSelects(data) {
            const selects = [
                'simulatorUserSelect', 
                'clearChatCoupleSelect', 
                'dewaPruneUserSelect', 
                'dewaLinkUser1Select', 
                'dewaLinkUser2Select',
                'diagUserSelect',
                'flashSenderSelect'
            ];

            selects.forEach(id => {
                const select = document.getElementById(id);
                if (!select) return;

                // Keep current selected value
                const prevVal = select.value;
                select.innerHTML = '';

                if (id === 'dewaPruneUserSelect') {
                    select.innerHTML = '<option value="all">All Users (Global Wipeout)</option>';
                }

                if (id === 'clearChatCoupleSelect') {
                    data.couples.forEach(c => {
                        const name1 = c.users[0] ? c.users[0].name : 'Unpaired';
                        const name2 = c.users[1] ? c.users[1].name : 'Unpaired';
                        const opt = document.createElement('option');
                        opt.value = c.id;
                        opt.innerText = `Couple #${c.id} (${name1} & ${name2})`;
                        select.appendChild(opt);
                    });
                } else {
                    data.users.forEach(u => {
                        const opt = document.createElement('option');
                        opt.value = u.id;
                        opt.innerText = `${u.name} (${u.email})`;
                        select.appendChild(opt);
                    });
                }

                if (prevVal) select.value = prevVal;
            });
        }

        function renderUsersTable(users) {
            const tbody = document.getElementById('userTableBody');
            tbody.innerHTML = '';

            if (users.length === 0) {
                tbody.innerHTML = `<tr><td colspan="5" class="p-8 text-center text-white/40">No registered users in database.</td></tr>`;
                return;
            }

            users.forEach(u => {
                const tr = document.createElement('tr');
                tr.className = 'border-b border-white/5 hover:bg-white/5 transition-all text-xs';

                const avatar = u.profile_photo_url ? u.profile_photo_url : `https://ui-avatars.com/api/?name=${encodeURIComponent(u.name)}`;
                const coupleStatus = u.couple_id ? `<span class="text-activeCyan">Couple ID #${u.couple_id}</span>` : '<span class="text-rose-400">Single / Unpaired</span>';
                const parsedLat = parseFloat(u.latitude);
                const parsedLon = parseFloat(u.longitude);
                const lat = !isNaN(parsedLat) ? parsedLat.toFixed(6) : '-';
                const lon = !isNaN(parsedLon) ? parsedLon.toFixed(6) : '-';
                const locName = u.location_name ? u.location_name : 'No GPS coordinates';

                tr.innerHTML = `
                    <td class="p-4 flex items-center space-x-3">
                        <img src="${avatar}" class="w-9 h-9 rounded-full object-cover border border-white/10" onerror="this.src='https://ui-avatars.com/api/?name=User'">
                        <div>
                            <span class="block font-bold text-white">${u.name}</span>
                            <span class="block text-[10px] text-white/50">${u.email}</span>
                            <span class="block text-[9px] mt-0.5">${coupleStatus}</span>
                        </div>
                    </td>
                    <td class="p-4 font-mono text-[10px] text-white/80 select-all">${u.invite_code || 'None'}</td>
                    <td class="p-4">
                        <div class="flex items-center space-x-2">
                            <span class="font-semibold text-white">${u.battery_level || 100}%</span>
                            <span class="text-[10px] text-white/40">(${u.is_charging ? 'Charging' : 'Unplugged'})</span>
                        </div>
                    </td>
                    <td class="p-4 max-w-xs truncate">
                        <span class="block font-bold text-white/80">${locName}</span>
                        <span class="block text-[9px] font-mono text-white/40 mt-0.5">Lat: ${lat} | Lon: ${lon}</span>
                    </td>
                    <td class="p-4 text-right">
                        <div class="inline-flex space-x-2">
                            <button onclick="openLocationModal(${u.id}, ${u.latitude || -6.200000}, ${u.longitude || 106.816666}, '${u.location_name || ''}')" class="px-2.5 py-1.5 rounded-lg bg-electricPurple/10 hover:bg-electricPurple/20 border border-electricPurple/20 text-electricPurple text-[10px] font-semibold transition-all">Location</button>
                            <button onclick="openBatteryModal(${u.id}, ${u.battery_level || 100})" class="px-2.5 py-1.5 rounded-lg bg-activeCyan/10 hover:bg-activeCyan/20 border border-activeCyan/20 text-activeCyan text-[10px] font-semibold transition-all">Battery</button>
                            <button onclick="deleteUser(${u.id})" class="px-2.5 py-1.5 rounded-lg bg-rose-500/10 hover:bg-rose-500 hover:text-white border border-rose-500/20 text-rose-400 text-[10px] font-semibold transition-all">Delete</button>
                        </div>
                    </td>
                `;
                tbody.appendChild(tr);
            });
        }

        function filterUsers() {
            const query = document.getElementById('userSearch').value.toLowerCase();
            const filtered = appData.users.filter(u => u.name.toLowerCase().includes(query) || u.email.toLowerCase().includes(query));
            renderUsersTable(filtered);
        }

        function renderCouplesGrid(couples) {
            const container = document.getElementById('couplesContainer');
            container.innerHTML = '';

            if (couples.length === 0) {
                container.innerHTML = `<div class="md:col-span-2 p-8 text-center border border-white/10 bg-white/5 rounded-2xl text-white/40">No couples paired yet.</div>`;
                return;
            }

            couples.forEach(c => {
                const card = document.createElement('div');
                card.className = 'p-6 rounded-2xl border border-white/10 bg-white/5 space-y-4';

                const p1 = c.users[0] ? c.users[0].name : '<span class="text-rose-400 font-semibold">Unpaired</span>';
                const p2 = c.users[1] ? c.users[1].name : '<span class="text-rose-400 font-semibold">Unpaired</span>';

                card.innerHTML = `
                    <div class="flex items-center justify-between">
                        <span class="text-xs uppercase font-bold text-activeCyan tracking-wider">Couple Connection #${c.id}</span>
                        <span class="px-2 py-0.5 rounded bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-[10px] font-bold">Active</span>
                    </div>

                    <div class="flex items-center justify-between p-4 bg-white/5 border border-white/5 rounded-xl">
                        <div class="text-center flex-1">
                            <span class="block text-[10px] text-white/40 uppercase">Partner A</span>
                            <span class="font-bold text-white text-sm">${p1}</span>
                        </div>
                        <div class="text-electricPurple font-bold text-xl px-4 animate-pulse">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" class="w-5 h-5 inline-block" viewBox="0 0 24 24">
                                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
                            </svg>
                        </div>
                        <div class="text-center flex-1">
                            <span class="block text-[10px] text-white/40 uppercase">Partner B</span>
                            <span class="font-bold text-white text-sm">${p2}</span>
                        </div>
                    </div>

                    <div class="flex items-center justify-between text-xs text-white/50 mb-2">
                        <span>Anniversary Date:</span>
                        <span class="font-semibold text-white font-mono">${c.anniversary_start_date || 'Not configured'}</span>
                    </div>

                    <div class="pt-3 border-t border-white/5 flex items-center justify-between space-x-2">
                        <button onclick="openChatSpy(${c.id})" class="flex-grow py-2 rounded-xl bg-activeCyan/10 hover:bg-activeCyan text-activeCyan hover:text-slate-950 font-bold text-xs transition-all flex items-center justify-center space-x-1.5">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3.5 h-3.5">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
                                <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                            </svg>
                            <span>Spy Chat History</span>
                        </button>
                        <button onclick="clearChatConfirm(${c.id})" class="px-3 py-2 rounded-xl bg-rose-500/10 hover:bg-rose-500 text-rose-400 hover:text-white font-bold text-xs transition-all">
                            Purge
                        </button>
                    </div>
                `;
                container.appendChild(card);
            });
        }

        // TABS NAVIGATION
        function switchTab(tabId) {
            document.querySelectorAll('.tab-content').forEach(c => c.classList.add('hidden'));
            
            document.querySelectorAll('.tab-btn').forEach(b => {
                b.classList.remove('bg-white/10', 'text-white');
                b.classList.add('text-white/60');
            });
            document.querySelectorAll('.tab-btn-mob').forEach(b => {
                b.classList.remove('bg-white/10', 'text-white');
                b.classList.add('text-white/60');
            });

            document.getElementById(`content-${tabId}`).classList.remove('hidden');

            const btn = document.getElementById(`tab-${tabId}`);
            if (btn) {
                btn.classList.add('bg-white/10', 'text-white');
                btn.classList.remove('text-white/60');
            }
            const btnMob = document.getElementById(`tab-mob-${tabId}`);
            if (btnMob) {
                btnMob.classList.add('bg-white/10', 'text-white');
                btnMob.classList.remove('text-white/60');
            }
        }

        // --- MOCK MODALS TRIGGERS ---
        function openLocationModal(userId, lat, lon, name) {
            document.getElementById('locModalUserId').value = userId;
            document.getElementById('locModalLat').value = lat;
            document.getElementById('locModalLon').value = lon;
            document.getElementById('locModalName').value = name;
            document.getElementById('locationModal').classList.remove('hidden');
        }

        function openBatteryModal(userId, level) {
            document.getElementById('battModalUserId').value = userId;
            document.getElementById('battModalSlider').value = level;
            document.getElementById('battModalVal').innerText = level + '%';
            document.getElementById('batteryModal').classList.remove('hidden');
        }

        function closeModal(modalId) {
            document.getElementById(modalId).classList.add('hidden');
        }

        // --- DEV API ACTIONS ---
        async function adminApiCall(action, payload) {
            const token = localStorage.getItem('glimpse_admin_token');
            try {
                const response = await fetch(`/admin/api?token=${encodeURIComponent(token)}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({ action: action, ...payload })
                });

                const data = await response.json();
                if (response.ok) {
                    alert(`Success: ${data.message}`);
                    fetchData(); // Sync dashboard
                } else {
                    alert(`Error: ${data.error || 'Request failed'}`);
                }
            } catch (err) {
                console.error(err);
                alert(`Network failure during command execution.`);
            }
        }

        function submitLocationUpdate() {
            const userId = document.getElementById('locModalUserId').value;
            const lat = parseFloat(document.getElementById('locModalLat').value);
            const lon = parseFloat(document.getElementById('locModalLon').value);
            const name = document.getElementById('locModalName').value.trim();

            adminApiCall('update_location', { user_id: userId, latitude: lat, longitude: lon, location_name: name });
            closeModal('locationModal');
        }

        function submitBatteryUpdate() {
            const userId = document.getElementById('battModalUserId').value;
            const val = document.getElementById('battModalSlider').value;

            adminApiCall('update_battery', { user_id: userId, battery_level: val });
            closeModal('batteryModal');
        }

        function deleteUser(userId) {
            const confirmation = confirm(`Are you sure you want to permanently erase this user account? This will cascade-delete their uploads, pair links, and messages!`);
            if (confirmation) {
                adminApiCall('delete_user', { user_id: userId });
            }
        }

        function triggerSimulatedUpdate(type) {
            const userId = document.getElementById('simulatorUserSelect').value;
            adminApiCall('push_diagnostics', { user_id: userId, type: type });
        }

        function clearChat() {
            const coupleId = document.getElementById('clearChatCoupleSelect').value;
            const confirmation = confirm(`Clean out conversation history for Couple ID #${coupleId}? This action is irreversible!`);
            if (confirmation) {
                adminApiCall('clear_chat', { couple_id: coupleId });
            }
        }

        // --- WEBSOCKET DIAGNOSTICS MONITOR ---
        let liveWS = null;
        let wsPingInterval = null;

        function decodeProtobufJS(base64Str, event = '') {
            try {
                const binStr = atob(base64Str);
                const len = binStr.length;
                const bytes = new Uint8Array(len);
                for (let i = 0; i < len; i++) {
                    bytes[i] = binStr.charCodeAt(i);
                }
                
                let offset = 0;
                const result = {};
                
                while (offset < bytes.length) {
                    const tag = decodeVarint();
                    const fieldNum = tag >> 3;
                    const wireType = tag & 0x07;
                    
                    if (wireType === 0) { // Varint
                        const val = decodeVarint();
                        if (event.includes('Typing')) {
                            if (fieldNum === 1) result.user_id = val;
                            else if (fieldNum === 2) result.is_typing = val !== 0;
                        } else if (event.includes('PartnerStateUpdated')) {
                            if (fieldNum === 1) result.user_id = val;
                            else if (fieldNum === 4) result.battery_level = val;
                            else if (fieldNum === 5) result.is_charging = val !== 0;
                        } else {
                            if (fieldNum === 1) result.id = val;
                            else if (fieldNum === 2) result.room_id = val;
                            else if (fieldNum === 3) result.sender_id = val;
                            else result[`field_${fieldNum}`] = val;
                        }
                    } else if (wireType === 2) { // Length-delimited
                        const length = decodeVarint();
                        const strBytes = bytes.slice(offset, offset + length);
                        offset += length;
                        const text = new TextDecoder().decode(strBytes);
                        if (event.includes('PartnerStateUpdated')) {
                            if (fieldNum === 2) result.latitude = text;
                            else if (fieldNum === 3) result.longitude = text;
                            else if (fieldNum === 6) result.status_note = text;
                            else if (fieldNum === 7) result.location_name = text;
                            else if (fieldNum === 8) result.wifi_bssid = text;
                        } else {
                            if (fieldNum === 4) result.message = text;
                            else if (fieldNum === 5) result.created_at = text;
                            else result[`field_${fieldNum}`] = text;
                        }
                    } else {
                        break;
                    }
                }
                return result;

                function decodeVarint() {
                    let value = 0;
                    let shift = 0;
                    while (offset < bytes.length) {
                        const byte = bytes[offset++];
                        value |= (byte & 0x7F) << shift;
                        if ((byte & 0x80) === 0) {
                            break;
                        }
                        shift += 7;
                    }
                    return value;
                }
            } catch (e) {
                console.error("Protobuf decoder failure:", e);
                return null;
            }
        }

        function base64ToHex(base64Str) {
            try {
                const binStr = atob(base64Str);
                let hex = '';
                for (let i = 0; i < binStr.length; i++) {
                    const code = binStr.charCodeAt(i).toString(16).padStart(2, '0');
                    hex += code + ' ';
                }
                return hex.trim().toUpperCase();
            } catch (e) {
                return '';
            }
        }

        function logWSEvent(event, channel, data) {
            const stream = document.getElementById('ws-log-stream');
            if (!stream) return;
            
            if (stream.innerHTML.includes('Waiting for events...')) {
                stream.innerHTML = '';
            }
            
            const time = new Date().toLocaleTimeString([], { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
            const logItem = document.createElement('div');
            logItem.className = 'border-b border-white/5 pb-2.5 pt-1';
            
            let color = 'text-white/60';
            if (event.includes('MessageSent')) color = 'text-activeCyan font-semibold';
            else if (event.includes('PartnerStateUpdated')) color = 'text-emerald-400 font-semibold';
            else if (event.includes('LoveBurstSent')) color = 'text-rose-400 font-semibold';
            else if (event.includes('Typing')) color = 'text-amber-400 font-semibold';
            else if (event.includes('established') || event.includes('subscription')) color = 'text-white/40';
            
            // Check if Protobuf payload is inside data
            let pbDecoded = null;
            if (data && typeof data === 'object' && data.pb) {
                pbDecoded = decodeProtobufJS(data.pb, event);
            }
            
            let dataStr = typeof data === 'object' ? JSON.stringify(data) : data;
            if (dataStr.length > 120) {
                dataStr = dataStr.substring(0, 120) + '...';
            }
            
            let pbSection = '';
            if (pbDecoded) {
                const rawJsonBytes = new TextEncoder().encode(JSON.stringify(data.message || data)).length;
                const pbBytes = Math.ceil((data.pb.length * 3) / 4) - (data.pb.indexOf('=') > 0 ? (data.pb.length - data.pb.indexOf('=')) : 0);
                const saving = Math.round(((rawJsonBytes - pbBytes) / rawJsonBytes) * 100);
                const rawHex = base64ToHex(data.pb);
                
                let detailsHtml = '';
                let tagsHtml = '';
                
                if (event.includes('Typing')) {
                    detailsHtml = `
                        <div class="p-1.5 bg-slate-950/60 rounded border border-white/5">
                            <span class="block text-white/40 text-[8px] uppercase">User ID</span>
                            <span class="font-bold text-white">${pbDecoded.user_id || '-'}</span>
                        </div>
                        <div class="p-1.5 bg-slate-950/60 rounded border border-white/5">
                            <span class="block text-white/40 text-[8px] uppercase">Is Typing</span>
                            <span class="font-bold text-activeCyan">${pbDecoded.is_typing ? 'TRUE' : 'FALSE'}</span>
                        </div>
                    `;
                    tagsHtml = `
                        <div><span class="text-emerald-400 font-bold">1</span> = <span class="text-white">${pbDecoded.user_id || '-'}</span> <span class="text-white/30 text-[7.5px] font-normal">(User ID)</span></div>
                        <div><span class="text-emerald-400 font-bold">2</span> = <span class="text-emerald-300">${pbDecoded.is_typing ? '1 (True)' : '0 (False)'}</span> <span class="text-white/30 text-[7.5px] font-normal">(Is Typing)</span></div>
                    `;
                } else if (event.includes('PartnerStateUpdated')) {
                    detailsHtml = `
                        <div class="p-1.5 bg-slate-950/60 rounded border border-white/5">
                            <span class="block text-white/40 text-[8px] uppercase">User ID</span>
                            <span class="font-bold text-white">${pbDecoded.user_id || '-'}</span>
                        </div>
                        <div class="p-1.5 bg-slate-950/60 rounded border border-white/5">
                            <span class="block text-white/40 text-[8px] uppercase">Battery</span>
                            <span class="font-bold text-white">${pbDecoded.battery_level !== undefined ? pbDecoded.battery_level + '%' : '-'}</span>
                        </div>
                        <div class="p-1.5 bg-slate-950/60 rounded border border-white/5 col-span-2">
                            <span class="block text-white/40 text-[8px] uppercase">Coordinates</span>
                            <span class="font-bold text-activeCyan">${pbDecoded.latitude || '-'}, ${pbDecoded.longitude || '-'}</span>
                        </div>
                        <div class="p-1.5 bg-slate-950/60 rounded border border-white/5 col-span-2">
                            <span class="block text-white/40 text-[8px] uppercase">Location Name</span>
                            <span class="text-white break-words">${pbDecoded.location_name || '-'}</span>
                        </div>
                    `;
                    tagsHtml = `
                        <div><span class="text-emerald-400 font-bold">1</span> = <span class="text-white">${pbDecoded.user_id || '-'}</span> <span class="text-white/30 text-[7.5px] font-normal">(User ID)</span></div>
                        <div><span class="text-emerald-400 font-bold">2</span> = <span class="text-emerald-300">"${pbDecoded.latitude || '-'}"</span> <span class="text-white/30 text-[7.5px] font-normal">(Latitude)</span></div>
                        <div><span class="text-emerald-400 font-bold">3</span> = <span class="text-emerald-300">"${pbDecoded.longitude || '-'}"</span> <span class="text-white/30 text-[7.5px] font-normal">(Longitude)</span></div>
                        <div><span class="text-emerald-400 font-bold">4</span> = <span class="text-white">${pbDecoded.battery_level !== undefined ? pbDecoded.battery_level : '-'}</span> <span class="text-white/30 text-[7.5px] font-normal">(Battery Level)</span></div>
                        <div><span class="text-emerald-400 font-bold">5</span> = <span class="text-white">${pbDecoded.is_charging ? '1 (Charging)' : '0'}</span> <span class="text-white/30 text-[7.5px] font-normal">(Is Charging)</span></div>
                        <div><span class="text-emerald-400 font-bold">6</span> = <span class="text-white/80">"${pbDecoded.status_note || '-'}"</span> <span class="text-white/30 text-[7.5px] font-normal">(Status Note)</span></div>
                        <div><span class="text-emerald-400 font-bold">7</span> = <span class="text-white/80">"${pbDecoded.location_name || '-'}"</span> <span class="text-white/30 text-[7.5px] font-normal">(Location Name)</span></div>
                        <div><span class="text-emerald-400 font-bold">8</span> = <span class="text-white/80">"${pbDecoded.wifi_bssid || '-'}"</span> <span class="text-white/30 text-[7.5px] font-normal">(Wifi BSSID)</span></div>
                    `;
                } else {
                    detailsHtml = `
                        <div class="p-1.5 bg-slate-950/60 rounded border border-white/5">
                            <span class="block text-white/40 text-[8px] uppercase">Message ID</span>
                            <span class="font-bold text-white">${pbDecoded.id || '-'}</span>
                        </div>
                        <div class="p-1.5 bg-slate-950/60 rounded border border-white/5">
                            <span class="block text-white/40 text-[8px] uppercase">Sender ID</span>
                            <span class="font-bold text-white">${pbDecoded.sender_id || '-'}</span>
                        </div>
                        <div class="p-1.5 bg-slate-950/60 rounded border border-white/5 col-span-2">
                            <span class="block text-white/40 text-[8px] uppercase">Message Content</span>
                            <span class="font-bold text-activeCyan break-words">${pbDecoded.message || '-'}</span>
                        </div>
                        <div class="p-1.5 bg-slate-950/60 rounded border border-white/5 col-span-2">
                            <span class="block text-white/40 text-[8px] uppercase">Created At</span>
                            <span class="text-white">${pbDecoded.created_at || '-'}</span>
                        </div>
                    `;
                    tagsHtml = `
                        <div><span class="text-emerald-400 font-bold">1</span> = <span class="text-white">${pbDecoded.id || '-'}</span> <span class="text-white/30 text-[7.5px] font-normal">(Message ID)</span></div>
                        <div><span class="text-emerald-400 font-bold">2</span> = <span class="text-white">${pbDecoded.room_id || '0'}</span> <span class="text-white/30 text-[7.5px] font-normal">(Room ID)</span></div>
                        <div><span class="text-emerald-400 font-bold">3</span> = <span class="text-white">${pbDecoded.sender_id || '-'}</span> <span class="text-white/30 text-[7.5px] font-normal">(Sender ID)</span></div>
                        <div><span class="text-emerald-400 font-bold">4</span> = <span class="text-emerald-300">"${pbDecoded.message || '-'}"</span> <span class="text-white/30 text-[7.5px] font-normal">(Message)</span></div>
                        <div><span class="text-emerald-400 font-bold">5</span> = <span class="text-white/80">"${pbDecoded.created_at || '-'}"</span> <span class="text-white/30 text-[7.5px] font-normal">(Created At)</span></div>
                    `;
                }
                
                pbSection = `
                    <div class="mt-2 ml-4 p-3 rounded-xl bg-activeCyan/10 border border-activeCyan/20 text-[10px] space-y-1.5 shadow-lg shadow-activeCyan/5 relative overflow-hidden group">
                        <div class="absolute -right-8 -bottom-8 w-16 h-16 rounded-full bg-activeCyan/5 blur-md group-hover:scale-150 transition-all"></div>
                        <div class="flex items-center justify-between">
                            <span class="text-activeCyan font-extrabold flex items-center space-x-1.5">
                                <span class="w-1.5 h-1.5 rounded-full bg-activeCyan animate-ping"></span>
                                <span>⚡️ PROTOBUF BINARY DECODED</span>
                            </span>
                            <span class="px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400 font-bold text-[9px] border border-emerald-500/20">-${saving}% Size Saved</span>
                        </div>
                        <div class="grid grid-cols-2 gap-2 font-mono text-[9px]">
                            ${detailsHtml}
                            <!-- PURE WHATSAPP-STYLE TAGS -->
                            <div class="p-2.5 bg-slate-950 rounded border border-emerald-500/30 col-span-2 font-mono text-[9px] space-y-1 bg-gradient-to-r from-slate-950 to-slate-900 shadow-inner">
                                <span class="block text-emerald-400 text-[8px] uppercase font-bold tracking-wider mb-1.5 flex items-center space-x-1">
                                    <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                                    <span>WhatsApp-Style Wire Tag View (No JSON)</span>
                                </span>
                                <div class="text-[8.5px] text-white/90 space-y-0.5">
                                    ${tagsHtml}
                                </div>
                            </div>
                            <!-- RAW PROTOBUF BINARY / HEX LOGGER -->
                            <div class="p-1.5 bg-slate-950/60 rounded border border-white/5 col-span-2">
                                <span class="block text-amber-400 text-[8px] uppercase font-bold">Raw Hexadecimal Bytes (Kode Acak)</span>
                                <span class="text-amber-300 break-all select-all font-semibold font-mono text-[8px]">${rawHex}</span>
                            </div>
                            <div class="p-1.5 bg-slate-950/60 rounded border border-white/5 col-span-2">
                                <span class="block text-white/40 text-[8px] uppercase">Raw Base64 Encoded Payload</span>
                                <span class="text-white/60 break-all select-all font-mono text-[8.5px]">${data.pb}</span>
                            </div>
                        </div>
                        <div class="flex justify-between items-center text-[8px] font-mono text-white/40 pt-1 border-t border-white/5">
                            <span>Protobuf size: <b>${pbBytes} bytes</b></span>
                            <span>Raw JSON size: <b>${rawJsonBytes} bytes</b></span>
                        </div>
                    </div>
                `;
            }
            
            logItem.innerHTML = `
                <div class="flex items-center space-x-1.5">
                    <span class="text-white/30 font-mono">[${time}]</span> 
                    <span class="${color}">${event}</span> 
                    <span class="text-electricPurple/70 font-mono">(${channel || 'global'})</span>
                </div>
                <span class="block text-white/50 pl-4 break-all font-mono mt-0.5">${dataStr}</span>
                ${pbSection}
            `;
            
            stream.appendChild(logItem);
            stream.scrollTop = stream.scrollHeight;
            
            // Prune old logs to keep client-side DOM extremely light (0% server load, protects browser memory)
            while (stream.children.length > 30) {
                stream.removeChild(stream.firstChild);
            }

            // Log to Diagnostics Stream if it exists
            const diagStream = document.getElementById('diag-ws-log-stream');
            if (diagStream) {
                if (diagStream.innerHTML.includes('Waiting for events')) {
                    diagStream.innerHTML = '';
                }
                
                // Apply filters
                let isFiltered = false;
                if (event.includes('MessageSent') && !document.getElementById('filter-pb').checked) isFiltered = true;
                else if (event.includes('PartnerStateUpdated') && !document.getElementById('filter-state').checked) isFiltered = true;
                else if (event.includes('LoveBurstSent') && !document.getElementById('filter-burst').checked) isFiltered = true;
                else if (event.includes('Typing') && !document.getElementById('filter-typing').checked) isFiltered = true;
                
                if (!isFiltered) {
                    const diagLogItem = logItem.cloneNode(true);
                    diagStream.appendChild(diagLogItem);
                    diagStream.scrollTop = diagStream.scrollHeight;
                    
                    while (diagStream.children.length > 50) {
                        diagStream.removeChild(diagStream.firstChild);
                    }
                }
            }
        }

        function clearWSLogs() {
            const stream = document.getElementById('ws-log-stream');
            if (stream) {
                stream.innerHTML = '<div class="text-white/40 italic">Waiting for events...</div>';
            }
        }

        function startWebSocketDiagnostics() {
            if (liveWS) return;

            const isHttps = window.location.protocol === 'https:';
            const wsProtocol = isHttps ? 'wss:' : 'ws:';
            const host = window.location.hostname;
            const isLocal = host.includes('localhost') || host.includes('127.0.0.1') || host.includes('192.168.');
            const appKey = "u1eadho8wbhzv2mcnlfy";
            
            const wsUrl = isLocal ? 
                `${wsProtocol}//${host}:8080/app/${appKey}?protocol=7&client=js&version=8.4.0-reverb` :
                `${wsProtocol}//${host}/app/${appKey}?protocol=7&client=js&version=8.4.0-reverb`;
            
            try {
                liveWS = new WebSocket(wsUrl);
                
                liveWS.onopen = () => {
                    document.getElementById('ws-diag-indicator').className = "w-2.5 h-2.5 rounded-full bg-emerald-500";
                    document.getElementById('ws-diag-status').innerText = "Live Connected";
                    document.getElementById('ws-diag-status').className = "text-xs font-bold text-emerald-400";
                    
                    logWSEvent('System: connection_established', '', { url: wsUrl });
                    
                    // Auto-subscribe to all loaded couples' channels
                    if (appData.couples) {
                        appData.couples.forEach(c => {
                            liveWS.send(JSON.stringify({
                                event: 'pusher:subscribe',
                                data: { channel: `couple.${c.id}` }
                            }));
                        });
                        document.getElementById('ws-diag-channels').innerText = `${appData.couples.length} channels monitored`;
                    }
                    
                    let pingStart = Date.now();
                    liveWS.send(JSON.stringify({ event: 'pusher:ping', data: {} }));
                    
                    wsPingInterval = setInterval(() => {
                        pingStart = Date.now();
                        if (liveWS && liveWS.readyState === WebSocket.OPEN) {
                            liveWS.send(JSON.stringify({ event: 'pusher:ping', data: {} }));
                        }
                    }, 10000);

                    liveWS.onmessage = (event) => {
                        const payload = JSON.parse(event.data);
                        
                        if (payload.event === 'pusher:pong') {
                            const latency = Date.now() - pingStart;
                            document.getElementById('ws-diag-latency').innerText = `${latency} ms`;
                        } else if (payload.event === 'pusher:error') {
                            console.error("Pusher error details:", payload.data);
                            logWSEvent('pusher:error', '', payload.data);
                        } else {
                            let eventData = payload.data;
                            if (typeof eventData === 'string') {
                                try { eventData = JSON.parse(eventData); } catch(e) {}
                            }
                            logWSEvent(payload.event, payload.channel, eventData);
                        }
                    };
                };

                liveWS.onclose = () => {
                    document.getElementById('ws-diag-indicator').className = "w-2.5 h-2.5 rounded-full bg-rose-500 animate-pulse";
                    document.getElementById('ws-diag-status').innerText = "Disconnected";
                    document.getElementById('ws-diag-status').className = "text-xs font-bold text-rose-400";
                    clearInterval(wsPingInterval);
                    liveWS = null;
                    
                    // Reconnect attempt in 5 seconds
                    setTimeout(startWebSocketDiagnostics, 5000);
                };

                liveWS.onerror = (err) => {
                    console.error("Diagnostics socket failed:", err);
                };

            } catch (socketErr) {
                console.error("Websocket init failed:", socketErr);
            }
        }

        // --- DEWA (GOD MODE) UTILITIES ---
        async function dewaApiCall(action, payload) {
            const token = localStorage.getItem('glimpse_admin_token');
            try {
                const response = await fetch(`/admin/api?token=${encodeURIComponent(token)}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({ action: action, ...payload })
                });

                const data = await response.json();
                if (response.ok) {
                    alert(`Dewa Success: ${data.message}`);
                    fetchData(); // Sync dashboard
                } else {
                    alert(`Dewa Error: ${data.error || 'Request failed'}`);
                }
            } catch (err) {
                console.error(err);
                alert(`Network failure during Dewa command execution.`);
            }
        }

        function executeFlashPrune() {
            const userId = document.getElementById('dewaPruneUserSelect').value;
            const daysAgo = document.getElementById('dewaPruneDaysSelect').value;
            const confirmation = confirm(`DEWA COMMAND WARNING\n\nAre you sure you want to exterminate Glimpse Flash records for this selection? This will physically and permanently erase flash files from the server's disk!`);
            if (confirmation) {
                dewaApiCall('delete_flashes', { user_id: userId, days_ago: daysAgo });
            }
        }

        function executeGodLink() {
            const user1 = document.getElementById('dewaLinkUser1Select').value;
            const user2 = document.getElementById('dewaLinkUser2Select').value;
            if (user1 === user2) {
                alert("Cannot establish link between the same user!");
                return;
            }
            const confirmation = confirm(`Establish direct God-Link between User ID ${user1} and User ID ${user2} instantly?`);
            if (confirmation) {
                dewaApiCall('forced_couple_link', { user_1_id: user1, user_2_id: user2 });
            }
        }

        function executeGlobalBroadcast() {
            const text = document.getElementById('dewaBroadcastText').value.trim();
            if (!text) {
                alert("Please write an announcement text to broadcast!");
                return;
            }
            const confirmation = confirm(`Broadcast system announcement to all active couple companion devices instantly?`);
            if (confirmation) {
                dewaApiCall('broadcast_announcement', { text: text });
                document.getElementById('dewaBroadcastText').value = '';
            }
        }

        function executeDatabaseOptimize() {
            const confirmation = confirm(`Run system engine database vacuuming & orphans purge?`);
            if (confirmation) {
                dewaApiCall('database_optimize', {});
            }
        }

        async function executeChangeAdminToken() {
            const newToken = document.getElementById('dewaNewTokenInput').value.trim();
            if (!newToken) {
                alert("Please enter a new access token!");
                return;
            }
            const confirmation = confirm(`DEWA COMMAND: Change Master Admin Token?\n\nYou will be logged out and must log in again with the new token.`);
            if (confirmation) {
                const token = localStorage.getItem('glimpse_admin_token');
                try {
                    const response = await fetch(`/admin/api?token=${encodeURIComponent(token)}`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                            'X-Admin-Token': token
                        },
                        body: JSON.stringify({ action: 'change_admin_token', new_token: newToken })
                    });

                    const data = await response.json();
                    if (response.ok) {
                        alert(`Dewa Success: ${data.message}`);
                        handleLogout(); // Automatically log out
                    } else {
                        alert(`Dewa Error: ${data.error || 'Request failed'}`);
                    }
                } catch (err) {
                    console.error(err);
                    alert(`Network failure during Dewa command execution.`);
                }
            }
        }

        // --- DEWA SPYGLASS HANDLERS ---
        let activeSpyCoupleId = null;
        let activeSpyUsers = [];

        async function openChatSpy(coupleId) {
            activeSpyCoupleId = coupleId;
            const token = localStorage.getItem('glimpse_admin_token');
            const stream = document.getElementById('spyChatStream');
            stream.innerHTML = '<div class="p-8 text-center text-white/40 animate-pulse">Establishing secure spy tunnel connection...</div>';
            
            document.getElementById('chatSpyModal').classList.remove('hidden');

            try {
                const response = await fetch(`/admin/api?token=${encodeURIComponent(token)}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({ action: 'get_chat_history', couple_id: coupleId })
                });

                if (response.ok) {
                    const data = await response.json();
                    activeSpyUsers = data.couple.users;
                    
                    const names = activeSpyUsers.map(u => u.name).join(' & ');
                    document.getElementById('spyModalTitle').innerText = `Spyglass: ${names || 'Unpaired Couple'}`;

                    const senderSelect = document.getElementById('spySenderSelect');
                    senderSelect.innerHTML = '<option value="0">System Announcement</option>';
                    activeSpyUsers.forEach(u => {
                        const opt = document.createElement('option');
                        opt.value = u.id;
                        opt.innerText = u.name;
                        senderSelect.appendChild(opt);
                    });

                    renderSpyMessages(data.messages);
                } else {
                    const data = await response.json().catch(() => ({}));
                    stream.innerHTML = `<div class="p-8 text-center text-rose-400">Failed to establish spy tunnel connection: ${data.error || 'Server error'}</div>`;
                }
            } catch (err) {
                console.error(err);
                stream.innerHTML = '<div class="p-8 text-center text-rose-400 font-semibold">Spy tunnel failure. Connection lost.</div>';
            }
        }

        function renderSpyMessages(messages) {
            const stream = document.getElementById('spyChatStream');
            stream.innerHTML = '';

            if (messages.length === 0) {
                stream.innerHTML = '<div class="p-12 text-center text-white/30 text-xs italic">Conversation is currently silent. No messages found.</div>';
                return;
            }

            messages.forEach(m => {
                const bubble = document.createElement('div');
                
                // System message (sender_id = 0 or starts/contains system announcement marker)
                if (m.sender_id === 0 || m.message.includes('[SYSTEM') || m.message.includes('[ANNOUNCEMENT')) {
                    bubble.className = 'flex justify-center my-2 w-full';
                    bubble.innerHTML = `
                        <div class="px-3 py-1 rounded-lg bg-white/5 border border-white/10 text-[10px] text-white/60 font-mono tracking-tight max-w-sm text-center">
                            ${m.message}
                        </div>
                    `;
                } else {
                    const sender = activeSpyUsers.find(u => u.id === m.sender_id);
                    const senderName = sender ? sender.name : 'Unknown User';
                    const avatar = sender && sender.profile_photo_url ? sender.profile_photo_url : `https://ui-avatars.com/api/?name=${encodeURIComponent(senderName)}`;
                    
                    const isUser1 = activeSpyUsers[0] && m.sender_id === activeSpyUsers[0].id;
                    bubble.className = `flex ${isUser1 ? 'justify-start' : 'justify-end'} space-x-2 p-1`;
                    
                    const time = new Date(m.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

                    bubble.innerHTML = `
                        <div class="flex items-start space-x-2 max-w-[80%] ${isUser1 ? '' : 'flex-row-reverse space-x-reverse'}">
                            <img src="${avatar}" class="w-8 h-8 rounded-full border border-white/10 object-cover flex-shrink-0" onerror="this.src='https://ui-avatars.com/api/?name=User'">
                            <div class="space-y-1">
                                <span class="block text-[9px] text-white/40 ${isUser1 ? 'text-left' : 'text-right'} font-semibold">${senderName}</span>
                                <div class="px-3 py-2 rounded-2xl text-xs text-white ${isUser1 ? 'bg-white/10 rounded-tl-none border border-white/5' : 'bg-electricPurple/20 rounded-tr-none border border-electricPurple/30'}">
                                    ${m.message}
                                </div>
                                <span class="block text-[8px] text-white/30 ${isUser1 ? 'text-left' : 'text-right'} font-mono">${time}</span>
                            </div>
                        </div>
                    `;
                }
                
                stream.appendChild(bubble);
            });

            setTimeout(() => {
                stream.scrollTop = stream.scrollHeight;
            }, 50);
        }

        function closeChatSpy() {
            document.getElementById('chatSpyModal').classList.add('hidden');
            activeSpyCoupleId = null;
            activeSpyUsers = [];
        }

        async function injectSpyMessage() {
            const input = document.getElementById('spyMockMessageInput');
            const message = input.value.trim();
            const senderId = document.getElementById('spySenderSelect').value;

            if (!message) {
                alert("Please write a message to inject!");
                return;
            }

            const token = localStorage.getItem('glimpse_admin_token');
            try {
                const response = await fetch(`/admin/api?token=${encodeURIComponent(token)}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({
                        action: 'inject_spy_message',
                        couple_id: activeSpyCoupleId,
                        sender_id: senderId,
                        message: message
                    })
                });

                const data = await response.json();
                if (response.ok) {
                    input.value = '';
                    openChatSpy(activeSpyCoupleId); // Refresh history stream
                } else {
                    alert(`Injection failed: ${data.error || 'Server error'}`);
                }
            } catch (err) {
                console.error(err);
                alert("Connection lost. Failed to inject mock message.");
            }
        }

        function clearChatConfirm(coupleId) {
            const confirmation = confirm("Are you sure you want to permanently clear the conversation history for this couple? This action is irreversible!");
            if (confirmation) {
                dewaApiCall('clear_chat', { couple_id: coupleId });
            }
        }

        // --- REAL-TIME BANDWIDTH CANVAS MONITOR ---
        let txHistory = Array(30).fill(0);
        let rxHistory = Array(30).fill(0);

        function startBandwidthMonitor() {
            const canvas = document.getElementById('bandwidthCanvas');
            if (!canvas) return;

            const ctx = canvas.getContext('2d');
            
            // Adjust to responsive bounds
            function resizeCanvas() {
                canvas.width = canvas.parentElement.clientWidth;
                canvas.height = canvas.parentElement.clientHeight;
            }
            resizeCanvas();
            window.addEventListener('resize', resizeCanvas);

            // Generate mock traffic speeds (normal operations)
            setInterval(() => {
                const activeFactor = appData.stats && appData.stats.active_sessions ? appData.stats.active_sessions : 1;
                const mockRxSpeed = (Math.random() * 450 + 50) * activeFactor; // KB/s
                const mockTxSpeed = (Math.random() * 200 + 20) * activeFactor; // KB/s

                // Shift speeds history
                rxHistory.push(mockRxSpeed);
                rxHistory.shift();
                txHistory.push(mockTxSpeed);
                txHistory.shift();

                // Format values into elements
                document.getElementById('rx-speed').innerText = `${(mockRxSpeed / 1024).toFixed(2)} MB/s`;
                document.getElementById('tx-speed').innerText = `${(mockTxSpeed / 1024).toFixed(2)} MB/s`;

                // Calculate cumulative volumes
                const totalRxBytes = rxHistory.reduce((acc, v) => acc + v, 0) * 1024 * 1.5;
                const totalTxBytes = txHistory.reduce((acc, v) => acc + v, 0) * 1024 * 1.3;
                document.getElementById('rx-total').innerText = formatBytesBandwidth(totalRxBytes);
                document.getElementById('tx-total').innerText = formatBytesBandwidth(totalTxBytes);

                // Render Canvas Spline lines
                drawTrafficGraph(canvas, ctx);
            }, 1000);
        }

        function formatBytesBandwidth(bytes) {
            if (bytes === 0) return '0 B';
            const k = 1024;
            const sizes = ['B', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }

        function drawTrafficGraph(canvas, ctx) {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            
            // Draw grid background line paths
            ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
            ctx.lineWidth = 1;
            for (let i = 1; i < 4; i++) {
                const y = (canvas.height / 4) * i;
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(canvas.width, y);
                ctx.stroke();
            }

            const maxSpeedVal = Math.max(...rxHistory, ...txHistory, 100);
            
            // Render curves
            drawSplineLine(canvas, ctx, rxHistory, maxSpeedVal, '#00FFFF', 'rgba(0, 255, 255, 0.08)');
            drawSplineLine(canvas, ctx, txHistory, maxSpeedVal, '#BF80FF', 'rgba(191, 128, 255, 0.08)');
        }

        // --- LIVE DIAGNOSTICS & PROTOBUF DEBUGGER SUITE ---
        function clearDiagWSLogs() {
            const stream = document.getElementById('diag-ws-log-stream');
            if (stream) {
                stream.innerHTML = '<div class="text-white/40 italic">Waiting for events from active couple channels...</div>';
            }
        }

        // Lightweight Pure JS Protobuf v3 Encoder matching the Swift/PHP models
        function encodeProtobufJS(message) {
            let data = [];
            
            // Helper to write varint
            function writeVarint(val) {
                let value = val;
                while (value >= 0x80) {
                    data.push((value & 0x7F) | 0x80);
                    value >>= 7;
                }
                data.push(value & 0x7F);
            }
            
            // Helper to write tag
            function writeTag(fieldNum, wireType) {
                writeVarint((fieldNum << 3) | wireType);
            }
            
            // Field 1: id (Varint)
            if (message.id) {
                writeTag(1, 0);
                writeVarint(message.id);
            }
            
            // Field 2: room_id (Varint)
            if (message.room_id) {
                writeTag(2, 0);
                writeVarint(message.room_id);
            }
            
            // Field 3: sender_id (Varint)
            if (message.sender_id) {
                writeTag(3, 0);
                writeVarint(message.sender_id);
            }
            
            // Field 4: message (Length-delimited string)
            if (message.message) {
                const encoder = new TextEncoder();
                const strBytes = encoder.encode(message.message);
                writeTag(4, 2);
                writeVarint(strBytes.length);
                for (let i = 0; i < strBytes.length; i++) {
                    data.push(strBytes[i]);
                }
            }
            
            // Field 5: created_at (Length-delimited string)
            if (message.created_at) {
                const encoder = new TextEncoder();
                const strBytes = encoder.encode(message.created_at);
                writeTag(5, 2);
                writeVarint(strBytes.length);
                for (let i = 0; i < strBytes.length; i++) {
                    data.push(strBytes[i]);
                }
            }
            
            return new Uint8Array(data);
        }

        function uint8ArrayToHex(arr) {
            let hex = '';
            for (let i = 0; i < arr.length; i++) {
                hex += arr[i].toString(16).padStart(2, '0') + ' ';
            }
            return hex.trim().toUpperCase();
        }

        async function updateDiagRooms() {
            const userId = document.getElementById('diagUserSelect').value;
            const roomSelect = document.getElementById('diagRoomSelect');
            if (!userId) return;

            const token = localStorage.getItem('glimpse_admin_token');
            try {
                const response = await fetch(`/admin/api?token=${encodeURIComponent(token)}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({ action: 'get_user_rooms', user_id: userId })
                });

                if (response.ok) {
                    const rooms = await response.json();
                    roomSelect.innerHTML = '';
                    if (rooms.length === 0) {
                        roomSelect.innerHTML = '<option value="">No Rooms (User is Single)</option>';
                        return;
                    }
                    rooms.forEach(r => {
                        const opt = document.createElement('option');
                        opt.value = r.id;
                        opt.innerText = `${r.name} (ID: ${r.id}${r.is_main ? ' - Main' : ''})`;
                        roomSelect.appendChild(opt);
                    });
                }
            } catch (err) {
                console.error("Failed to load rooms:", err);
            }
        }

        async function sendHTTPProtobufRequest() {
            const userId = document.getElementById('diagUserSelect').value;
            const roomId = document.getElementById('diagRoomSelect').value;
            const messageText = document.getElementById('diagMessageText').value;

            if (!userId) {
                alert("Please select a valid sender user.");
                return;
            }
            if (!messageText.trim()) {
                alert("Please enter message text.");
                return;
            }

            const outputBox = document.getElementById('diag-http-output');
            const reqHexSpan = document.getElementById('diag-http-req-hex');
            const respJsonSpan = document.getElementById('diag-http-resp-json');
            const statsDiv = document.getElementById('diag-http-stats');

            outputBox.classList.remove('hidden');
            reqHexSpan.innerText = "Encoding...";
            respJsonSpan.innerText = "Sending pure Protobuf binary request...";
            statsDiv.innerText = "";

            const startTime = performance.now();

            // 1. Encode payload to raw Protobuf binary in-browser
            const payload = {
                id: 0,
                room_id: roomId ? parseInt(roomId) : 0,
                sender_id: parseInt(userId),
                message: messageText,
                created_at: ""
            };
            const reqBytes = encodeProtobufJS(payload);
            const reqHex = uint8ArrayToHex(reqBytes);
            reqHexSpan.innerText = reqHex || '[Empty Payload]';

            // 2. Fetch POST raw binary to Admin API simulating a client request
            const token = localStorage.getItem('glimpse_admin_token');
            try {
                const response = await fetch(`/admin/api?token=${encodeURIComponent(token)}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/x-protobuf',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({
                        action: 'simulate_protobuf_post',
                        user_id: userId,
                        room_id: roomId ? parseInt(roomId) : null,
                        message: messageText
                    })
                });

                if (response.ok) {
                    const respBytes = new Uint8Array(await response.arrayBuffer());
                    const respHex = uint8ArrayToHex(respBytes);
                    
                    // Convert binary back to base64 to leverage our existing JS decoder
                    let binaryString = '';
                    for (let i = 0; i < respBytes.length; i++) {
                        binaryString += String.fromCharCode(respBytes[i]);
                    }
                    const base64 = btoa(binaryString);
                    const decoded = decodeProtobufJS(base64);

                    const duration = (performance.now() - startTime).toFixed(2);
                    const waStyle = `⚡️ WhatsApp-Style Wire Tag View (No JSON):
1 = ${decoded.id || '-'} (Message ID)
2 = ${decoded.room_id || '0'} (Room ID)
3 = ${decoded.sender_id || '-'} (Sender ID)
4 = "${decoded.message || '-'}" (Message)
5 = "${decoded.created_at || '-'}" (Created At)`;

                    respJsonSpan.innerText = waStyle + `\n\nPure Protobuf Decoded Fields:\n` + JSON.stringify(decoded, null, 4) + `\n\nResponse Hex Bytes:\n${respHex}`;
                    statsDiv.innerHTML = `Payload Size: <b>${reqBytes.length} bytes</b> | Response Size: <b>${respBytes.length} bytes</b> | Latency: <b>${duration} ms</b>`;
                    
                    // Clear inputs
                    document.getElementById('diagMessageText').value = '';
                    
                    // Force refresh main UI data to show updated chat count!
                    fetchData();
                } else {
                    respJsonSpan.innerText = "HTTP Error " + response.status;
                }
            } catch (err) {
                console.error(err);
                respJsonSpan.innerText = "Failed to transmit Protobuf binary: " + err.message;
            }
        }

        // --- GLIMPSE FLASH SIMULATOR & STORAGE DIAGNOSTICS HANDLERS ---
        let mockFlashImageBase64 = '';

        function generateMockFlashImage() {
            const canvas = document.createElement('canvas');
            canvas.width = 512;
            canvas.height = 512;
            const ctx = canvas.getContext('2d');

            // Draw a gorgeous aesthetic gradient background
            const gradient = ctx.createLinearGradient(0, 0, 512, 512);
            gradient.addColorStop(0, '#f97316'); // Orange
            gradient.addColorStop(0.5, '#ec4899'); // Pink
            gradient.addColorStop(1, '#a855f7'); // Purple
            ctx.fillStyle = gradient;
            ctx.fillRect(0, 0, 512, 512);

            // Draw clean subtle grid patterns for that premium blueprint look
            ctx.strokeStyle = 'rgba(255, 255, 255, 0.08)';
            ctx.lineWidth = 1;
            for (let i = 32; i < 512; i += 32) {
                ctx.beginPath();
                ctx.moveTo(i, 0); ctx.lineTo(i, 512);
                ctx.moveTo(0, i); ctx.lineTo(512, i);
                ctx.stroke();
            }

            // Draw a cute retro camera graphic
            ctx.fillStyle = 'rgba(255, 255, 255, 0.2)';
            ctx.beginPath();
            ctx.roundRect(156, 180, 200, 150, 24);
            ctx.fill();
            
            // Camera lens
            ctx.fillStyle = '#1e1b4b'; // Deep Indigo
            ctx.beginPath();
            ctx.arc(256, 255, 50, 0, Math.PI * 2);
            ctx.fill();
            
            ctx.strokeStyle = 'rgba(255, 255, 255, 0.4)';
            ctx.lineWidth = 6;
            ctx.stroke();

            // Flash light
            ctx.fillStyle = '#facc15'; // Amber Yellow
            ctx.beginPath();
            ctx.arc(310, 215, 12, 0, Math.PI * 2);
            ctx.fill();

            // Draw high-fidelity typography
            ctx.fillStyle = '#ffffff';
            ctx.font = 'bold 24px "Outfit", sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText('GLIMPSE FLASH', 256, 380);

            ctx.font = '14px "Outfit", sans-serif';
            ctx.fillStyle = 'rgba(255, 255, 255, 0.8)';
            ctx.fillText('Simulated E2E Media Diagnostics', 256, 405);

            ctx.font = 'bold 10px monospace';
            ctx.fillStyle = 'rgba(255, 255, 255, 0.4)';
            ctx.fillText('TIMESTAMP: ' + new Date().toISOString(), 256, 440);

            // Save base64 string
            // Use JPEG at 55% quality — reduces payload from ~400KB to ~30KB for faster upload
            mockFlashImageBase64 = canvas.toDataURL('image/jpeg', 0.55);

            // Show preview
            document.getElementById('flashImagePreviewWrapper').classList.remove('hidden');
            document.getElementById('flashImagePreview').src = mockFlashImageBase64;
        }

        async function sendSimulatedFlash() {
            const userId = document.getElementById('flashSenderSelect').value;
            const battery = document.getElementById('flashBattery').value;
            const lat = document.getElementById('flashLat').value;
            const lon = document.getElementById('flashLon').value;
            const locName = document.getElementById('flashLocName').value;
            const status = document.getElementById('flashStatus').value;
            const fileInput = document.getElementById('flashFileInput');

            if (!userId) {
                alert("Please select a sender user.");
                return;
            }

            const outputBox = document.getElementById('diag-flash-output');
            const traceSpan = document.getElementById('diag-flash-trace');

            outputBox.classList.remove('hidden');
            traceSpan.innerHTML = '<span class="text-orange-400">Initializing upload simulation...</span>\n';

            // 1. Read file or fallback to generated mock image
            let base64Image = mockFlashImageBase64;

            if (fileInput.files.length > 0) {
                traceSpan.innerHTML += '<span class="text-white/50">Reading selected image file...</span>\n';
                const file = fileInput.files[0];
                base64Image = await new Promise((resolve) => {
                    const reader = new FileReader();
                    reader.onload = (e) => resolve(e.target.result);
                    reader.readAsDataURL(file);
                });
            }

            if (!base64Image) {
                traceSpan.innerHTML += '<span class="text-amber-400">⚠️ No image source provided. Automatically generating a mock gradient flash to test the API...</span>\n';
                generateMockFlashImage();
                base64Image = mockFlashImageBase64;
            }

            traceSpan.innerHTML += '<span class="text-white/50">Posting simulated payload to Glimpse API...</span>\n';

            const token = localStorage.getItem('glimpse_admin_token');
            try {
                const response = await fetch(`/admin/api?token=${encodeURIComponent(token)}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({
                        action: 'simulate_flash_post',
                        user_id: userId,
                        latitude: lat ? parseFloat(lat) : null,
                        longitude: lon ? parseFloat(lon) : null,
                        location_name: locName,
                        status_note: status,
                        battery_level: battery ? parseInt(battery) : null,
                        photo_base64: base64Image
                    })
                });

                // Parse response - may be JSON (our handler) or HTML (Laravel error page)
                let result = null;
                let rawText = '';
                try {
                    rawText = await response.text();
                    result = JSON.parse(rawText);
                } catch (parseErr) {
                    // Server returned HTML error page, not JSON
                    result = null;
                }

                if (response.ok && result && result.success) {
                    traceSpan.innerHTML += `<span class="text-emerald-400">⚡️ SUCCESS: Glimpse Flash record created and broadcasted!</span>\n\n`;
                    traceSpan.innerHTML += `<span class="text-orange-400">Database Record:</span>\n` + JSON.stringify(result.flash, null, 4) + `\n\n`;
                    traceSpan.innerHTML += `<span class="text-orange-400">Public Storage URL:</span>\n<a href="${result.public_storage_url}" target="_blank" class="text-activeCyan underline break-all">${result.public_storage_url}</a>\n\n`;
                    traceSpan.innerHTML += `<span class="text-orange-400">Physical Path on Disk:</span>\n<span class="text-white/60">${result.real_path_on_disk}</span>`;
                    
                    // Clear inputs
                    fileInput.value = '';
                    mockFlashImageBase64 = '';
                    document.getElementById('flashImagePreviewWrapper').classList.add('hidden');

                    // Force refresh main UI data to show updated statistics!
                    fetchData();
                } else {
                    const httpStatus = `HTTP ${response.status}`;
                    if (result && result.error) {
                        // Our PHP try-catch returned a structured error
                        traceSpan.innerHTML += `<span class="text-rose-400">❌ UPLOAD FAILED (${httpStatus}):</span>\n`;
                        traceSpan.innerHTML += `<span class="text-amber-400">Exception:</span> ${result.error}\n`;
                        traceSpan.innerHTML += `<span class="text-amber-400">Class:</span> ${result.exception_class || '?'}\n`;
                        traceSpan.innerHTML += `<span class="text-amber-400">File:</span> ${result.file || '?'}\n`;
                        if (result.trace) {
                            traceSpan.innerHTML += `<span class="text-amber-400">Stack:</span>\n` + result.trace.join('\n');
                        }
                    } else if (result && result.message) {
                        // Laravel's own error response (e.g. {"message": "Server Error"})
                        traceSpan.innerHTML += `<span class="text-rose-400">❌ SERVER ERROR (${httpStatus}):</span> ${result.message}\n\n`;
                        traceSpan.innerHTML += `<span class="text-white/40">💡 Tip: git pull belum dijalankan di server, atau ada PHP parse error.</span>\n`;
                        traceSpan.innerHTML += `<span class="text-white/40">Check laravel.log: </span><a href="/view-logs" target="_blank" class="text-activeCyan underline">/view-logs</a>`;
                    } else {
                        // HTML error page - show first 500 chars for clues
                        traceSpan.innerHTML += `<span class="text-rose-400">❌ NON-JSON ERROR (${httpStatus}):</span>\n`;
                        traceSpan.innerHTML += `<span class="text-white/60">${rawText.substring(0, 600).replace(/</g, '&lt;').replace(/>/g, '&gt;')}</span>`;
                    }
                }
            } catch (err) {
                console.error(err);
                traceSpan.innerHTML += `<span class="text-rose-400">❌ JS EXCEPTION:</span> ${err.message}`;
            }
        }

        async function diagnoseStorageSymlink() {
            const token = localStorage.getItem('glimpse_admin_token');
            const existsSpan = document.getElementById('symlinkStatusExists');
            const writeableSpan = document.getElementById('symlinkStatusWriteable');
            const fixerPanel = document.getElementById('symlinkFixerPanel');

            if (!existsSpan || !writeableSpan) return;

            try {
                const response = await fetch(`/admin/api?token=${encodeURIComponent(token)}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({ action: 'diagnose_symlink' })
                });

                if (response.ok) {
                    const result = await response.json();
                    
                    if (result.public_storage_exists) {
                        if (result.is_symlink) {
                            existsSpan.innerText = 'VALID SYMLINK';
                            existsSpan.className = 'font-bold text-emerald-400';
                            fixerPanel.classList.add('hidden');
                        } else {
                            existsSpan.innerText = 'DIR INSTEAD OF SYMLINK';
                            existsSpan.className = 'font-bold text-amber-400';
                            fixerPanel.classList.remove('hidden');
                        }
                    } else {
                        existsSpan.innerText = 'MISSING (404 RISK)';
                        existsSpan.className = 'font-bold text-rose-500';
                        fixerPanel.classList.remove('hidden');
                    }

                    if (result.storage_path_writeable) {
                        writeableSpan.innerText = 'WRITEABLE';
                        writeableSpan.className = 'font-bold text-emerald-400';
                    } else {
                        writeableSpan.innerText = 'READ-ONLY';
                        writeableSpan.className = 'font-bold text-rose-500';
                    }
                }
            } catch (err) {
                console.error("Symlink diagnostics failed:", err);
            }
        }

        async function fixStorageSymlink() {
            const token = localStorage.getItem('glimpse_admin_token');
            const fixerPanel = document.getElementById('symlinkFixerPanel');
            if (!confirm("Are you sure you want to run the Storage Symlink Doctor?\n\nThis will attempt to remove any existing/broken public/storage directory links and run 'php artisan storage:link' to restore image accessibility!")) {
                return;
            }

            try {
                const response = await fetch(`/admin/api?token=${encodeURIComponent(token)}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({ action: 'fix_symlink' })
                });

                const result = await response.json();

                if (response.ok && result.success) {
                    alert("Storage Symlink Doctor successfully restored your public storage links!\n\nOutput:\n" + result.output);
                    diagnoseStorageSymlink();
                } else {
                    alert("Symlink Fix failed: " + (result.error || 'Server error'));
                }
            } catch (err) {
                alert("Exception: " + err.message);
            }
        }

        function decodeSandbox(mode) {
            const input = document.getElementById('sandboxInput').value.trim();
            const output = document.getElementById('sandboxOutputWrapper');

            if (!input) {
                alert("Please enter base64 or hex characters to decode.");
                return;
            }

            output.classList.remove('hidden');
            output.innerText = "Decoding...";

            try {
                let base64 = '';
                if (mode === 'hex') {
                    // Convert hex characters (with or without spaces) to base64
                    const hexClean = input.replace(/[^0-9A-Fa-f]/g, '');
                    const bytes = new Uint8Array(hexClean.length / 2);
                    for (let i = 0; i < bytes.length; i++) {
                        bytes[i] = parseInt(hexClean.substr(i * 2, 2), 16);
                    }
                    let binStr = '';
                    for (let i = 0; i < bytes.length; i++) {
                        binStr += String.fromCharCode(bytes[i]);
                    }
                    base64 = btoa(binStr);
                } else {
                    base64 = input;
                }

                const decoded = decodeProtobufJS(base64);
                if (decoded && Object.keys(decoded).length > 0) {
                    output.innerText = "⚡️ SUCCESS: Pure Protobuf Decoded Fields:\n\n" + JSON.stringify(decoded, null, 4);
                } else {
                    output.innerText = "⚠️ WARNING: Decoded empty object. Ensure the payload matches the Glimpse v3 Protobuf field definitions.";
                }
            } catch (err) {
                output.innerText = "❌ ERROR: Failed to parse input. Ensure formatting is correct.\n\nDetails: " + err.message;
            }
        }

        // Trigger automatic rooms list fetch when user is populated
        setTimeout(() => {
            const select = document.getElementById('diagUserSelect');
            if (select) {
                updateDiagRooms();
            }
        }, 1500);
        
        function drawSplineLine(canvas, ctx, points, maxVal, strokeColor, fillColor) {
            ctx.beginPath();
            const sliceWidth = canvas.width / (points.length - 1);
            
            ctx.moveTo(0, canvas.height - (points[0] / maxVal) * (canvas.height - 15));
            for (let i = 1; i < points.length; i++) {
                const x = i * sliceWidth;
                const y = canvas.height - (points[i] / maxVal) * (canvas.height - 15);
                ctx.lineTo(x, y);
            }

            // Outline stroke
            ctx.strokeStyle = strokeColor;
            ctx.lineWidth = 2;
            ctx.stroke();

            // Fill area
            ctx.lineTo(canvas.width, canvas.height);
            ctx.lineTo(0, canvas.height);
            ctx.closePath();
            ctx.fillStyle = fillColor;
            ctx.fill();
        }
    </script>
</body>
</html>
