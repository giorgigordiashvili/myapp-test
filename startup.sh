#!/bin/bash
set -e

echo "Starting Laravel application..."
echo "PHP Version: $(php --version)"
echo "Current directory: $(pwd)"
echo "Directory contents:"
ls -la

# Change to the application directory
cd /var/www/html

# Check if Laravel is properly installed
if [ ! -f "artisan" ]; then
    echo "ERROR: Laravel artisan command not found!"
    exit 1
fi

echo "Laravel installation found"

# Check environment variables
echo "Environment variables:"
echo "APP_ENV: $APP_ENV"
echo "APP_DEBUG: $APP_DEBUG" 
echo "DB_CONNECTION: $DB_CONNECTION"
if [ ! -z "$DB_HOST" ]; then
    echo "DB_HOST: $DB_HOST"
    echo "DB_PORT: $DB_PORT"
fi

# Wait for database if using managed database
if [ ! -z "$DB_HOST" ]; then
    echo "Waiting for database connection..."
    timeout=60
    while ! nc -z $DB_HOST $DB_PORT; do
        timeout=$((timeout - 1))
        if [ $timeout -eq 0 ]; then
            echo "Database connection timeout"
            exit 1
        fi
        sleep 1
    done
    echo "Database is ready!"
fi

# Generate app key if not set
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:" ]; then
    echo "Generating application key..."
    php artisan key:generate --force
    echo "Application key generated"
else
    echo "APP_KEY is already set"
fi

# Ensure autoloader is properly generated
echo "Regenerating autoloader..."
export COMPOSER_ALLOW_SUPERUSER=1
composer dump-autoload --optimize --no-dev || echo "Composer autoload failed, continuing..."

# Test autoloader
echo "Testing autoloader..."
php -r "require_once '/var/www/html/vendor/autoload.php'; echo 'Autoloader: SUCCESS\n';" || echo "Autoloader: FAILED"

# Create SQLite database file if using SQLite
if [ "$DB_CONNECTION" = "sqlite" ]; then
    echo "Creating SQLite database..."
    mkdir -p /var/www/html/database
    touch /var/www/html/database/database.sqlite
    chmod 664 /var/www/html/database/database.sqlite
    echo "SQLite database created"
fi

# Test database connection
echo "Testing database connection..."
php artisan migrate:status || echo "Migration status check failed - will proceed with migration"

# Run database migrations
echo "Running database migrations..."
php artisan migrate --force || {
    echo "Migration failed! Checking database connection..."
    php -r "
    try {
        \$pdo = new PDO('pgsql:host='.\$_ENV['DB_HOST'].';port='.\$_ENV['DB_PORT'].';dbname='.\$_ENV['DB_DATABASE'], \$_ENV['DB_USERNAME'], \$_ENV['DB_PASSWORD']);
        echo 'Database connection successful\n';
    } catch (Exception \$e) {
        echo 'Database connection failed: ' . \$e->getMessage() . '\n';
        exit(1);
    }
    " || echo "Database connection test failed"
    exit 1
}

echo "Migrations completed successfully"

# Clear and cache configuration
echo "Caching configuration..."
php artisan config:clear
php artisan config:cache || echo "Config cache failed, continuing..."
php artisan route:clear  
php artisan route:cache || echo "Route cache failed, continuing..."
php artisan view:clear
php artisan view:cache || echo "View cache failed, continuing..."

# Create storage link if it doesn't exist
if [ ! -L /var/www/html/public/storage ]; then
    echo "Creating storage link..."
    php artisan storage:link || echo "Storage link failed, continuing..."
fi

# Set final permissions
echo "Setting permissions..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || echo "Permission setting failed, continuing..."
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || echo "Permission setting failed, continuing..."

# Test that Laravel can start
echo "Testing Laravel..."
php artisan --version || {
    echo "Laravel artisan test failed!"
    exit 1
}

# Test basic web functionality
echo "Testing web server configuration..."
php -S localhost:8080 -t public/ > /dev/null 2>&1 &
TEST_PID=$!
sleep 2

# Test if we can reach the info page
curl -f http://localhost:8080/info.php > /tmp/info_test.txt 2>/dev/null && {
    echo "Web server test: SUCCESS"
    cat /tmp/info_test.txt
} || {
    echo "Web server test: FAILED"
    echo "Testing direct PHP execution..."
    php public/info.php || echo "Direct PHP execution failed"
}

# Kill the test server
kill $TEST_PID 2>/dev/null || true

echo "Laravel is ready!"
echo "Starting services..."

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
