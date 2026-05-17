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
                    <a href="/admin" class="px-5 py-2 rounded-xl bg-gradient-to-r from-electricPurple to-royalPurple text-white font-semibold text-sm hover:shadow-[0_0_20px_rgba(191,128,255,0.4)] transition-all flex items-center space-x-2">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 17.25v1.007a3 3 0 01-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0115 18.257V17.25m6-12V15a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 15V5.25m18 0A2.25 2.25 0 0018.75 3H5.25A2.25 2.25 0 003 5.25m18 0V12a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 12V5.25" />
                        </svg>
                        <span>Admin Console</span>
                    </a>
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
                        <a href="/admin" class="px-6 py-3.5 rounded-xl bg-gradient-to-r from-electricPurple to-royalPurple text-white font-bold hover:shadow-[0_0_25px_rgba(191,128,255,0.4)] transition-all text-sm flex items-center space-x-2">
                            <span>Launch Admin Dashboard</span>
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                            </svg>
                        </a>
                    </div>
                </div>

                <!-- Right Visual Mockup -->
                <div class="lg:col-span-5 relative flex justify-center">
                    <div class="w-80 h-[500px] rounded-[48px] border-4 border-white/20 bg-slate-900 shadow-2xl relative p-4 flex flex-col justify-between overflow-hidden">
                        <!-- Camera notch -->
                        <div class="absolute top-2 left-1/2 -translate-x-1/2 w-32 h-6 bg-black rounded-full z-20"></div>
                        
                        <!-- Internal Screen Content -->
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

    <!-- Smooth Tab Switching for API Documentation -->
    <script>
        function switchDocTab(tabId) {
            document.querySelectorAll('.doc-content').forEach(c => c.classList.add('hidden'));
            document.querySelectorAll('#docs button').forEach(b => {
                b.classList.remove('border-electricPurple/20', 'bg-electricPurple/10');
                b.classList.add('border-white/5', 'bg-white/5');
            });

            document.getElementById(`doc-content-${tabId}`).classList.remove('hidden');
            const activeBtn = document.getElementById(`doc-tab-${tabId}`);
            if (activeBtn) {
                activeBtn.classList.remove('border-white/5', 'bg-white/5');
                activeBtn.classList.add('border-electricPurple/20', 'bg-electricPurple/10');
            }
        }
    </script>
</body>
</html>
