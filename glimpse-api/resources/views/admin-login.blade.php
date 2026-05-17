<!DOCTYPE html>
<html lang="en" class="h-full bg-slate-950">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Glimpse Console — Secure Portal</title>
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
    </style>
    <script>
        // Check if already authenticated to prevent flash of login screen
        (function() {
            const token = localStorage.getItem('glimpse_admin_token');
            if (token && token !== 'undefined' && token !== 'null' && token.trim() !== '') {
                window.location.href = '/admin';
            }
        })();
    </script>
</head>
<body class="h-full antialiased flex items-center justify-center min-h-screen relative">
    
    <!-- Dynamic Futuristic Glowing Background Spheres -->
    <div class="fixed inset-0 z-0 pointer-events-none overflow-hidden">
        <div class="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] rounded-full bg-electricPurple/10 blur-[100px]"></div>
        <div class="absolute bottom-[-10%] right-[-10%] w-[600px] h-[600px] rounded-full bg-royalPurple/10 blur-[120px]"></div>
        <div class="absolute top-[40%] right-[20%] w-[400px] h-[400px] rounded-full bg-activeCyan/5 blur-[90px]"></div>
    </div>

    <!-- Token Verification Portal -->
    <div class="w-full max-w-md p-8 mx-4 rounded-3xl border border-white/10 bg-white/5 backdrop-blur-xl shadow-2xl relative overflow-hidden z-10">
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
        </div>

        <form id="loginForm" onsubmit="handleLogin(event)">
            <div class="space-y-4">
                <div>
                    <label for="adminToken" class="block text-xs font-semibold uppercase tracking-wider text-white/50 mb-2">Security Token</label>
                    <input type="password" id="adminToken" placeholder="••••••••••••••••••••••••" 
                        class="w-full px-4 py-3 rounded-xl border border-white/10 bg-white/5 text-white placeholder-white/20 focus:outline-none focus:ring-2 focus:ring-electricPurple/50 focus:border-electricPurple transition-all"
                        required>
                </div>
                
                <div id="loginError" class="hidden text-rose-400 text-xs font-medium bg-rose-500/10 border border-rose-500/20 py-2 px-3 rounded-lg text-center whitespace-pre-wrap">
                    Invalid admin token. Please try again.
                </div>

                <button type="submit" id="btnSubmit" class="w-full py-3 rounded-xl bg-gradient-to-r from-electricPurple to-royalPurple text-white font-semibold hover:shadow-[0_0_20px_rgba(191,128,255,0.4)] transition-all flex items-center justify-center space-x-2">
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

    <script>
        async function handleLogin(event) {
            event.preventDefault();
            const tokenInput = document.getElementById('adminToken');
            const errorDiv = document.getElementById('loginError');
            const btnSubmit = document.getElementById('btnSubmit');
            const token = tokenInput.value.trim();

            errorDiv.classList.add('hidden');
            btnSubmit.disabled = true;
            btnSubmit.innerHTML = 'Verifying Authenticity...';

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
                    localStorage.setItem('glimpse_admin_token', token);
                    window.location.href = '/admin';
                } else {
                    let errMsg = `Server status ${response.status}: Unauthorized`;
                    try {
                        const errData = await response.json();
                        if (errData && errData.error) {
                            errMsg = errData.error;
                        }
                    } catch(e) {}
                    showLoginError(errMsg);
                }
            } catch (err) {
                showLoginError(`Network Error: ${err.message}`);
            } finally {
                btnSubmit.disabled = false;
                btnSubmit.innerHTML = 'Authenticate';
            }
        }

        function showLoginError(message) {
            const errorDiv = document.getElementById('loginError');
            errorDiv.innerText = message || 'Invalid Admin Token.';
            errorDiv.classList.remove('hidden');
            localStorage.removeItem('glimpse_admin_token');
        }
    </script>
</body>
</html>
