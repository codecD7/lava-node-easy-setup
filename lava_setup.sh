# Create a directory and navigate to it
mkdir /home/lava-node
cd /home/lava-node

# Download docker file
wget https://raw.githubusercontent.com/codecD7/lava-node-easy-setup/main/Dockerfile

# Build the docker image
docker build -t lava-node .

# Run the container
docker run -d --name lava-container lava-node
