FROM php:7.4-apache

# Set the working directory in the container
WORKDIR /var/www/html

# Install system dependencies for PHP, Composer, and other tools
RUN yum update -y && \
    yum install -y \
    git \
    unzip \
    libzip \
    zlib \
    libpng \
    libjpeg \
    freetype \
    mariadb \
    mariadb-server \
    wget \
    sudo \
    java-11-openjdk-devel \
    && yum clean all

# Install PHP extensions and LAMP stack components
RUN docker-php-ext-install zip pdo pdo_mysql gd && \
    yum install -y \
    httpd \
    php-mbstring php-xml php-mysqlnd \
    && yum clean all

# Start Apache and MySQL services
RUN systemctl start httpd && systemctl start mariadb

# Enable Apache to start at boot
RUN systemctl enable httpd

# Configure MySQL root password
RUN echo "mysql-server mysql-server/root_password password doncen" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password doncen" | debconf-set-selections && \
    yum install -y mysql-server && \
    echo -e "n\nn\nn\nn\n" | mysql_secure_installation

# Download Jenkins repository file and import the Jenkins key
RUN wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo && \
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Change Jenkins port to 8484
RUN sed -i 's/JENKINS_PORT="8080"/JENKINS_PORT="8484"/g' /etc/sysconfig/jenkins

# Install phpMyAdmin
RUN cd /var/www/html/ && \
    wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz && \
    tar -xvzf phpMyAdmin-latest-all-languages.tar.gz && \
    mv phpMyAdmin-* phpMyAdmin && \
    rm phpMyAdmin-latest-all-languages.tar.gz

# Set permissions
RUN chown -R apache:apache /var/www/html && \
    chmod -R 755 /var/www/html

# Remove Composer (if installed globally)
RUN yum remove -y composer

# Download and install Composer globally
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"

# Remove Composer lock file if exists
RUN rm -f /var/www/html/composer.lock

# Update Composer (ignoring platform requirements)
RUN composer update --ignore-platform-reqs --no-plugins --no-scripts --no-interaction

# Expose port 80 to the Docker host for PHP application
EXPOSE 80

# Expose port 3306 for MySQL
EXPOSE 3306

# Expose port 8080 for Jenkins web interface
EXPOSE 8484

# Switch back to the Apache user
USER apache

# Start the Apache server
CMD ["httpd", "-DFOREGROUND"]
