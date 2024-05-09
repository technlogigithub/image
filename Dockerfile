FROM php:7.4-apache

# Set the working directory in the container
WORKDIR /var/www/html

# Update package list and install necessary dependencies
RUN apt-get update && apt-get install -y \
    gnupg2 \
    software-properties-common \
    apt-transport-https \
    lsb-release \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Add Debian repository for PHP
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

# Update package list again
RUN apt-get update

# Install PHP extensions and LAMP stack components
RUN apt-get install -y \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    default-mysql-client \
    libmariadb-dev \
    apache2 \
    mariadb-server \
    php7.4-cli \
    php7.4-common \
    php7.4-json \
    php7.4-opcache \
    libapache2-mod-php7.4

# Enable Apache modules
RUN a2enmod rewrite

# Start Apache and MySQL services
RUN service apache2 start && \
    service mysql start

# Configure MySQL root password
RUN echo "mysql-server mysql-server/root_password password doncen" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password doncen" | debconf-set-selections && \
    apt-get install -y mysql-server && \
    echo -e "n\nn\nn\nn\n" | mysql_secure_installation

# Install phpMyAdmin dependencies
RUN apt-get install -y php-mbstring php-xml php-mysql

# Install phpMyAdmin
RUN wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz && \
    mkdir phpMyAdmin && \
    tar -xvzf phpMyAdmin-latest-all-languages.tar.gz -C phpMyAdmin --strip-components 1 && \
    chown -R www-data:www-data /var/www/html/phpMyAdmin && \
    chmod -R 755 /var/www/html/phpMyAdmin && \
    rm -rf /var/www/html/*phpMyAdmin-latest-all-languages.tar.gz

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

# Start the Apache server
CMD ["apache2-foreground"]
