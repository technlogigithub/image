FROM amazonlinux:latest

# Update the system and install necessary packages
RUN yum update -y && \
    yum install -y httpd \
                   mysql-server \
                   php \
                   php-mysqlnd \
                   php-mbstring \
                   php-xml \
                   && yum clean all

# Start services
RUN systemctl start httpd && \
    systemctl enable httpd && \
    systemctl start mysqld && \
    systemctl enable mysqld

# Set file permissions
RUN usermod -a -G apache ec2-user && \
    chown -R ec2-user:apache /var/www && \
    chmod -R 2775 /var/www && \
    find /var/www -type d -exec chmod 2775 {} \; && \
    find /var/www -type f -exec chmod 0664 {} \;

# Copy PHP info file into Apache document root
COPY phpinfo.php /var/www/html/

# Remove PHP info file for security reasons
RUN rm -f /var/www/html/phpinfo.php

# Secure MySQL
# Note: The following steps may not be directly applicable in a Docker environment
# You might need to manually secure the MySQL instance after running the container
# RUN mysql_secure_installation ...

# Expose ports
EXPOSE 80

# Command to run Apache in foreground
CMD ["httpd", "-D", "FOREGROUND"]
