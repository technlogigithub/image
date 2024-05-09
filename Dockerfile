FROM centos:latest

# Modify repository URLs
RUN cd /etc/yum.repos.d/ && \
    sed -i 's/mirrorlist/#mirrorlist/g' CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' CentOS-*

# Install necessary packages and Jenkins
RUN yum update -y && \
    yum install -y \
    unzip \
    zlib \
    libpng \
    freetype \
    sudo \
    java-11-openjdk \
    && yum clean all && \
    # Add Jenkins repository and key
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo && \
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key && \
    # Install Jenkins
    yum update && \
    yum install -y jenkins && \
    # Change Jenkins port to 8484
    sed -i 's/HTTP_PORT=8080/HTTP_PORT=8484/g' /etc/default/jenkins && \
    # Clean up
    yum clean all
