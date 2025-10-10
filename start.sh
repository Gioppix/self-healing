#!/bin/bash

set -e

# CHANNEL_ID=channel_name
POLL_INTERVAL=5
LATENCY_THRESHOLD=0.5

docker-compose up -d --build && docker-compose logs -f
