#!/bin/bash

# Pull required Docker images
docker compose pull
docker pull hummingbot/hummingbot:latest

# Create .env file with environment variables
echo "CONFIG_PASSWORD=a" > .env
echo "BOTS_PATH=$(pwd)" >> .env

# Start Docker containers in detached mode
docker compose up -d

# Step 4: Locate the running container
CONTAINER_ID=$(docker ps --filter "name=backend-api" --format "{{.ID}}")

if [ -z "$CONTAINER_ID" ]; then
    echo "Error: Could not find a running Hummingbot container."
    exit 1
fi

echo "Installing dependencies in container: $CONTAINER_ID"

# Install necessary tools inside the container
docker run -it --rm --network host hummingbot/hummingbot:latest bash -c "
apt-get update &&
apt-get install -y dnsutils iputils-ping vim supervisor
"

# Configure Supervisor for Hummingbot
SUPERVISOR_CONF="/etc/supervisor/conf.d/hummingbot.conf"
docker exec -it $CONTAINER_ID bash -c "
mkdir -p /etc/supervisor/conf.d &&
echo '[program:hummingbot]
command=/opt/conda/envs/backend-api/bin/python /opt/conda/envs/backend-api/lib/python3.10/site-packages/hummingbot/main.py
autostart=true
autorestart=true
stderr_logfile=/var/log/hummingbot.err.log
stdout_logfile=/var/log/hummingbot.out.log
' > $SUPERVISOR_CONF
"

# Start Supervisor and Hummingbot
docker exec -it $CONTAINER_ID bash -c "
mkdir -p /var/run/supervisor &&
supervisord -c /etc/supervisor/supervisord.conf
"

# Reload Supervisor and start Hummingbot
docker exec -it $CONTAINER_ID bash -c "
supervisorctl reread &&
supervisorctl update &&
supervisorctl start hummingbot
"

echo "Setup complete. Hummingbot is running and configured."




