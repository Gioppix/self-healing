#!/bin/bash

set -e

CHANNEL_ID=channel_name
docker-compose up -d --build && docker-compose logs -f
