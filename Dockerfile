# Use Ubuntu as the base image
FROM ubuntu:20.04

# Avoid prompts from apt during the build process
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt update && apt install -y unzip logrotate git jq sed wget curl coreutils && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Install Go
ENV GO_VERSION=1.20.5
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz
ENV PATH="${PATH}:/usr/local/go/bin"

# Clone and setup lava-config
RUN git clone https://github.com/lavanet/lava-config.git /lava-config && \
    cd /lava-config/testnet-2 && \
    bash -c "source setup_config/setup_config.sh && \
    mkdir -p \$lavad_home_folder && \
    mkdir -p \$lava_config_folder && \
    cp default_lavad_config_files/* \$lava_config_folder && \
    cp genesis_json/genesis.json \$lava_config_folder"

# Download cosmovisor
ENV GOPATH="/root/go"
ENV PATH="${PATH}:${GOPATH}/bin"
RUN go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0

# Set environment variables for cosmovisor and lavad
ENV DAEMON_NAME=lavad \
    CHAIN_ID=lava-testnet-2 \
    DAEMON_HOME=/root/.lava \
    DAEMON_ALLOW_DOWNLOAD_BINARIES=false \
    DAEMON_LOG_BUFFER_SIZE=512 \
    DAEMON_RESTART_AFTER_UPGRADE=true \
    UNSAFE_SKIP_BACKUP=true

# Create the directory structure for cosmovisor and lavad
RUN mkdir -p ${DAEMON_HOME}/cosmovisor/genesis/bin

# Download genesis binary and setup
RUN wget -O ${DAEMON_HOME}/cosmovisor/genesis/bin/lavad "https://github.com/lavanet/lava/releases/download/v0.21.1.2/lavad-v0.21.1.2-linux-amd64" && \
    chmod +x ${DAEMON_HOME}/cosmovisor/genesis/bin/lavad

# Initialize the chain
RUN ${DAEMON_HOME}/cosmovisor/genesis/bin/lavad init my-node --chain-id $CHAIN_ID --home ${DAEMON_HOME} --overwrite

# Expose necessary ports
EXPOSE 26656 26657

# Copy the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Command to run cosmovisor
CMD ["/root/go/bin/cosmovisor", "start"]