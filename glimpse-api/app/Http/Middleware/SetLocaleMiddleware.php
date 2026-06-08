<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Symfony\Component\HttpFoundation\Response;

class SetLocaleMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $locale = 'en';

        // 1. Check if authenticated user has a preference set
        if ($request->user() && $request->user()->locale) {
            $locale = $request->user()->locale;
        } 
        // 2. Fallback to Accept-Language header
        elseif ($request->header('Accept-Language')) {
            $headerLocale = strtolower(substr($request->header('Accept-Language'), 0, 2));
            if (in_array($headerLocale, ['en', 'id'])) {
                $locale = $headerLocale;
            }
        }

        App::setLocale($locale);

        return $next($request);
    }
}
