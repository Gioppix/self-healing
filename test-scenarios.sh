#!/bin/bash

BASE_URL="http://localhost:8080"
ADMIN_URL="http://localhost:5001"

echo "=== Self-Healing Service Test Scenarios ==="
echo ""

test_normal() {
  echo "Test 1: Normal Operation"
  curl -s "$BASE_URL/set_failure_mode/off"
  sleep 2
  curl -s "$BASE_URL/status" | jq .
  echo ""
}

test_error_mode() {
  echo "Test 2: Error Mode (HTTP 500)"
  curl -s "$BASE_URL/set_failure_mode/error"
  echo "Waiting for monitor to detect and restart..."
  sleep 8
  curl -s "$BASE_URL/status" | jq .
  echo ""
}

test_slow_mode() {
  echo "Test 3: Slow Response Mode (1s delay)"
  curl -s "$BASE_URL/set_failure_mode/slow"
  echo "Waiting for latency threshold breach..."
  sleep 8
  curl -s "$BASE_URL/status" | jq .
  echo ""
}

test_manual_restart() {
  echo "Test 4: Manual Restart via Admin"
  curl -s -X POST "$ADMIN_URL/restart_service" \
    -H "Content-Type: application/json" \
    -d '{"service":"critical"}' | jq .
  sleep 3
  curl -s "$BASE_URL/status" | jq .
  echo ""
}

test_container_stop() {
  echo "Test 5: Container Stop"
  docker stop critical
  echo "Waiting for monitor to detect and restart..."
  sleep 10
  curl -s "$BASE_URL/status" | jq .
  echo ""
}

if [ "$1" == "all" ]; then
  test_normal
  test_error_mode
  test_slow_mode
  test_manual_restart
  echo "=== All tests completed ==="
elif [ "$1" == "error" ]; then
  test_error_mode
elif [ "$1" == "slow" ]; then
  test_slow_mode
elif [ "$1" == "stop" ]; then
  test_container_stop
elif [ "$1" == "restart" ]; then
  test_manual_restart
elif [ "$1" == "normal" ]; then
  test_normal
else
  echo "Usage: $0 [all|normal|error|slow|stop|restart]"
  echo ""
  echo "Examples:"
  echo "  $0 all       - Run all tests"
  echo "  $0 error     - Test error mode recovery"
  echo "  $0 slow      - Test latency threshold"
  echo "  $0 stop      - Test container stop recovery"
  echo "  $0 restart   - Test manual restart"
  echo "  $0 normal    - Reset to normal mode"
fi
