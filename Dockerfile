FROM centos:latest

# Install necessary packages
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
    --disablerepo=appstream \
    && yum clean all

# Install Apache HTTP Server
RUN yum install -y httpd && \
    systemctl enable httpd

# Install PHP and necessary PHP extensions
RUN yum install -y \
    php \
    php-mysql \
    php-mbstring \
    php-xml \
    php-gd \
    php-zip \
    && yum clean all

# Set the working directory
WORKDIR /var/www/html

# Expose port 80 for Apache
EXPOSE 80

# Download Jenkins repository file and import the Jenkins key
RUN wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo && \
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install phpMyAdmin
RUN cd /var/www/html/ && \
    wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz && \
    tar -xvzf phpMyAdmin-latest-all-languages.tar.gz && \
    mv phpMyAdmin-* phpMyAdmin && \
    rm phpMyAdmin-latest-all-languages.tar.gz

# Change Jenkins port to 8484
RUN sed -i 's/JENKINS_PORT="8080"/JENKINS_PORT="8484"/g' /etc/sysconfig/jenkins

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

# Expose port 8484 for Jenkins web interface
EXPOSE 8484
