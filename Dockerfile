FROM ubuntu:22.04

# Update system and add the packages required for Yocto builds.
# Use DEBIAN_FRONTEND=noninteractive, to avoid image build hang waiting
# for a default confirmation [Y/n] at some configurations.
ENV DEBIAN_FRONTEND=noninteractive

RUN apt clean
RUN apt update
RUN apt upgrade -y
# RUN apt install -y apt-utils
RUN apt install -y --fix-missing gawk wget git-core diffstat \
    unzip tar locales net-tools sudo vim curl xorriso tree cloud-init libnss3 \
    ca-certificates curl gnupg lsb-release dpkg-dev software-properties-common

# Set up locales
RUN locale-gen en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Use dash
RUN rm /bin/sh && ln -s bash /bin/sh

# Add your user to sudoers to be able to install other packages in the container.
ARG USER
RUN echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

# Set the arguments for host_id and user_id to be able to save the build artifacts
# outside the container, on host directories, as docker volumes.
ARG host_uid \
    host_gid
RUN groupadd -g $host_gid build && \
    useradd -g $host_gid -m -s /bin/bash -u $host_uid $USER

# create work dir that is owned by normal user
WORKDIR /home/$USER/builder

# Switch to normal user.
USER $USER
