# Use an official PHP 7.4 runtime as a parent image
FROM php:7.4-apache

# Set the working directory in the container
WORKDIR /var/www/html

# Install system dependencies for PHP and Composer
RUN apt-get update && \
    apt-get install -y \
    git \
    unzip \
    libzip-dev \
    zlib1g-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    default-mysql-client \
    libmariadb-dev \
    wget \
    gnupg2 \
    sudo && \
    wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key && \
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null && \
    apt-get update && \
    apt-get install -y openjdk-11-jre jenkins
    
# Install PHP extensions
RUN docker-php-ext-install zip pdo pdo_mysql gd

# Enable installed PHP extensions
RUN docker-php-ext-enable zip pdo pdo_mysql gd

# Copy the rest of the application code
COPY . .

# Set permissions
# RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Remove Composer (if installed globally)
RUN apt-get remove -y composer

# Download Composer installer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

# Run the Composer installer
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Remove Composer setup file
RUN php -r "unlink('composer-setup.php');"

# Remove Composer lock file
RUN rm /var/www/html/composer.lock

# Update Composer (ignoring platform requirements)
RUN composer update --ignore-platform-reqs --no-plugins --no-scripts --no-interaction


# Expose port 80 to the Docker host for PHP application
EXPOSE 80

# Expose port 8484 for Jenkins web interface
EXPOSE 8484

# Expose port 50000 for Jenkins agent connections
EXPOSE 50000

# Switch back to the Apache user
USER www-data

# Start the Apache server
CMD ["apache2-foreground"]
