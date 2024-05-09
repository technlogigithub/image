FROM php:7.4-apache

# Set the working directory in the container
WORKDIR /var/www/html

# Install system dependencies for PHP, Composer, and other tools
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
    sudo \
    apt-transport-https && \
    # Add Jenkins repository and install Jenkins
    wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key && \
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null && \
    apt-get update && \
    apt-get install -y openjdk-11-jre jenkins && \
    # Change Jenkins port to 8484
    sed -i 's/HTTP_PORT=8080/HTTP_PORT=8484/g' /etc/default/jenkins

# Expose port 80 for Apache
EXPOSE 80

# Start Apache and Jenkins during container startup
CMD apache2-foreground && service jenkins start
