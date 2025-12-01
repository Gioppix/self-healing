#!/bin/bash

set -e

export POLL_INTERVAL=10
export LATENCY_THRESHOLD=0.5
export CHANNEL_ID=""

docker-compose up --build
