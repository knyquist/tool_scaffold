#!/bin/bash

# Start the registry container if it's not already running
echo "Starting docker registry if not already started"
[[ $(docker ps --filter ancestor=registry --format '{{.Image}}') == registry ]] || docker run -d -p 5000:5000 registry