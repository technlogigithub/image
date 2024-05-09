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

# Change Jenkins port to 8484
RUN sed -i 's/HTTP_PORT=8080/HTTP_PORT=8484/g' /etc/default/jenkins

# Install PHP extensions and LAMP stack components
RUN docker-php-ext-install zip pdo pdo_mysql gd && \
    apt-get update && \
    apt-get install -y \
    apache2 \
    mariadb-server \
    php-mbstring php-xml php-mysql libapache2-mod-php && \
    # Enable Apache modules
    a2enmod rewrite && \
    # Start Apache and MySQL services
    service apache2 start && service mysql start && \
    # Configure MySQL root password
    echo "mysql-server mysql-server/root_password password doncen" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password doncen" | debconf-set-selections && \
    apt-get install -y mysql-server && \
    echo -e "n\nn\nn\nn\n" | mysql_secure_installation && \
    # Install phpMyAdmin
    cd /var/www/html/ && \
    wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz && \
    mkdir phpMyAdmin && \
    tar -xvzf phpMyAdmin-latest-all-languages.tar.gz -C phpMyAdmin --strip-components 1 && \
    docker-php-ext-install zip pdo pdo_mysql gd && \
    chown -R www-data:www-data /var/www/html/phpMyAdmin && \
    chmod -R 755 /var/www/html/phpMyAdmin && \
    rm -rf /var/www/html/*

# Copy the rest of the application code
COPY . .

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Remove Composer (if installed globally)
RUN apt-get remove -y composer

# Download and install Composer globally
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"

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

# Restart all services
RUN service apache2 restart && \
    service mysql restart && \
    service jenkins restart

# Start the Apache server
CMD ["apache2-foreground"]
