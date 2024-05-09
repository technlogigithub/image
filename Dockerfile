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
    apt-get install -y openjdk-11-jre jenkins mariadb-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up MariaDB/MySQL root user and password
RUN echo "CREATE USER 'root'@'localhost' IDENTIFIED BY 'root123';" > /root/db-setup.sql && \
    echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;" >> /root/db-setup.sql && \
    echo "FLUSH PRIVILEGES;" >> /root/db-setup.sql && \
    mysqld --user=mysql --initialize-insecure --skip-networking && \
    mysqld_safe --skip-grant-tables & \
    sleep 5 && \
    mysql -uroot < /root/db-setup.sql && \
    rm /root/db-setup.sql

# Install PHP extensions
RUN docker-php-ext-install zip pdo pdo_mysql gd

# Enable installed PHP extensions
RUN docker-php-ext-enable zip pdo pdo_mysql gd

# Copy the rest of the application code
COPY . .

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Remove Composer setup files
RUN rm -f composer-setup.php

# Remove Composer lock file if it exists
RUN rm -f /var/www/html/composer.lock

# Update Composer (ignoring platform requirements)
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');" && \
    composer update --ignore-platform-reqs --no-plugins --no-scripts --no-interaction || true

# Expose port 80 to the Docker host for PHP application
EXPOSE 80

# Expose port 8484 for Jenkins web interface
EXPOSE 8484

# Expose port 50000 for Jenkins agent connections
EXPOSE 50000

# Restart all services
RUN service apache2 restart && \
    service mysql restart && \
    service jenkins restart

# Start the Apache server
CMD ["apache2-foreground"]
