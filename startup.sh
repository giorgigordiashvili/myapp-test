#!/bin/bash
set -e

echo "Starting Laravel application..."

# Change to the application directory
cd /var/www/html

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
fi

# Create SQLite database file if using SQLite
if [ "$DB_CONNECTION" = "sqlite" ]; then
    touch /var/www/html/database/database.sqlite
    chmod 664 /var/www/html/database/database.sqlite
fi

# Run database migrations
echo "Running database migrations..."
php artisan migrate --force

# Clear and cache configuration
echo "Caching configuration..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Create storage link if it doesn't exist
if [ ! -L /var/www/html/public/storage ]; then
    echo "Creating storage link..."
    php artisan storage:link
fi

# Set final permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

echo "Starting services..."

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
