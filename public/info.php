<?php
echo "PHP is working!\n";
echo "PHP Version: " . phpversion() . "\n";
echo "Current directory: " . getcwd() . "\n";
echo "Document root: " . $_SERVER['DOCUMENT_ROOT'] . "\n";
echo "Script name: " . $_SERVER['SCRIPT_NAME'] . "\n";

// Test Laravel bootstrap
try {
    require_once __DIR__ . '/../bootstrap/app.php';
    echo "Laravel bootstrap: SUCCESS\n";
} catch (Exception $e) {
    echo "Laravel bootstrap: FAILED - " . $e->getMessage() . "\n";
}

// Test database connection if Laravel loaded
try {
    $app = require_once __DIR__ . '/../bootstrap/app.php';
    $app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();
    
    $pdo = new PDO(
        env('DB_CONNECTION') === 'pgsql' ? 
            'pgsql:host=' . env('DB_HOST') . ';port=' . env('DB_PORT') . ';dbname=' . env('DB_DATABASE') :
            'sqlite:' . database_path('database.sqlite'),
        env('DB_USERNAME'),
        env('DB_PASSWORD')
    );
    echo "Database connection: SUCCESS\n";
} catch (Exception $e) {
    echo "Database connection: FAILED - " . $e->getMessage() . "\n";
}

echo "Environment: " . (env('APP_ENV') ?? 'not set') . "\n";
echo "Debug: " . (env('APP_DEBUG') ? 'true' : 'false') . "\n";
echo "App Key: " . (env('APP_KEY') ? 'SET' : 'NOT SET') . "\n";
