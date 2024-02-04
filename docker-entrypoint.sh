#!/bin/bash

# Download the latest genesis file
echo "Downloading latest genesis.json..."
curl -Ls https://snapshots.aknodes.net/snapshots/lava/genesis.json > $HOME/.lava/config/genesis.json

# Proceed to run whatever command was passed to docker run or to the CMD
exec "$@"