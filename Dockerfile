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
    wget \
    && yum clean all && \
    # Add Jenkins repository and key
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo && \
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key && \
    # Install Jenkins
    yum update && \
    yum install -y jenkins && \
    # Clean up
    yum clean all

# Change Jenkins port to 8484
RUN sed -i 's/<arguments>/& --httpPort=8484/' /etc/sysconfig/jenkins
