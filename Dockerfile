# Base image
FROM debian:bullseye-slim

# Install required packages for our script
RUN apt-get update && apt-get install -y \
    bash \
    ca-certificates \
    curl \
    unzip \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Download and install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

RUN pip3 install pinecone-client cohere

# Copy your code file to the filesystem
COPY entrypoint.sh /entrypoint.sh
COPY pinecone_sync.py /github/workspace/pinecone_sync.py

# Change permission to execute the script
RUN chmod +x /entrypoint.sh

# File to execute when the docker container starts up
ENTRYPOINT ["/entrypoint.sh"]
