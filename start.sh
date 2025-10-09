#!/bin/bash

set -e



docker-compose up -d --build

echo ""
echo "Waiting for services to be ready..."
sleep 5

echo ""
echo "Testing services..."

if curl -s http://localhost:8080/status > /dev/null; then
    echo "✓ Critical Service is running on port 8080"
else
    echo "✗ Critical Service not responding"
fi

if curl -s http://localhost:5001/health > /dev/null; then
    echo "✓ Admin Service is running on port 5001"
else
    echo "✗ Admin Service not responding"
fi

if docker ps | grep -q monitor; then
    echo "✓ Monitor Service is running"
else
    echo "✗ Monitor Service not running"
fi

echo ""
echo "=== Services Started Successfully ==="
echo ""
echo "Available commands:"
echo "  make status       - Check service health"
echo "  make logs-monitor - View monitor logs"
echo "  make test-error   - Trigger error mode"
echo "  make test-slow    - Trigger slow mode"
echo "  make down         - Stop all services"
echo ""
echo "Or use Docker Compose directly:"
echo "  docker-compose logs -f monitor-service"
echo "  curl http://localhost:8080/status"
echo ""
echo "View monitor logs now:"
docker-compose logs -f monitor-service
