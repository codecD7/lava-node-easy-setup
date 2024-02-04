# Use a base image with systemd (if you really need systemd) or just Ubuntu
FROM ubuntu:20.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt update && apt install -y unzip logrotate git jq sed wget curl coreutils

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
RUN /usr/local/go/bin/go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0

# Download genesis binary and setup
RUN wget -O /lavad "https://github.com/lavanet/lava/releases/download/v0.21.1.2/lavad-v0.21.1.2-linux-amd64" && \
    chmod +x /lavad && \
    mkdir -p /cosmovisor/genesis/bin/ && \
    mv /lavad /cosmovisor/genesis/bin/lavad

# Set environment variables
ENV DAEMON_NAME=lavad \
    CHAIN_ID=lava-testnet-2 \
    DAEMON_HOME=/root/.lava \
    DAEMON_ALLOW_DOWNLOAD_BINARIES=true \
    DAEMON_LOG_BUFFER_SIZE=512 \
    DAEMON_RESTART_AFTER_UPGRADE=true \
    UNSAFE_SKIP_BACKUP=true

# Initialize the chain
RUN /cosmovisor/genesis/bin/lavad init my-node --chain-id lava-testnet-2 --home /root/.lava --overwrite

# Expose necessary ports (adjust as needed)
EXPOSE 26656 26657

# Command to run cosmovisor
CMD ["/root/go/bin/cosmovisor", "start"]
