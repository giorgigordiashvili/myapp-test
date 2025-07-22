<?php
echo "PHP is working!\n";
echo "PHP Version: " . phpversion() . "\n";
echo "Current directory: " . getcwd() . "\n";
echo "Document root: " . $_SERVER['DOCUMENT_ROOT'] . "\n";
echo "Script name: " . $_SERVER['SCRIPT_NAME'] . "\n";

// Check if autoloader exists
$autoloaderPath = __DIR__ . '/../vendor/autoload.php';
if (!file_exists($autoloaderPath)) {
    echo "Autoloader NOT FOUND at: $autoloaderPath\n";
    exit(1);
}

echo "Autoloader found: $autoloaderPath\n";

// Load the autoloader first
try {
    require_once $autoloaderPath;
    echo "Autoloader loaded: SUCCESS\n";
} catch (Exception $e) {
    echo "Autoloader load: FAILED - " . $e->getMessage() . "\n";
    exit(1);
}

// Test Laravel bootstrap
try {
    $app = require_once __DIR__ . '/../bootstrap/app.php';
    echo "Laravel bootstrap: SUCCESS\n";
} catch (Exception $e) {
    echo "Laravel bootstrap: FAILED - " . $e->getMessage() . "\n";
    exit(1);
}

// Test database connection if Laravel loaded
try {
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
