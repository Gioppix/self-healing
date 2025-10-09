.PHONY: help up down build restart logs logs-monitor logs-critical logs-admin test clean status

help:
	@echo "Self-Healing Service Architecture - Available Commands:"
	@echo ""
	@echo "  make up          - Start all services"
	@echo "  make down        - Stop all services"
	@echo "  make build       - Build all service images"
	@echo "  make restart     - Restart all services"
	@echo "  make logs        - Follow all service logs"
	@echo "  make logs-monitor   - Follow monitor service logs"
	@echo "  make logs-critical  - Follow critical service logs"
	@echo "  make logs-admin     - Follow admin service logs"
	@echo "  make status      - Check service health"
	@echo "  make test-error  - Trigger error mode"
	@echo "  make test-slow   - Trigger slow mode"
	@echo "  make test-normal - Reset to normal mode"
	@echo "  make clean       - Stop and remove all containers"

up:
	docker-compose up -d --build

down:
	docker-compose down

build:
	docker-compose build

restart:
	docker-compose restart

logs:
	docker-compose logs -f

logs-monitor:
	docker-compose logs -f monitor

logs-critical:
	docker-compose logs -f critical-service

logs-admin:
	docker-compose logs -f admin-service

status:
	@echo "Checking service status..."
	@curl -s http://localhost:8080/status | jq . || echo "Critical service not responding"
	@echo ""
	@curl -s http://localhost:5001/health | jq . || echo "Admin service not responding"

test-error:
	@echo "Triggering error mode..."
	@curl -s http://localhost:8080/set_failure_mode/error | jq .

test-slow:
	@echo "Triggering slow mode..."
	@curl -s http://localhost:8080/set_failure_mode/slow | jq .

test-normal:
	@echo "Resetting to normal mode..."
	@curl -s http://localhost:8080/set_failure_mode/off | jq .

clean:
	docker-compose down -v --remove-orphans
	docker system prune -f
