<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\HealthController;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/test', function () {
    return response()->json([
        'message' => 'Laravel is working!',
        'environment' => app()->environment(),
        'debug' => config('app.debug'),
        'timestamp' => now()->toISOString()
    ]);
});

Route::get('/health', [HealthController::class, 'check']);
