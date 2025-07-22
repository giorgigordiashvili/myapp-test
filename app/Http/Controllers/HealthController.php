<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class HealthController extends Controller
{
    public function check(): JsonResponse
    {
        return response()->json([
            'status' => 'ok',
            'app_name' => config('app.name'),
            'environment' => app()->environment(),
            'debug' => config('app.debug'),
            'database' => $this->checkDatabase(),
            'cache' => $this->checkCache(),
            'timestamp' => now()->toISOString()
        ]);
    }

    private function checkDatabase(): array
    {
        try {
            \DB::connection()->getPdo();
            return ['status' => 'connected', 'driver' => config('database.default')];
        } catch (\Exception $e) {
            return ['status' => 'error', 'message' => $e->getMessage()];
        }
    }

    private function checkCache(): array
    {
        try {
            cache()->put('health_check', 'ok', 60);
            $value = cache()->get('health_check');
            return ['status' => $value === 'ok' ? 'working' : 'error'];
        } catch (\Exception $e) {
            return ['status' => 'error', 'message' => $e->getMessage()];
        }
    }
}
