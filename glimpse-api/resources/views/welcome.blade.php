<!DOCTYPE html>
<html lang="en" class="h-full bg-slate-950">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Glimpse Admin Command Center</title>
    <!-- Google Fonts & Tailwind CDN -->
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&display=swap" rel="stylesheet">
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

    <!-- LOCK SCREEN (Token Verification Portal) -->
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
                <h1 class="text-3xl font-bold tracking-tight text-white mb-2">Glimpse Command Center</h1>
                <p class="text-white/60 text-sm">Enter secure Admin Access Token to verify identity.</p>
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

    <!-- MAIN APP SCREEN (Dashboard) -->
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
                        <h2 class="text-3xl font-extrabold text-white mb-2">Welcome Back, Admin! 👋</h2>
                        <p class="text-white/60 text-sm max-w-xl">Monitor your intimacy companion Glimpse API, couples connections, real-time battery status, reverse geocoded map coordinates, and WebSocket broadcasts.</p>
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
                        <div class="text-[10px] text-activeCyan mt-2 font-medium">Active intimacies</div>
                    </div>

                    <!-- Total Messages -->
                    <div class="p-5 rounded-2xl border border-white/10 bg-white/5 shadow-lg relative group overflow-hidden">
                        <div class="absolute -right-4 -bottom-4 w-20 h-20 rounded-full bg-royalPurple/5 blur-xl group-hover:scale-150 transition-all"></div>
                        <div class="text-white/50 text-xs font-semibold uppercase tracking-wider mb-2">Total Messages</div>
                        <div id="stat-messages" class="text-4xl font-extrabold text-white tracking-tight">-</div>
                        <div class="text-[10px] text-electricPurple mt-2 font-medium">Shared chat bubbles</div>
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
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <!-- Environment Info -->
                    <div class="p-6 rounded-2xl border border-white/10 bg-white/5 shadow-lg space-y-4">
                        <h3 class="text-lg font-bold flex items-center space-x-2">
                            <span class="w-1.5 h-6 rounded bg-electricPurple inline-block"></span>
                            <span>System & Environment Environment</span>
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
                                <span class="font-bold text-white">{{ DB::connection()->getDriverName() }}</span>
                            </div>
                            <div class="p-3 bg-white/5 rounded-xl border border-white/5">
                                <span class="block text-[10px] text-white/50 uppercase font-semibold">Server Host</span>
                                <span class="font-bold text-white">Octane (Swoole/Roadrunner)</span>
                            </div>
                        </div>
                    </div>

                    <!-- Developer Logs -->
                    <div class="p-6 rounded-2xl border border-white/10 bg-white/5 shadow-lg space-y-4 flex flex-col">
                        <h3 class="text-lg font-bold flex items-center space-x-2">
                            <span class="w-1.5 h-6 rounded bg-activeCyan inline-block"></span>
                            <span>Quick Developer Actions</span>
                        </h3>
                        <div class="flex-grow grid grid-cols-2 gap-4">
                            <button onclick="switchTab('control')" class="p-4 bg-electricPurple/10 hover:bg-electricPurple/20 border border-electricPurple/20 hover:border-electricPurple/30 rounded-xl text-left transition-all group">
                                <span class="block font-bold text-white group-hover:text-electricPurple transition-all">Pusher Emulator</span>
                                <span class="block text-xs text-white/50 mt-1">Force device triggers and location updates easily.</span>
                            </button>
                            <button onclick="switchTab('users')" class="p-4 bg-activeCyan/10 hover:bg-activeCyan/20 border border-activeCyan/20 hover:border-activeCyan/30 rounded-xl text-left transition-all group">
                                <span class="block font-bold text-white group-hover:text-activeCyan transition-all">Mock Battery Levels</span>
                                <span class="block text-xs text-white/50 mt-1">Edit custom battery levels to trigger low-battery warning alerts.</span>
                            </button>
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
                                <!-- Dynamic user list inserted here -->
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
                    <!-- Dynamic couples items inserted here -->
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
            </div>
        </main>
        
        <!-- Premium Footer -->
        <footer class="border-t border-white/10 py-6 text-center text-xs text-white/40">
            &copy; 2026 Glimpse Intimacy Companion &bull; Powered by Laravel Octane & SwiftUI
        </footer>
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
            if (savedToken) {
                document.getElementById('adminToken').value = savedToken;
                verifyAndLogin(savedToken);
            }
        });

        function handleLogin(event) {
            event.preventDefault();
            const token = document.getElementById('adminToken').value.trim();
            verifyAndLogin(token);
        }

        async function verifyAndLogin(token) {
            try {
                const response = await fetch('/admin/api', {
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

                    // Show panel with premium transition
                    lockScreen.classList.add('opacity-0', 'pointer-events-none');
                    mainDashboard.classList.remove('hidden');
                    setTimeout(() => {
                        mainDashboard.classList.remove('opacity-0');
                        mainDashboard.classList.add('opacity-100');
                    }, 50);
                } else {
                    showLoginError();
                }
            } catch (err) {
                console.error(err);
                showLoginError();
            }
        }

        function showLoginError() {
            const errorDiv = document.getElementById('loginError');
            errorDiv.classList.remove('hidden');
            localStorage.removeItem('glimpse_admin_token');
        }

        function handleLogout() {
            localStorage.removeItem('glimpse_admin_token');
            mainDashboard.classList.add('opacity-0');
            setTimeout(() => {
                mainDashboard.classList.add('hidden');
                lockScreen.classList.remove('opacity-0', 'pointer-events-none');
                document.getElementById('adminToken').value = '';
                document.getElementById('loginError').classList.add('hidden');
            }, 500);
        }

        async function fetchData() {
            const token = localStorage.getItem('glimpse_admin_token');
            try {
                const response = await fetch('/admin/api', {
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
                }
            } catch (err) {
                console.error('Failed to sync', err);
            }
        }

        function updateUI(data) {
            appData = data;
            
            // 1. Update stats
            document.getElementById('stat-users').innerText = data.stats.total_users;
            document.getElementById('stat-couples').innerText = data.stats.total_couples;
            document.getElementById('stat-messages').innerText = data.stats.total_messages;
            document.getElementById('stat-active').innerText = data.stats.active_sessions;

            // 2. Render users list
            renderUsersTable(data.users);

            // 3. Render couples list
            renderCouplesGrid(data.couples);

            // 4. Populate simulator & developer utilities select controls
            const simSelect = document.getElementById('simulatorUserSelect');
            const clearSelect = document.getElementById('clearChatCoupleSelect');
            
            simSelect.innerHTML = '';
            clearSelect.innerHTML = '';

            data.users.forEach(u => {
                const opt = document.createElement('option');
                opt.value = u.id;
                opt.innerText = `${u.name} (${u.email})`;
                simSelect.appendChild(opt);
            });

            data.couples.forEach(c => {
                const opt = document.createElement('option');
                opt.value = c.id;
                const names = c.users.map(u => u.name).join(' & ');
                opt.innerText = `Couple #${c.id}: ${names || 'Unpaired'}`;
                clearSelect.appendChild(opt);
            });
        }

        function renderUsersTable(users) {
            const body = document.getElementById('userTableBody');
            body.innerHTML = '';

            if (users.length === 0) {
                body.innerHTML = `<tr><td colspan="5" class="p-8 text-center text-white/40">No users found in database.</td></tr>`;
                return;
            }

            users.forEach(u => {
                const row = document.createElement('tr');
                row.className = 'border-b border-white/5 hover:bg-white/5 transition-all';
                
                const profileImg = u.profile_photo_url ? u.profile_photo_url : `https://ui-avatars.com/api/?name=${encodeURIComponent(u.name)}`;
                const locationDisplay = u.latitude ? `${u.location_name || 'Mock Location'} (${u.latitude}, ${u.longitude})` : '<span class="text-white/30">No coordinates set</span>';
                
                let batteryColor = 'text-emerald-400';
                if (u.battery_level <= 20) batteryColor = 'text-rose-400';
                else if (u.battery_level <= 50) batteryColor = 'text-amber-400';

                row.innerHTML = `
                    <td class="p-4 flex items-center space-x-3">
                        <img src="${profileImg}" class="w-10 h-10 rounded-xl object-cover border border-white/10" onerror="this.src='https://ui-avatars.com/api/?name=User'">
                        <div>
                            <span class="block font-bold text-white">${u.name}</span>
                            <span class="block text-xs text-white/50">${u.email}</span>
                        </div>
                    </td>
                    <td class="p-4 font-mono text-xs text-activeCyan font-bold uppercase">${u.invite_code}</td>
                    <td class="p-4 font-semibold ${batteryColor}">${u.battery_level}%</td>
                    <td class="p-4 text-xs text-white/70 max-w-xs truncate">${locationDisplay}</td>
                    <td class="p-4 text-right space-x-1">
                        <button onclick="openLocationModal(${u.id}, ${u.latitude || -6.200000}, ${u.longitude || 106.816666}, '${u.location_name || ''}')" class="px-2.5 py-1.5 rounded-lg bg-electricPurple/10 hover:bg-electricPurple/20 border border-electricPurple/20 text-electricPurple text-xs font-semibold transition-all">Location</button>
                        <button onclick="openBatteryModal(${u.id}, ${u.battery_level})" class="px-2.5 py-1.5 rounded-lg bg-activeCyan/10 hover:bg-activeCyan/20 border border-activeCyan/20 text-activeCyan text-xs font-semibold transition-all">Battery</button>
                        <button onclick="deleteUser(${u.id})" class="px-2.5 py-1.5 rounded-lg bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/20 text-rose-400 text-xs font-semibold transition-all">Delete</button>
                    </td>
                `;
                body.appendChild(row);
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
                        <div class="text-electricPurple font-bold text-xl px-4 animate-pulse">❤️</div>
                        <div class="text-center flex-1">
                            <span class="block text-[10px] text-white/40 uppercase">Partner B</span>
                            <span class="font-bold text-white text-sm">${p2}</span>
                        </div>
                    </div>

                    <div class="flex items-center justify-between text-xs text-white/50">
                        <span>Anniversary Date:</span>
                        <span class="font-semibold text-white font-mono">${c.anniversary_start_date || 'Not configured'}</span>
                    </div>
                `;
                container.appendChild(card);
            });
        }

        // TABS AND MODALS NAVIGATION
        function switchTab(tabId) {
            // Hide all contents
            document.querySelectorAll('.tab-content').forEach(c => c.classList.add('hidden'));
            
            // Deactivate all tab buttons
            document.querySelectorAll('.tab-btn').forEach(b => {
                b.classList.remove('bg-white/10', 'text-white');
                b.classList.add('text-white/60');
            });
            document.querySelectorAll('.tab-btn-mob').forEach(b => {
                b.classList.remove('bg-white/10', 'text-white');
                b.classList.add('text-white/60');
            });

            // Show active content
            document.getElementById(`content-${tabId}`).classList.remove('hidden');

            // Active button styling
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

        function openLocationModal(userId, lat, lon, name) {
            document.getElementById('locModalUserId').value = userId;
            document.getElementById('locModalLat').value = lat;
            document.getElementById('locModalLon').value = lon;
            document.getElementById('locModalName').value = name;
            
            document.getElementById('locationModal').classList.remove('hidden');
        }

        function openBatteryModal(userId, currentBattery) {
            document.getElementById('battModalUserId').value = userId;
            document.getElementById('battModalSlider').value = currentBattery;
            document.getElementById('battModalVal').innerText = currentBattery + '%';
            
            document.getElementById('batteryModal').classList.remove('hidden');
        }

        function closeModal(modalId) {
            document.getElementById(modalId).classList.add('hidden');
        }

        // ADMIN API ACTIONS SUBMISSIONS
        async function submitLocationUpdate() {
            const token = localStorage.getItem('glimpse_admin_token');
            const userId = document.getElementById('locModalUserId').value;
            const lat = document.getElementById('locModalLat').value;
            const lon = document.getElementById('locModalLon').value;
            const name = document.getElementById('locModalName').value;

            try {
                const response = await fetch('/admin/api', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({
                        action: 'update_location',
                        user_id: userId,
                        latitude: lat,
                        longitude: lon,
                        location_name: name
                    })
                });

                if (response.ok) {
                    closeModal('locationModal');
                    fetchData();
                }
            } catch (err) {
                console.error(err);
            }
        }

        async function submitBatteryUpdate() {
            const token = localStorage.getItem('glimpse_admin_token');
            const userId = document.getElementById('battModalUserId').value;
            const battery = document.getElementById('battModalSlider').value;

            try {
                const response = await fetch('/admin/api', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({
                        action: 'update_battery',
                        user_id: userId,
                        battery_level: battery
                    })
                });

                if (response.ok) {
                    closeModal('batteryModal');
                    fetchData();
                }
            } catch (err) {
                console.error(err);
            }
        }

        async function deleteUser(userId) {
            if (!confirm('Are you sure you want to permanently delete this user?')) return;
            const token = localStorage.getItem('glimpse_admin_token');
            try {
                const response = await fetch('/admin/api', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({
                        action: 'delete_user',
                        user_id: userId
                    })
                });
                if (response.ok) {
                    fetchData();
                }
            } catch (err) {
                console.error(err);
            }
        }

        async function clearChat() {
            const coupleId = document.getElementById('clearChatCoupleSelect').value;
            if (!confirm('Are you sure you want to clear this couple conversation history permanently?')) return;
            
            const token = localStorage.getItem('glimpse_admin_token');
            try {
                const response = await fetch('/admin/api', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({
                        action: 'clear_chat',
                        couple_id: coupleId
                    })
                });
                if (response.ok) {
                    alert('Couple conversation history cleared successfully!');
                    fetchData();
                }
            } catch (err) {
                console.error(err);
            }
        }

        async function triggerSimulatedUpdate(type) {
            const token = localStorage.getItem('glimpse_admin_token');
            const userId = document.getElementById('simulatorUserSelect').value;

            if (type === 'battery_low') {
                // Set battery level to 12%
                try {
                    await fetch('/admin/api', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-Admin-Token': token
                        },
                        body: JSON.stringify({
                            action: 'update_battery',
                            user_id: userId,
                            battery_level: 12
                        })
                    });
                    alert('Broadcasted simulated battery low alert!');
                    fetchData();
                } catch (err) { console.error(err); }
            } else if (type === 'is_charging') {
                alert('Broadcasted simulated device charging alert!');
            } else if (type === 'online') {
                alert('Broadcasted simulated location active update pulsing!');
            }
        }
    </script>
</body>
</html>
