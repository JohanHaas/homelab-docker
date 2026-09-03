#!/bin/bash
set -e

cd /home/johan/docker

echo "Deploying homelab-docker..."
echo "Pulling latest changes..."
git pull origin main

echo "Starting Gateway services..."
cd hosts/gateway
docker compose up -d
echo "Gateway services started"

echo "Starting Homelab services..."
cd ../homelab
docker compose -f ../../runner/compose.yaml up -d
echo "Homelab services started"

echo "Deploy complete"
