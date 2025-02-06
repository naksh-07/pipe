#!/bin/bash

# Set Variables
POP_BINARY_URL="https://dl.pipecdn.app/v0.2.3/pop"
POP_BINARY_NAME="pop"
CACHE_DIR="download_cache"
ENV_FILE="pop.env"
DOCKER_IMAGE="pop_service"
DOCKER_CONTAINER="pop_container"

# Function to check command dependencies
check_command() {
    command -v "$1" >/dev/null 2>&1 || { echo "Error: $1 is not installed. Please install it."; exit 1; }
}

# Check for required commands
check_command wget
check_command docker

# Download the binary if it doesn't exist
if [[ ! -f "$POP_BINARY_NAME" ]]; then
    echo "Downloading $POP_BINARY_NAME..."
    wget "$POP_BINARY_URL" -O "$POP_BINARY_NAME"
else
    echo "$POP_BINARY_NAME already exists, skipping download."
fi

# Make the binary executable
chmod +x "$POP_BINARY_NAME"

# Create required directory
mkdir -p "$CACHE_DIR"

# Prompt user for referral code
echo "Please enter your referral code:"
read -r REFERRAL_CODE

# Ensure the environment file exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: Configuration file $ENV_FILE not found! Creating a template..."
    cat <<EOF > "$ENV_FILE"
RAM=8
MAX_DISK=500
CACHE_DIR=/data
SOLANA_PUBKEY=your_solana_public_key_here
EOF
    echo "Please edit '$ENV_FILE' to add your Solana Public Key before running again."
    exit 1
fi

# Load environment variables
source "$ENV_FILE"

# Create a Dockerfile dynamically
cat <<EOF > Dockerfile
FROM ubuntu:latest

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    openssl \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*  # Clean up to reduce image size

# Set working directory
WORKDIR /app

# Copy binary and config files
COPY pop /app/
COPY pop.env /app/

# Create cache directory
RUN mkdir -p /data

# Make binary executable
RUN chmod +x /app/pop

# Load environment variables
ENV RAM=${RAM}
ENV MAX_DISK=${MAX_DISK}
ENV CACHE_DIR=${CACHE_DIR}
ENV SOLANA_PUBKEY=${SOLANA_PUBKEY}

# Run service with configuration
CMD ["/app/pop", "--ram", "$RAM", "--max-disk", "$MAX_DISK", "--cache-dir", "/data", "--pubKey", "$SOLANA_PUBKEY"]
EOF

# Remove any existing container
docker rm -f "$DOCKER_CONTAINER" 2>/dev/null

# Build Docker Image
echo "Building Docker image..."
docker build -t "$DOCKER_IMAGE" .

# Run the Docker container
echo "Running Docker container..."
docker run -d --name "$DOCKER_CONTAINER" \
  -v "$(pwd)/$CACHE_DIR:/data" \
  --restart unless-stopped \
  "$DOCKER_IMAGE"

echo "✅ Service is running in Docker as '$DOCKER_CONTAINER'!"
