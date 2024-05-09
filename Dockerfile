FROM centos:latest

# Modify repository URLs
RUN cd /etc/yum.repos.d/ && \
    sed -i 's/mirrorlist/#mirrorlist/g' CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' CentOS-*

# Install necessary packages
RUN yum update -y && \
    yum install -y \
    httpd \
    mariadb-server \
    php \
    php-mysql \
    php-mbstring \
    php-xml \
    wget \
    && yum clean all

# Start services
RUN systemctl start httpd && \
    systemctl enable httpd && \
    systemctl start mariadb && \
    systemctl enable mariadb

# Set permissions
RUN usermod -a -G apache ec2-user && \
    chown -R ec2-user:apache /var/www && \
    chmod -R 2775 /var/www && \
    find /var/www -type d -exec chmod 2775 {} \; && \
    find /var/www -type f -exec chmod 0664 {} \;

# Copy PHP file into Apache document root
COPY phpinfo.php /var/www/html/

# Remove PHP info file for security reasons
RUN rm -f /var/www/html/phpinfo.php

# Secure MariaDB (this part may need adaptation for Docker)
# RUN mysql_secure_installation ... (adapted for Docker)

# Install phpMyAdmin (this part may need adaptation for Docker)
# RUN yum install php-mbstring php-xml -y && \
#     systemctl restart httpd && \
#     systemctl restart php-fpm && \
#     cd /var/www/html && \
#     wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz && \
#     mkdir phpMyAdmin && \
#     tar -xvzf phpMyAdmin-latest-all-languages.tar.gz -C phpMyAdmin --strip-components 1 && \
#     rm phpMyAdmin-latest-all-languages.tar.gz

# Expose ports
EXPOSE 80

# Command to run Apache in foreground
CMD ["httpd", "-D", "FOREGROUND"]
