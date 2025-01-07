# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set environment to non-interactive mode for apt installations
ENV DEBIAN_FRONTEND=noninteractive

# Install base tools
RUN apt-get update && apt-get install -y \
    nano \
    screen \
    curl \
    wget \
    htop \
    openssh-server \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create SSH directory
RUN mkdir /var/run/sshd

# Expose ports for GUI/VNC if needed later
EXPOSE 6080

# Start OpenSSH service manually
CMD service ssh start && bash

