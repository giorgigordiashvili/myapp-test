#!/bin/bash

echo "Starting build process..."

# Install PHP dependencies
echo "Installing PHP dependencies..."
composer install --no-dev --optimize-autoloader --no-interaction

# Generate app key if not set
if [ -z "$APP_KEY" ]; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# Install Node dependencies and build assets
echo "Installing Node dependencies..."
npm install

echo "Building assets..."
npm run build

# Clear and cache configuration
echo "Caching configuration..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Create storage link
echo "Creating storage link..."
php artisan storage:link

echo "Build completed successfully!"
