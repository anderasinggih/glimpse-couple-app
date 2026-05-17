<!DOCTYPE html>
<html lang="en" class="h-full bg-slate-950">
<head>
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

    <!-- ================= LOCK SCREEN (Token Verification Portal) ================= -->
    <div id="lockScreen" class="fixed inset-0 z-50 flex items-center justify-center bg-deepVelvet/95 backdrop-blur-md transition-all duration-500">
        <div class="w-full max-w-md p-8 mx-4 rounded-3xl border border-white/10 bg-white/5 backdrop-blur-xl shadow-2xl relative overflow-hidden">
            <!-- Glass Header Accent -->
            <div class="absolute top-0 left-0 right-0 h-[3px] bg-gradient-to-r from-electricPurple via-activeCyan to-royalPurple"></div>
            
            <div class="text-center mb-8">
                <!-- Glowing Pulsing Heart Logo -->
                <div class="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-tr from-electricPurple/20 to-royalPurple/20 border border-electricPurple/30 shadow-[0_0_20px_rgba(191,128,255,0.2)] mb-4 animate-pulse">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" class="w-8 h-8 text-electricPurple" viewBox="0 0 24 24">
                        <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
                    </svg>
                </div>
                <h1 class="text-3xl font-bold tracking-tight text-white mb-2">Admin Command Center</h1>
                <p class="text-white/60 text-sm">Enter secure Admin Access Token to verify identity.</p>
                <div class="mt-2 text-xs text-white/40">Default Token: <span class="font-mono text-electricPurple font-semibold bg-white/5 px-2 py-0.5 rounded">GLIMPSE-ADMIN-TOKEN-2026</span></div>
            </div>

            <form id="loginForm" onsubmit="handleLogin(event)">
                <div class="space-y-4">
                    <div>
                        <label for="adminToken" class="block text-xs font-semibold uppercase tracking-wider text-white/50 mb-2">Security Token</label>
                        <input type="password" id="adminToken" placeholder="••••••••••••••••••••••••" 
                            class="w-full px-4 py-3 rounded-xl border border-white/10 bg-white/5 text-white placeholder-white/20 focus:outline-none focus:ring-2 focus:ring-electricPurple/50 focus:border-electricPurple transition-all"
                            required>
                    </div>
                    
                    <div id="loginError" class="hidden text-rose-400 text-xs font-medium bg-rose-500/10 border border-rose-500/20 py-2 px-3 rounded-lg text-center">
                        Invalid admin token. Please try again.
                    </div>

                    <button type="submit" class="w-full py-3 rounded-xl bg-gradient-to-r from-electricPurple to-royalPurple text-white font-semibold hover:shadow-[0_0_20px_rgba(191,128,255,0.4)] transition-all flex items-center justify-center space-x-2">
                        <span>Authenticate</span>
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                        </svg>
                    </button>
                </div>
            </form>

            <div class="text-center mt-6 text-[10px] text-white/30">
                Authorized developer dashboard access only. System activity is logged.
            </div>
        </div>
    </div>

    <!-- ================= MAIN APP SCREEN (Dashboard) ================= -->
    <div id="mainDashboard" class="hidden min-h-screen flex flex-col relative z-10 transition-all duration-700 opacity-0">
        
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

        const lockScreen = document.getElementById('lockScreen');
        const mainDashboard = document.getElementById('mainDashboard');

        // Check if already authenticated on load
        window.addEventListener('DOMContentLoaded', () => {
            const savedToken = localStorage.getItem('glimpse_admin_token');
            if (savedToken && savedToken !== 'undefined' && savedToken !== 'null' && savedToken.trim() !== '') {
                document.getElementById('adminToken').value = savedToken.trim();
                verifyAndLogin(savedToken.trim(), true); // Silent auto-login
            } else {
                localStorage.removeItem('glimpse_admin_token');
            }
        });

        function handleLogin(event) {
            event.preventDefault();
            const token = document.getElementById('adminToken').value.trim();
            verifyAndLogin(token, false);
        }

        async function verifyAndLogin(token, isAuto = false) {
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
                    localStorage.setItem('glimpse_admin_token', token);
                    
                    // Populate data
                    updateUI(data);

                    // Close lock screen
                    lockScreen.classList.add('opacity-0');
                    setTimeout(() => {
                        lockScreen.classList.add('hidden');
                    }, 500);

                    // Show dashboard
                    mainDashboard.classList.remove('hidden');
                    setTimeout(() => {
                        mainDashboard.classList.remove('opacity-0');
                        mainDashboard.classList.add('opacity-100');
                    }, 50);
                    
                    // Start monitors
                    startWebSocketDiagnostics();
                    startBandwidthMonitor();
                } else {
                    let errMsg = `Server status ${response.status}: Unauthorized`;
                    try {
                        const errData = await response.json();
                        if (errData && errData.error) {
                            errMsg = errData.error;
                        }
                    } catch(e) {}
                    if (!isAuto) showLoginError(errMsg);
                }
            } catch (err) {
                console.error(err);
                if (!isAuto) showLoginError(`Network Error: ${err.message}`);
            }
        }

        function showLoginError(message) {
            const errorDiv = document.getElementById('loginError');
            errorDiv.innerText = message || 'Invalid Admin Token.';
            errorDiv.classList.remove('hidden');
            localStorage.removeItem('glimpse_admin_token');
        }

        function handleLogout() {
            localStorage.removeItem('glimpse_admin_token');
            if (liveWS) {
                try { liveWS.close(); } catch(e) {}
                liveWS = null;
            }
            clearInterval(wsPingInterval);
            mainDashboard.classList.add('opacity-0');
            setTimeout(() => {
                window.location.reload();
            }, 500);
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
        }

        function populateSelects(data) {
            const selects = [
                'simulatorUserSelect', 
                'clearChatCoupleSelect', 
                'dewaPruneUserSelect', 
                'dewaLinkUser1Select', 
                'dewaLinkUser2Select'
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

            adminApiCall('mock_location', { user_id: userId, latitude: lat, longitude: lon, location_name: name });
            closeModal('locationModal');
        }

        function submitBatteryUpdate() {
            const userId = document.getElementById('battModalUserId').value;
            const val = document.getElementById('battModalSlider').value;

            adminApiCall('mock_battery', { user_id: userId, battery_level: val });
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

        function startWebSocketDiagnostics() {
            if (liveWS) return;

            const isHttps = window.location.protocol === 'https:';
            const wsProtocol = isHttps ? 'wss:' : 'ws:';
            
            // Laravel Reverb WebSockets endpoint mapping (port 8080)
            const wsUrl = `${wsProtocol}//${window.location.hostname}:8080/app/glimpseappkey?protocol=7&client=js&version=8.4.0&flash=true`;
            
            try {
                liveWS = new WebSocket(wsUrl);
                
                liveWS.onopen = () => {
                    document.getElementById('ws-diag-indicator').className = "w-2.5 h-2.5 rounded-full bg-emerald-500";
                    document.getElementById('ws-diag-status').innerText = "Live Connected";
                    document.getElementById('ws-diag-status').className = "text-xs font-bold text-emerald-400";
                    
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
