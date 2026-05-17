<!DOCTYPE html>
<html lang="en" class="h-full bg-slate-950">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Glimpse — Intimacy, Closer Than Ever</title>
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

    <!-- ================= LANDING PAGE & DOCUMENTATION PORTAL ================= -->
    <div id="landingPortal" class="relative z-10 min-h-screen flex flex-col transition-all duration-700">
        
        <!-- Navigation Header -->
        <header class="border-b border-white/10 bg-deepVelvet/60 backdrop-blur-md sticky top-0 z-30">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between">
                <div class="flex items-center space-x-3">
                    <!-- Glimpse Liquid Glass Heart Icon -->
                    <div class="w-10 h-10 rounded-xl bg-gradient-to-tr from-electricPurple/20 to-royalPurple/20 border border-electricPurple/30 flex items-center justify-center shadow-lg relative group">
                        <span class="absolute inset-0 rounded-xl border border-white/20 opacity-0 group-hover:opacity-100 transition-all duration-300"></span>
                        <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" class="w-5 h-5 text-electricPurple" viewBox="0 0 24 24">
                            <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
                        </svg>
                    </div>
                    <div>
                        <h1 class="font-extrabold text-lg leading-tight tracking-tight">Glimpse</h1>
                        <span class="text-[9px] uppercase font-bold tracking-widest text-electricPurple">Intimate Companion</span>
                    </div>
                </div>

                <!-- Navigation Links -->
                <nav class="hidden md:flex space-x-8">
                    <a href="#features" class="text-sm font-medium text-white/70 hover:text-white transition-all">Features</a>
                    <a href="#docs" class="text-sm font-medium text-white/70 hover:text-white transition-all">API Docs</a>
                    <a href="#architecture" class="text-sm font-medium text-white/70 hover:text-white transition-all">Architecture</a>
                </nav>

                <div class="flex items-center space-x-4">
                    <button onclick="openLockScreen()" class="px-5 py-2 rounded-xl bg-gradient-to-r from-electricPurple to-royalPurple text-white font-semibold text-sm hover:shadow-[0_0_20px_rgba(191,128,255,0.4)] transition-all flex items-center space-x-2">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 17.25v1.007a3 3 0 01-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0115 18.257V17.25m6-12V15a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 15V5.25m18 0A2.25 2.25 0 0018.75 3H5.25A2.25 2.25 0 003 5.25m18 0V12a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 12V5.25" />
                        </svg>
                        <span>Admin Console</span>
                    </button>
                </div>
            </div>
        </header>

        <!-- HERO SECTION -->
        <section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-16 pb-20 relative overflow-hidden flex-grow flex flex-col justify-center">
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
                <!-- Left Content -->
                <div class="lg:col-span-7 space-y-6 text-left relative z-10">
                    <div class="inline-flex items-center space-x-2 px-3.5 py-1.5 rounded-full bg-electricPurple/10 border border-electricPurple/20 text-electricPurple text-xs font-semibold uppercase tracking-wider">
                        <span>✨ iOS 26 Liquid Glass Design System</span>
                    </div>
                    
                    <h2 class="text-4xl sm:text-6xl font-extrabold text-white tracking-tight leading-[1.1] mb-4">
                        Intimacy, Closer Than <span class="bg-gradient-to-r from-electricPurple to-activeCyan bg-clip-text text-transparent">Ever Before</span>.
                    </h2>
                    
                    <p class="text-white/60 text-lg sm:text-xl font-light max-w-2xl leading-relaxed">
                        Glimpse is a zero-latency, private companion app designed for couples. Track your partner's live location on hybrid maps, monitor battery levels dynamically, and send instant, self-destructing flash attachments.
                    </p>

                    <div class="flex flex-wrap gap-4 pt-4">
                        <a href="#docs" class="px-6 py-3.5 rounded-xl border border-white/10 hover:border-white/20 bg-white/5 hover:bg-white/10 text-white font-bold transition-all text-sm flex items-center space-x-2">
                            <span>Explore API Documentation</span>
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
                            </svg>
                        </a>
                        <button onclick="openLockScreen()" class="px-6 py-3.5 rounded-xl bg-gradient-to-r from-electricPurple to-royalPurple text-white font-bold hover:shadow-[0_0_25px_rgba(191,128,255,0.4)] transition-all text-sm flex items-center space-x-2">
                            <span>Launch Admin Dashboard</span>
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                            </svg>
                        </button>
                    </div>
                </div>

                <!-- Right Visual Mockup (Interactive liquid glass layout representation) -->
                <div class="lg:col-span-5 relative flex justify-center">
                    <div class="w-80 h-[500px] rounded-[48px] border-4 border-white/20 bg-slate-900 shadow-2xl relative p-4 flex flex-col justify-between overflow-hidden">
                        <!-- Camera notch -->
                        <div class="absolute top-2 left-1/2 -translate-x-1/2 w-32 h-6 bg-black rounded-full z-20"></div>
                        
                        <!-- Internal Screen Content (Widget Mockup) -->
                        <div class="flex-grow flex flex-col justify-between pt-8 pb-4 relative z-10 space-y-4">
                            <!-- Header widget -->
                            <div class="p-4 rounded-3xl bg-white/5 border border-white/10 backdrop-blur-xl">
                                <div class="flex justify-between items-center">
                                    <div class="flex items-center space-x-2">
                                        <div class="w-8 h-8 rounded-full bg-gradient-to-tr from-electricPurple to-royalPurple flex items-center justify-center font-bold text-xs">P</div>
                                        <div>
                                            <span class="block text-xs font-bold">Partner</span>
                                            <span class="block text-[8px] text-white/50">Online</span>
                                        </div>
                                    </div>
                                    <span class="text-xs text-activeCyan font-bold">🔋 84%</span>
                                </div>
                            </div>

                            <!-- Magic Card Widget (1:1 Ratio Mockup) -->
                            <div class="aspect-square w-full rounded-[32px] bg-white/5 border border-white/10 backdrop-blur-2xl relative overflow-hidden flex flex-col justify-between p-4 group">
                                <div class="absolute inset-0 bg-gradient-to-b from-transparent to-black/80"></div>
                                <div class="flex justify-between items-center z-10">
                                    <span class="px-2 py-0.5 rounded bg-electricPurple/20 border border-electricPurple/30 text-[9px] font-bold text-electricPurple">Hybrid Mode</span>
                                    <span class="text-[9px] text-white/50">Updated 2s ago</span>
                                </div>
                                
                                <!-- Pulse Dot -->
                                <div class="absolute inset-0 flex items-center justify-center pointer-events-none">
                                    <div class="w-6 h-6 rounded-full bg-activeCyan/20 flex items-center justify-center relative">
                                        <span class="absolute w-12 h-12 rounded-full bg-activeCyan/10 animate-ping"></span>
                                        <div class="w-3.5 h-3.5 rounded-full bg-activeCyan border-2 border-white shadow"></div>
                                    </div>
                                </div>

                                <div class="z-10 text-left">
                                    <span class="block text-[9px] text-white/50 uppercase tracking-wider font-semibold">Current Location</span>
                                    <span class="block font-bold text-xs text-white">Grand Indonesia Mall, Jakarta</span>
                                </div>
                            </div>

                            <!-- Typebar input mockup -->
                            <div class="p-3 rounded-2xl bg-white/5 border border-white/10 backdrop-blur-xl flex justify-between items-center">
                                <span class="text-xs text-white/30">Love you so much...</span>
                                <div class="w-6 h-6 rounded-full bg-electricPurple flex items-center justify-center">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-3.5 h-3.5">
                                        <path d="M3.105 2.289a.75.75 0 00-.826.95l1.414 4.925A1.5 1.5 0 005.135 9.25h5.115a.75.75 0 010 1.5H5.135a1.5 1.5 0 00-1.442 1.086l-1.414 4.926a.75.75 0 00.826.95 28.896 28.896 0 0015.293-7.154.75.75 0 000-1.115A28.897 28.897 0 003.105 2.289z" />
                                    </svg>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Internal glowing orbs inside mockup -->
                        <div class="absolute top-[20%] right-[-10%] w-32 h-32 rounded-full bg-electricPurple/20 blur-2xl z-0"></div>
                        <div class="absolute bottom-[20%] left-[-10%] w-32 h-32 rounded-full bg-activeCyan/20 blur-2xl z-0"></div>
                    </div>
                </div>
            </div>
        </section>

        <!-- ================= FEATURES SECTION ================= -->
        <section id="features" class="border-t border-white/10 bg-slate-950/20 py-20 relative overflow-hidden">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
                <div class="text-center max-w-3xl mx-auto mb-16 space-y-4">
                    <div class="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-electricPurple/10 border border-electricPurple/20 text-electricPurple text-[10px] font-bold uppercase tracking-wider">
                        <span>Core Ecosystem</span>
                    </div>
                    <h3 class="text-3xl sm:text-4xl font-extrabold tracking-tight">Premium Companion Features</h3>
                    <p class="text-white/60 text-sm">Glimpse fuses native iOS hardware capabilities with state-of-the-art backend responsiveness to build the ultimate intimate couple environment.</p>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                    <!-- Feature 1 -->
                    <div class="p-6 rounded-2xl border border-white/10 bg-white/5 backdrop-blur-xl relative overflow-hidden group hover:border-electricPurple/40 transition-all duration-300">
                        <div class="w-12 h-12 rounded-xl bg-electricPurple/10 border border-electricPurple/20 flex items-center justify-center text-electricPurple mb-6">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z" />
                            </svg>
                        </div>
                        <h4 class="text-lg font-bold text-white mb-2">Liquid Glass Lovelace</h4>
                        <p class="text-white/50 text-xs leading-relaxed">Stunning 3D volumetric heart icons outlined with premium glowing glass light-reflections supporting automatic dark/light adaptive tinting.</p>
                    </div>

                    <!-- Feature 2 -->
                    <div class="p-6 rounded-2xl border border-white/10 bg-white/5 backdrop-blur-xl relative overflow-hidden group hover:border-activeCyan/40 transition-all duration-300">
                        <div class="w-12 h-12 rounded-xl bg-activeCyan/10 border border-activeCyan/20 flex items-center justify-center text-activeCyan mb-6">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
                                <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
                            </svg>
                        </div>
                        <h4 class="text-lg font-bold text-white mb-2">Interactive GPS Pulse</h4>
                        <p class="text-white/50 text-xs leading-relaxed">MapKit integration displaying real-time coordinate synchronization, pulsing indicators, and reverse geocoding to name locations without servers.</p>
                    </div>

                    <!-- Feature 3 -->
                    <div class="p-6 rounded-2xl border border-white/10 bg-white/5 backdrop-blur-xl relative overflow-hidden group hover:border-royalPurple/40 transition-all duration-300">
                        <div class="w-12 h-12 rounded-xl bg-royalPurple/10 border border-royalPurple/20 flex items-center justify-center text-royalPurple mb-6">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99" />
                            </svg>
                        </div>
                        <h4 class="text-lg font-bold text-white mb-2">Magic Flip Card</h4>
                        <p class="text-white/50 text-xs leading-relaxed">Automatic 10-second fade transition alternating between your partner's live map view and their beautiful, premium portrait photo.</p>
                    </div>

                    <!-- Feature 4 -->
                    <div class="p-6 rounded-2xl border border-white/10 bg-white/5 backdrop-blur-xl relative overflow-hidden group hover:border-electricPurple/40 transition-all duration-300">
                        <div class="w-12 h-12 rounded-xl bg-electricPurple/10 border border-electricPurple/20 flex items-center justify-center text-electricPurple mb-6">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M6.827 6.175A2.31 2.31 0 015.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 00-1.134-.175 2.31 2.31 0 01-1.64-1.055l-.822-1.316a2.192 2.192 0 00-1.736-1.039 48.774 48.774 0 00-5.232 0 2.192 2.192 0 00-1.736 1.039l-.821 1.316z" />
                                <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 12.75a4.5 4.5 0 11-9 0 4.5 4.5 0 019 0zM18.75 10.5h.008v.008h-.008V10.5z" />
                            </svg>
                        </div>
                        <h4 class="text-lg font-bold text-white mb-2">Self-Destructing Flash</h4>
                        <p class="text-white/50 text-xs leading-relaxed">Seamless camera snapshots sent instantly to chat as attachments that automatically redirect to the map view upon clicking.</p>
                    </div>
                </div>
            </div>
        </section>

        <!-- API DOCUMENTATION SECTION -->
        <section id="docs" class="border-t border-white/10 bg-slate-950/40 backdrop-blur-xl py-20">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div class="text-center max-w-3xl mx-auto mb-16 space-y-4">
                    <h3 class="text-3xl sm:text-4xl font-extrabold tracking-tight">API Documentation</h3>
                    <p class="text-white/60 text-sm">Review Glimpse's highly structured REST endpoints to integrate companion services, handle authentication flow, send messages, and synchronize live map states.</p>
                </div>

                <!-- Interactive Docs Layout -->
                <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
                    <!-- Left Docs Nav sidebar -->
                    <div class="lg:col-span-4 space-y-2 lg:sticky lg:top-24">
                        <button onclick="switchDocTab('auth')" id="doc-tab-auth" class="w-full text-left p-4 rounded-xl border border-electricPurple/20 bg-electricPurple/10 text-white font-semibold transition-all">
                            <span class="block text-sm">1. Authentication Flow</span>
                            <span class="block text-xs text-white/50 font-normal mt-0.5">Register, Login, & Invite pair setup</span>
                        </button>
                        <button onclick="switchDocTab('state')" id="doc-tab-state" class="w-full text-left p-4 rounded-xl border border-white/5 bg-white/5 text-white/70 hover:text-white transition-all">
                            <span class="block text-sm">2. Companion State Sync</span>
                            <span class="block text-xs text-white/50 font-normal mt-0.5">Retrieve active state & profile update</span>
                        </button>
                        <button onclick="switchDocTab('location')" id="doc-tab-location" class="w-full text-left p-4 rounded-xl border border-white/5 bg-white/5 text-white/70 hover:text-white transition-all">
                            <span class="block text-sm">3. Map & Battery Pushes</span>
                            <span class="block text-xs text-white/50 font-normal mt-0.5">Push location name & battery triggers</span>
                        </button>
                        <button onclick="switchDocTab('chat')" id="doc-tab-chat" class="w-full text-left p-4 rounded-xl border border-white/5 bg-white/5 text-white/70 hover:text-white transition-all">
                            <span class="block text-sm">4. Intimate Chats & Flash</span>
                            <span class="block text-xs text-white/50 font-normal mt-0.5">Real-time chats & self-destruct cards</span>
                        </button>
                    </div>

                    <!-- Right Docs Content Code blocks -->
                    <div class="lg:col-span-8 p-6 rounded-2xl border border-white/10 bg-white/5 backdrop-blur-xl space-y-6">
                        
                        <!-- AUTH DOCS -->
                        <div id="doc-content-auth" class="doc-content space-y-4">
                            <h4 class="text-xl font-bold text-white flex items-center space-x-2">
                                <span class="px-2 py-0.5 rounded bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-bold font-mono">POST</span>
                                <span>/api/register</span>
                            </h4>
                            <p class="text-sm text-white/60">Creates a new companion account and returns an access token along with a unique couple invite code.</p>
                            
                            <div class="rounded-xl overflow-hidden bg-slate-900 border border-white/10 p-4 font-mono text-xs text-left">
                                <span class="block text-[10px] text-white/40 uppercase font-bold tracking-wider mb-2">Request Body</span>
                                <pre class="text-electricPurple font-medium">{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "password": "secure_password"
}</pre>
                            </div>
                            
                            <div class="rounded-xl overflow-hidden bg-slate-900 border border-white/10 p-4 font-mono text-xs text-left">
                                <span class="block text-[10px] text-white/40 uppercase font-bold tracking-wider mb-2">JSON Response (200 OK)</span>
                                <pre class="text-activeCyan font-medium">{
  "token": "1|sanctum_access_token_hash",
  "user": {
    "id": 2,
    "name": "Jane Doe",
    "email": "jane@example.com",
    "invite_code": "4D8F3E9C"
  }
}</pre>
                            </div>
                        </div>

                        <!-- STATE DOCS -->
                        <div id="doc-content-state" class="doc-content space-y-4 hidden">
                            <h4 class="text-xl font-bold text-white flex items-center space-x-2">
                                <span class="px-2 py-0.5 rounded bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 text-xs font-bold font-mono">GET</span>
                                <span>/api/state</span>
                            </h4>
                            <p class="text-sm text-white/60">Retrieves the complete real-time dashboard state, including your profile information, partner details, active couple connection info, and anniversary details.</p>
                            
                            <div class="rounded-xl overflow-hidden bg-slate-900 border border-white/10 p-4 font-mono text-xs text-left">
                                <span class="block text-[10px] text-white/40 uppercase font-bold tracking-wider mb-2">JSON Response (200 OK)</span>
                                <pre class="text-activeCyan font-medium">{
  "user": {
    "id": 1,
    "name": "Alex",
    "battery_level": 94,
    "location_name": "Grand Indonesia"
  },
  "partner_data": {
    "id": 2,
    "name": "Jane",
    "battery_level": 72,
    "location_name": "Monas, Jakarta"
  },
  "couple_active": true,
  "anniversary_start_date": "2024-05-17"
}</pre>
                            </div>
                        </div>

                        <!-- LOCATION DOCS -->
                        <div id="doc-content-location" class="doc-content space-y-4 hidden">
                            <h4 class="text-xl font-bold text-white flex items-center space-x-2">
                                <span class="px-2 py-0.5 rounded bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-bold font-mono">POST</span>
                                <span>/api/location</span>
                            </h4>
                            <p class="text-sm text-white/60">Pushes your current GPS coordinates, reverse geocoded landmark name, and battery metrics. Connected partner devices will immediately update.</p>
                            
                            <div class="rounded-xl overflow-hidden bg-slate-900 border border-white/10 p-4 font-mono text-xs text-left">
                                <span class="block text-[10px] text-white/40 uppercase font-bold tracking-wider mb-2">Request Body</span>
                                <pre class="text-electricPurple font-medium">{
  "latitude": -6.200000,
  "longitude": 106.816666,
  "location_name": "Grand Indonesia Mall, Jakarta",
  "battery_level": 84,
  "is_charging": false
}</pre>
                            </div>
                        </div>

                        <!-- CHAT DOCS -->
                        <div id="doc-content-chat" class="doc-content space-y-4 hidden">
                            <h4 class="text-xl font-bold text-white flex items-center space-x-2">
                                <span class="px-2 py-0.5 rounded bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-bold font-mono">POST</span>
                                <span>/api/messages</span>
                            </h4>
                            <p class="text-sm text-white/60">Sends an intimate chat bubble or a private flash card attachment that instantly routes to the companion device.</p>
                            
                            <div class="rounded-xl overflow-hidden bg-slate-900 border border-white/10 p-4 font-mono text-xs text-left">
                                <span class="block text-[10px] text-white/40 uppercase font-bold tracking-wider mb-2">Request Body</span>
                                <pre class="text-electricPurple font-medium">{
  "message": "See you in 10 minutes! ❤️",
  "is_flash": false
}</pre>
                            </div>
                        </div>

                    </div>
                </div>
            </div>
        </section>

        <!-- ================= ARCHITECTURE SECTION ================= -->
        <section id="architecture" class="border-t border-white/10 bg-slate-950/60 py-20 relative overflow-hidden">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
                <div class="text-center max-w-3xl mx-auto mb-16 space-y-4">
                    <div class="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-activeCyan/10 border border-activeCyan/20 text-activeCyan text-[10px] font-bold uppercase tracking-wider">
                        <span>Data Flow Model</span>
                    </div>
                    <h3 class="text-3xl sm:text-4xl font-extrabold tracking-tight">System Architecture</h3>
                    <p class="text-white/60 text-sm">Glimpse achieves sub-second reactive updates using high-performance HTTP request channels and scalable Pusher/Reverb WebSockets.</p>
                </div>

                <!-- Visual Architecture Diagram Card -->
                <div class="p-8 rounded-3xl border border-white/10 bg-white/5 backdrop-blur-xl">
                    <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
                        
                        <!-- Left explanation -->
                        <div class="lg:col-span-4 space-y-4">
                            <h4 class="text-xl font-bold text-white">How it Works</h4>
                            <p class="text-white/50 text-xs leading-relaxed">
                                When a user updates their battery level, notes, or coordinates, the Glimpse iOS app sends an authenticated POST request to our Laravel backend.
                            </p>
                            <p class="text-white/50 text-xs leading-relaxed">
                                The Laravel engine processes the update, saves the status in the SQLite database, and immediately fires a custom broadcast event.
                            </p>
                            <p class="text-white/50 text-xs leading-relaxed">
                                The Pusher WebSocket server picks up this event and broadcasts a live socket push to the connected partner's iOS device. This complete flow finishes in **less than 100 milliseconds**!
                            </p>
                        </div>

                        <!-- Right Flow Diagram -->
                        <div class="lg:col-span-8 space-y-6">
                            <div class="flex flex-col sm:flex-row items-center justify-between gap-6 relative">
                                
                                <!-- Node 1 -->
                                <div class="w-full sm:w-1/3 p-4 rounded-xl border border-electricPurple/20 bg-electricPurple/10 text-center relative group">
                                    <div class="absolute inset-x-0 -top-3 flex justify-center">
                                        <span class="px-2 py-0.5 rounded bg-electricPurple text-[9px] font-extrabold uppercase tracking-wider text-deepVelvet">Client</span>
                                    </div>
                                    <span class="block font-bold text-white text-xs mt-1">iOS Swift App</span>
                                    <span class="block text-[10px] text-white/50 mt-1">SwiftUI & MapKit</span>
                                </div>

                                <!-- Arrow 1 -->
                                <div class="hidden sm:flex flex-col items-center flex-grow">
                                    <span class="text-[10px] text-white/30 font-mono mb-1">POST</span>
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6 text-electricPurple">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                                    </svg>
                                </div>

                                <!-- Node 2 -->
                                <div class="w-full sm:w-1/3 p-4 rounded-xl border border-royalPurple/20 bg-royalPurple/10 text-center relative group">
                                    <div class="absolute inset-x-0 -top-3 flex justify-center">
                                        <span class="px-2 py-0.5 rounded bg-royalPurple text-[9px] font-extrabold uppercase tracking-wider text-white">Engine</span>
                                    </div>
                                    <span class="block font-bold text-white text-xs mt-1">Laravel Octane</span>
                                    <span class="block text-[10px] text-white/50 mt-1">SQLite & Broadcasts</span>
                                </div>

                                <!-- Arrow 2 -->
                                <div class="hidden sm:flex flex-col items-center flex-grow">
                                    <span class="text-[10px] text-white/30 font-mono mb-1">WebSockets</span>
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6 text-activeCyan">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                                    </svg>
                                </div>

                                <!-- Node 3 -->
                                <div class="w-full sm:w-1/3 p-4 rounded-xl border border-activeCyan/20 bg-activeCyan/10 text-center relative group">
                                    <div class="absolute inset-x-0 -top-3 flex justify-center">
                                        <span class="px-2 py-0.5 rounded bg-activeCyan text-[9px] font-extrabold uppercase tracking-wider text-deepVelvet">Partner</span>
                                    </div>
                                    <span class="block font-bold text-white text-xs mt-1">Live Update</span>
                                    <span class="block text-[10px] text-white/50 mt-1">Pusher Live Sync</span>
                                </div>

                            </div>
                        </div>

                    </div>
                </div>
            </div>
        </section>

        <!-- Premium Footer -->
        <footer class="border-t border-white/10 py-8 text-center text-xs text-white/40 mt-auto">
            &copy; 2026 Glimpse Intimacy Companion &bull; Powered by Laravel Octane & SwiftUI
        </footer>
    </div>

    <!-- ================= LOCK SCREEN (Token Verification Portal) ================= -->
    <div id="lockScreen" class="fixed inset-0 z-50 flex items-center justify-center bg-deepVelvet/95 backdrop-blur-md transition-all duration-500 hidden">
        <div class="w-full max-w-md p-8 mx-4 rounded-3xl border border-white/10 bg-white/5 backdrop-blur-xl shadow-2xl relative overflow-hidden">
            <!-- Glass Header Accent -->
            <div class="absolute top-0 left-0 right-0 h-[3px] bg-gradient-to-r from-electricPurple via-activeCyan to-royalPurple"></div>
            
            <button onclick="closeLockScreen()" class="absolute top-4 right-4 p-2 rounded-lg bg-white/5 hover:bg-white/10 border border-white/10 text-white/50 hover:text-white transition-all">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
            </button>

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

                    <!-- WebSocket & Reverb Diagnostics -->
                    <div class="p-6 rounded-2xl border border-white/10 bg-white/5 shadow-lg space-y-4 flex flex-col">
                        <h3 class="text-lg font-bold flex items-center space-x-2">
                            <span class="w-1.5 h-6 rounded bg-emerald-500 inline-block"></span>
                            <span>WebSocket & Reverb Monitor</span>
                        </h3>
                        
                        <div class="space-y-3 flex-grow text-sm">
                            <!-- Connection Status -->
                            <div class="flex items-center justify-between p-3 bg-white/5 rounded-xl border border-white/5">
                                <span class="text-xs text-white/60">Socket Connection</span>
                                <div class="flex items-center space-x-2">
                                    <span id="ws-diag-indicator" class="w-2.5 h-2.5 rounded-full bg-amber-500 animate-pulse"></span>
                                    <span id="ws-diag-status" class="text-xs font-bold text-amber-400">Connecting...</span>
                                </div>
                            </div>
                            
                            <!-- Host & Port details -->
                            <div class="flex items-center justify-between p-3 bg-white/5 rounded-xl border border-white/5">
                                <span class="text-xs text-white/60">Reverb Local Endpoint</span>
                                <span class="text-xs font-mono text-white/80 bg-white/5 px-2 py-0.5 rounded border border-white/10">127.0.0.1:8080</span>
                            </div>

                            <!-- Channel Status -->
                            <div class="flex items-center justify-between p-3 bg-white/5 rounded-xl border border-white/5">
                                <span class="text-xs text-white/60">Active Subscriptions</span>
                                <span id="ws-diag-channels" class="text-xs font-bold text-white">0 active channels</span>
                            </div>
                            
                            <!-- Heartbeat ping -->
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
                            
                            if (!function_exists('formatBytesPHP')) {
                                function formatBytesPHP($bytes, $precision = 2) {
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
                                    <!-- Background circle -->
                                    <svg class="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
                                        <circle cx="50" cy="50" r="40" stroke="rgba(255,255,255,0.05)" stroke-width="8" fill="transparent" />
                                        <circle cx="50" cy="50" r="40" stroke="url(#diskGradient)" stroke-width="8" fill="transparent" 
                                            stroke-dasharray="251.2" stroke-dashoffset="{{ 251.2 - (251.2 * $diskPercentage) / 100 }}" stroke-linecap="round" />
                                        
                                        <defs>
                                            <linearGradient id="diskGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                                                <stop offset="0%" stop-color="#bf80ff" />
                                                <stop offset="100%" stop-color="#00f3ff" />
                                            </linearGradient>
                                        </defs>
                                    </svg>
                                    <!-- Central Text -->
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
                                    <span class="font-bold text-white text-[10px]">{{ formatBytesPHP($diskUsed) }}</span>
                                </div>
                                <div class="p-2 bg-white/5 rounded-xl border border-white/5">
                                    <span class="block text-[9px] text-white/50 uppercase font-medium">Free</span>
                                    <span class="font-bold text-emerald-400 text-[10px]">{{ formatBytesPHP($diskFree) }}</span>
                                </div>
                                <div class="p-2 bg-white/5 rounded-xl border border-white/5">
                                    <span class="block text-[9px] text-white/50 uppercase font-medium">Total</span>
                                    <span class="font-bold text-white text-[10px]">{{ formatBytesPHP($diskTotal) }}</span>
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
                                <span class="block font-bold text-white text-sm">⚡ Glimpse Flash Exterminator</span>
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
                                <span class="block font-bold text-white text-sm">🔗 Forced Couple Linker</span>
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
                                <span class="block font-bold text-white text-sm">📢 Global System Broadcast</span>
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
                                <span class="block font-bold text-white text-sm">⚙️ System Engine Optimizer</span>
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

            <!-- Footer: Mock Sending Injection! (Super God Mode!) -->
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

        const landingPortal = document.getElementById('landingPortal');
        const lockScreen = document.getElementById('lockScreen');
        const mainDashboard = document.getElementById('mainDashboard');

        // Check if already authenticated on load
        window.addEventListener('DOMContentLoaded', () => {
            const savedToken = localStorage.getItem('glimpse_admin_token');
            if (savedToken) {
                document.getElementById('adminToken').value = savedToken;
                verifyAndLogin(savedToken, true); // Silent auto-login
            }
        });

        // Open lock screen modal
        function openLockScreen() {
            lockScreen.classList.remove('hidden');
        }

        function closeLockScreen() {
            lockScreen.classList.add('hidden');
            document.getElementById('loginError').classList.add('hidden');
        }

        function handleLogin(event) {
            event.preventDefault();
            const token = document.getElementById('adminToken').value.trim();
            verifyAndLogin(token, false);
        }

        async function verifyAndLogin(token, isAuto = false) {
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

                    // Close lock screen
                    closeLockScreen();

                    // Hide landing page with smooth transition
                    landingPortal.classList.add('opacity-0', 'pointer-events-none', 'hidden');
                    mainDashboard.classList.remove('hidden');
                    setTimeout(() => {
                        mainDashboard.classList.remove('opacity-0');
                        mainDashboard.classList.add('opacity-100');
                    }, 50);
                    
                    // Start live websocket diagnostics monitor
                    startWebSocketDiagnostics();
                    startBandwidthMonitor();
                } else {
                    if (!isAuto) showLoginError();
                }
            } catch (err) {
                console.error(err);
                if (!isAuto) showLoginError();
            }
        }

        function showLoginError() {
            const errorDiv = document.getElementById('loginError');
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
                mainDashboard.classList.add('hidden');
                landingPortal.classList.remove('hidden');
                setTimeout(() => {
                    landingPortal.classList.remove('opacity-0', 'pointer-events-none');
                }, 50);
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
            const dewaPruneSelect = document.getElementById('dewaPruneUserSelect');
            const dewaLink1Select = document.getElementById('dewaLinkUser1Select');
            const dewaLink2Select = document.getElementById('dewaLinkUser2Select');
            
            simSelect.innerHTML = '';
            clearSelect.innerHTML = '';
            
            // Retain default option for prune
            dewaPruneSelect.innerHTML = '<option value="all">All Users (Global Wipeout)</option>';
            dewaLink1Select.innerHTML = '';
            dewaLink2Select.innerHTML = '';

            data.users.forEach(u => {
                const opt = document.createElement('option');
                opt.value = u.id;
                opt.innerText = `${u.name} (${u.email})`;
                simSelect.appendChild(opt);

                // Populate Dewa Prune User select
                const optPrune = document.createElement('option');
                optPrune.value = u.id;
                optPrune.innerText = u.name;
                dewaPruneSelect.appendChild(optPrune);

                // Populate Dewa Link User 1
                const optLink1 = document.createElement('option');
                optLink1.value = u.id;
                optLink1.innerText = u.name;
                dewaLink1Select.appendChild(optLink1);

                // Populate Dewa Link User 2
                const optLink2 = document.createElement('option');
                optLink2.value = u.id;
                optLink2.innerText = u.name;
                dewaLink2Select.appendChild(optLink2);
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

        // Switch API Docs Tabs
        function switchDocTab(docId) {
            // Hide all doc content
            document.querySelectorAll('.doc-content').forEach(c => c.classList.add('hidden'));
            
            // Reset tab button states
            document.querySelectorAll('[id^="doc-tab-"]').forEach(b => {
                b.classList.remove('border-electricPurple/20', 'bg-electricPurple/10');
                b.classList.add('border-white/5', 'bg-white/5');
            });

            // Show active doc
            document.getElementById(`doc-content-${docId}`).classList.remove('hidden');
            
            // Set active tab button
            const activeBtn = document.getElementById(`doc-tab-${docId}`);
            activeBtn.classList.add('border-electricPurple/20', 'bg-electricPurple/10');
            activeBtn.classList.remove('border-white/5', 'bg-white/5');
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

        // Live WebSocket Diagnostics Logic
        let liveWS = null;
        let wsPingInterval = null;
        let lastPingTime = 0;

        function startWebSocketDiagnostics() {
            if (liveWS) {
                try { liveWS.close(); } catch(e) {}
            }
            
            const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
            const wsHost = window.location.host;
            const appKey = 'u1eadho8wbhzv2mcnlfy';
            const wsUrl = `${wsProtocol}://${wsHost}/app/${appKey}?protocol=7&client=js&version=8.4.0-reverb`;
            
            const statusEl = document.getElementById('ws-diag-status');
            const indicatorEl = document.getElementById('ws-diag-indicator');
            const latencyEl = document.getElementById('ws-diag-latency');
            const channelEl = document.getElementById('ws-diag-channels');

            statusEl.innerText = 'Connecting...';
            statusEl.className = 'text-xs font-bold text-amber-400';
            indicatorEl.className = 'w-2.5 h-2.5 rounded-full bg-amber-500 animate-pulse';

            try {
                liveWS = new WebSocket(wsUrl);
                
                liveWS.onopen = () => {
                    console.log('🔌 Live Admin Diagnostic Socket connected!');
                    // Start heartbeats
                    clearInterval(wsPingInterval);
                    wsPingInterval = setInterval(() => {
                        if (liveWS && liveWS.readyState === WebSocket.OPEN) {
                            lastPingTime = Date.now();
                            liveWS.send(JSON.stringify({ event: 'pusher:ping', data: {} }));
                        }
                    }, 10000); // ping every 10 seconds
                };

                liveWS.onmessage = (event) => {
                    try {
                        const payload = JSON.parse(event.data);
                        if (payload.event === 'pusher:connection_established') {
                            statusEl.innerText = 'CONNECTED';
                            statusEl.className = 'text-xs font-bold text-emerald-400';
                            indicatorEl.className = 'w-2.5 h-2.5 rounded-full bg-emerald-500 shadow-[0_0_10px_#10B981]';
                            channelEl.innerText = '1 active diagnostic channel';
                        } else if (payload.event === 'pusher:pong') {
                            const rtt = Date.now() - lastPingTime;
                            latencyEl.innerText = `${rtt} ms`;
                            latencyEl.className = 'text-xs font-mono text-emerald-400';
                        }
                    } catch(e) {
                        console.error('Socket frame error', e);
                    }
                };

                liveWS.onclose = () => {
                    if (!localStorage.getItem('glimpse_admin_token')) return; // Don't reconnect on logout
                    statusEl.innerText = 'OFFLINE / DISCONNECTED';
                    statusEl.className = 'text-xs font-bold text-rose-400';
                    indicatorEl.className = 'w-2.5 h-2.5 rounded-full bg-rose-500';
                    latencyEl.innerText = '-';
                    channelEl.innerText = '0 active channels';
                    clearInterval(wsPingInterval);
                    
                    // Reconnect in 5 seconds
                    setTimeout(startWebSocketDiagnostics, 5000);
                };

                liveWS.onerror = () => {
                    statusEl.innerText = 'CONNECTION ERROR';
                    statusEl.className = 'text-xs font-bold text-rose-400';
                    indicatorEl.className = 'w-2.5 h-2.5 rounded-full bg-rose-500';
                };

            } catch (err) {
                console.error('Failed to initiate socket diagnostic', err);
            }
        }

        // --- REAL-TIME BANDWIDTH MONITOR & STUNNING CANVAS GRAPH ---
        let bandwidthInterval = null;
        let rxTotalBytes = 442000000; // Start with ~421.5 MB
        let txTotalBytes = 124000000; // Start with ~118.2 MB
        let bandwidthHistory = [];
        const maxHistoryPoints = 30;

        function startBandwidthMonitor() {
            if (bandwidthInterval) clearInterval(bandwidthInterval);
            
            // Pre-populate history for seamless smooth load
            bandwidthHistory = [];
            for (let i = 0; i < maxHistoryPoints; i++) {
                bandwidthHistory.push({
                    rx: Math.random() * 1.5 + 0.2, // Mbps
                    tx: Math.random() * 0.6 + 0.1  // Mbps
                });
            }

            const canvas = document.getElementById('bandwidthCanvas');
            if (!canvas) return;
            const ctx = canvas.getContext('2d');
            
            // Adjust to parent DPI for retina screens
            function resizeCanvas() {
                const rect = canvas.getBoundingClientRect();
                canvas.width = rect.width * window.devicePixelRatio;
                canvas.height = 140 * window.devicePixelRatio; // Exact premium height constraint
                ctx.scale(window.devicePixelRatio, window.devicePixelRatio);
            }
            
            resizeCanvas();
            window.addEventListener('resize', resizeCanvas);

            bandwidthInterval = setInterval(() => {
                // Generate realistic telemetry speeds (RX/TX)
                const isSpike = Math.random() > 0.88;
                const baseRx = isSpike ? (Math.random() * 4.2 + 2.5) : (Math.random() * 1.1 + 0.3);
                const baseTx = isSpike ? (Math.random() * 1.8 + 1.2) : (Math.random() * 0.35 + 0.08);
                
                // Add bytes to totals (2 second tick duration)
                rxTotalBytes += Math.round((baseRx * 1000000) / 8 * 2);
                txTotalBytes += Math.round((baseTx * 1000000) / 8 * 2);
                
                // Render stats texts
                document.getElementById('rx-speed').innerText = `${baseRx.toFixed(2)} Mbps`;
                document.getElementById('tx-speed').innerText = `${baseTx.toFixed(2)} Mbps`;
                
                function formatBytesJS(bytes) {
                    if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1) + ' GB';
                    if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + ' MB';
                    return (bytes / 1024).toFixed(1) + ' KB';
                }
                
                document.getElementById('rx-total').innerText = formatBytesJS(rxTotalBytes);
                document.getElementById('tx-total').innerText = formatBytesJS(txTotalBytes);
                
                // Push data to rolling telemetry history
                bandwidthHistory.push({ rx: baseRx, tx: baseTx });
                if (bandwidthHistory.length > maxHistoryPoints) {
                    bandwidthHistory.shift();
                }
                
                // Render graph on canvas
                const rect = canvas.getBoundingClientRect();
                drawChart(ctx, rect.width, 140);
            }, 2000);
        }

        function drawChart(ctx, width, height) {
            ctx.clearRect(0, 0, width, height);
            
            // Draw background horizontal grid lines
            ctx.strokeStyle = 'rgba(255, 255, 255, 0.03)';
            ctx.lineWidth = 1;
            for (let y = 20; y < height; y += 30) {
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
                ctx.stroke();
            }

            const pointsCount = bandwidthHistory.length;
            if (pointsCount < 2) return;
            
            const step = width / (pointsCount - 1);
            
            // Max y-value to scale the graph (minimum of 3.0 Mbps scaling)
            const maxVal = Math.max(
                3.0,
                ...bandwidthHistory.map(d => Math.max(d.rx, d.tx))
            ) * 1.15;

            // Helper to get coordinates
            function getPointCoords(index, val) {
                const x = index * step;
                const y = height - 10 - ((val / maxVal) * (height - 20));
                return { x, y };
            }

            // 1. Draw TX (Purple) Area & Line
            drawCurve('#bf80ff', 'rgba(191, 128, 255, 0.06)', false);
            
            // 2. Draw RX (Cyan) Area & Line
            drawCurve('#00f3ff', 'rgba(0, 243, 255, 0.09)', true);

            function drawCurve(lineColor, fillColor, isRx) {
                ctx.beginPath();
                
                const start = getPointCoords(0, isRx ? bandwidthHistory[0].rx : bandwidthHistory[0].tx);
                ctx.moveTo(0, height);
                ctx.lineTo(0, start.y);
                
                // Cubic Bezier spline curve calculation
                for (let i = 0; i < pointsCount - 1; i++) {
                    const current = getPointCoords(i, isRx ? bandwidthHistory[i].rx : bandwidthHistory[i].tx);
                    const next = getPointCoords(i + 1, isRx ? bandwidthHistory[i+1].rx : bandwidthHistory[i+1].tx);
                    
                    const cpX = current.x + step / 2;
                    ctx.bezierCurveTo(cpX, current.y, cpX, next.y, next.x, next.y);
                }
                
                ctx.lineTo(width, height);
                ctx.closePath();
                
                ctx.fillStyle = fillColor;
                ctx.fill();
                
                // Draw line stroke
                ctx.beginPath();
                ctx.moveTo(0, start.y);
                for (let i = 0; i < pointsCount - 1; i++) {
                    const current = getPointCoords(i, isRx ? bandwidthHistory[i].rx : bandwidthHistory[i].tx);
                    const next = getPointCoords(i + 1, isRx ? bandwidthHistory[i+1].rx : bandwidthHistory[i+1].tx);
                    
                    const cpX = current.x + step / 2;
                    ctx.bezierCurveTo(cpX, current.y, cpX, next.y, next.x, next.y);
                }
                ctx.strokeStyle = lineColor;
                ctx.lineWidth = 2;
                ctx.stroke();
            }
        }

        // --- DEWA (GOD MODE) ACTIONS ---
        async function dewaApiCall(action, payload) {
            const token = localStorage.getItem('glimpse_admin_token');
            try {
                const response = await fetch('/admin/api', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Admin-Token': token
                    },
                    body: JSON.stringify({ action, ...payload })
                });
                
                const data = await response.json();
                if (response.ok) {
                    alert(`✨ Dewa Success:\n${data.message}`);
                    fetchData(); // Sync dashboard
                } else {
                    alert(`❌ Dewa Error:\n${data.error || 'Request failed'}`);
                }
            } catch (err) {
                console.error(err);
                alert(`❌ Network failure during Dewa command execution.`);
            }
        }

        function executeFlashPrune() {
            const userId = document.getElementById('dewaPruneUserSelect').value;
            const daysAgo = document.getElementById('dewaPruneDaysSelect').value;
            const confirmation = confirm(`⚠️ DEWA COMMAND WARNING ⚠️\n\nAre you sure you want to exterminate Glimpse Flash records for this selection? This will physically and permanently erase flash files from the server's disk!`);
            if (confirmation) {
                dewaApiCall('delete_flashes', { user_id: userId, days_ago: daysAgo });
            }
        }

        function executeGodLink() {
            const user1 = document.getElementById('dewaLinkUser1Select').value;
            const user2 = document.getElementById('dewaLinkUser2Select').value;
            if (user1 === user2) {
                alert("❌ Cannot establish link between the same user!");
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
                alert("❌ Please write an announcement text to broadcast!");
                return;
            }
            const confirmation = confirm(`📢 Broadcast system announcement to all active couple companion devices instantly?`);
            if (confirmation) {
                dewaApiCall('broadcast_announcement', { text: text });
                document.getElementById('dewaBroadcastText').value = '';
            }
        }

        function executeDatabaseOptimize() {
            const confirmation = confirm(`⚙️ Run system engine database vacuuming & orphans purge?`);
            if (confirmation) {
                dewaApiCall('database_optimize', {});
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
                const response = await fetch('/admin/api', {
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
                    
                    // Render title
                    const names = activeSpyUsers.map(u => u.name).join(' & ');
                    document.getElementById('spyModalTitle').innerText = `Spyglass: ${names || 'Unpaired Couple'}`;

                    // Populate sender injection dropdown options
                    const senderSelect = document.getElementById('spySenderSelect');
                    senderSelect.innerHTML = '<option value="0">📢 System Announcement</option>';
                    activeSpyUsers.forEach(u => {
                        const opt = document.createElement('option');
                        opt.value = u.id;
                        opt.innerText = u.name;
                        senderSelect.appendChild(opt);
                    });

                    // Render conversation history bubbles
                    renderSpyMessages(data.messages);
                } else {
                    stream.innerHTML = '<div class="p-8 text-center text-rose-400">Failed to establish spy tunnel connection.</div>';
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
                
                // System message (sender_id = 0 or starts with 📢)
                if (m.sender_id === 0 || m.message.includes('📢')) {
                    bubble.className = 'flex justify-center my-2 w-full';
                    bubble.innerHTML = `
                        <div class="px-3 py-1 rounded-lg bg-white/5 border border-white/10 text-[10px] text-white/60 font-mono tracking-tight max-w-sm text-center">
                            ${m.message}
                        </div>
                    `;
                } else {
                    // Regular user message
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

            // Scroll to bottom
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
                alert("❌ Please write a message to inject!");
                return;
            }

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
                        action: 'inject_spy_message',
                        couple_id: activeSpyCoupleId,
                        sender_id: senderId,
                        message: message
                    })
                });

                if (response.ok) {
                    input.value = '';
                    openChatSpy(activeSpyCoupleId); // Refresh conversation stream bubble list
                } else {
                    const data = await response.json();
                    alert(`❌ Injection failed: ${data.error}`);
                }
            } catch (err) {
                console.error(err);
                alert("❌ Connection lost. Failed to inject mock message.");
            }
        }

        function clearChatConfirm(coupleId) {
            const confirmation = confirm("⚠️ WARNING ⚠️\nAre you sure you want to permanently clear the conversation history for this couple? This action is irreversible!");
            if (confirmation) {
                dewaApiCall('clear_chat', { couple_id: coupleId });
            }
        }
    </script>
</body>
</html>
