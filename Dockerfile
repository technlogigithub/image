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
