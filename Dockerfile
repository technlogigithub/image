FROM centos:latest

# Modify repository URLs
RUN cd /etc/yum.repos.d/ && \
    sed -i 's/mirrorlist/#mirrorlist/g' CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' CentOS-*

# Install necessary packages
RUN yum update -y && \
    yum install -y \
    unzip \
    zlib \
    libpng \
    freetype \
    sudo \
    && yum clean all

# Install Apache HTTP Server and PHP
RUN yum install -y httpd \
    php \
    php-mysql \
    php-mbstring \
    php-xml \
    php-gd \
    php-zip \
    && yum clean all

# Install OpenJDK 11 and Jenkins
RUN yum install -y java-11-openjdk-devel && \
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo && \
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key && \
    yum install -y jenkins && \
    sed -i 's/JENKINS_PORT="8080"/JENKINS_PORT="8484"/g' /etc/sysconfig/jenkins && \
    yum clean all

# Set the working directory
WORKDIR /var/www/html

# Expose ports
EXPOSE 80 8484

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

# Additional steps:
# Start Apache
CMD ["httpd", "-D", "FOREGROUND"]
