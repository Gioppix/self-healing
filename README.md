# Self-Healing Services — Student Walkthrough

Welcome! This small project demonstrates a simple self-healing architecture made of three services running in Docker:

- critical-service — a toy service whose behavior can be toggled between `off` / `slow` / `error`.
- admin-service — receives restart requests and runs `docker restart <service>` to recover containers.
- monitor-service — polls `critical-service`, measures latency/status and triggers `admin-service` if problems are detected. It can also (optionally) send alerts to Telegram.

This README explains the technologies used, how to run the stack, and a set of hands-on scenarios where you will use web links to change service state and observe the self-healing behavior.

## Project layout

- `critical-service` — Express app exposing `/status`, `/set_failure_mode/:mode`, `/get_failure_mode` on port 8080.
- `admin-service` — Express app exposing a POST `/restart_service` endpoint on port 5001 which runs `docker restart <service>`.
- `monitor-service` — background poller that checks `CRITICAL_URL`, compares latency against `LATENCY_THRESHOLD_SEC`, and calls `ADMIN_RESTART_URL` when needed.
- `docker-compose.yml` — builds all three services and wires them together on a Docker network.

## What to prepare (requirements)

- Docker Desktop (or Docker Engine) installed and running.
- Docker Compose (Docker Desktop includes it).
- On Windows: using WSL2 backend or running Docker in Linux mode simplifies the Docker socket mounting used by `admin-service`.

Important note about `admin-service`: it restarts containers by calling the Docker CLI (`docker restart`). That requires access to the Docker daemon. The compose file mounts `/var/run/docker.sock` into the admin container. On Windows this path may not be directly available unless you run Docker with a Unix socket (e.g., WSL2). See the "Windows notes" section below for alternatives.

## Quick start (PowerShell)

1. Build and run the stack:

```powershell
docker compose up --build
```

2. Open the service pages in your browser (these are the links you'll use in the walkthrough):

- Critical service status (use this as your "main" tab):
  - http://localhost:8080/critical-service/status
- Critical service: set failure mode (open a second tab to toggle modes):
  - http://localhost:8080/critical-service/set_failure_mode/off
  - http://localhost:8080/critical-service/set_failure_mode/slow
  - http://localhost:8080/critical-service/set_failure_mode/error
- Critical service: check current mode:
  - http://localhost:8080/critical-service/get_failure_mode

Note: the `set_failure_mode` endpoints are implemented as GET for convenience in this demo (normally you'd use POST).

## Walkthrough scenarios

Follow these hands-on scenarios. Open two browser tabs side-by-side:

1) Baseline (healthy)

- In Tab A open: http://localhost:8080/critical-service/status — you should see a JSON response `{ "status": "OK" }` and HTTP 200.
- Watch the monitor logs in your terminal running `docker compose logs -f monitor` — the monitor should report `Status: 200` and low latency.

2) Simulate a slow service

- In Tab B open: http://localhost:8080/critical-service/set_failure_mode/slow
- Now switch back to Tab A and refresh http://localhost:8080/critical-service/status repeatedly. The endpoint will delay by about 1 second.
- The `monitor-service` polls every `POLL_INTERVAL` seconds (default 5s) and compares latency to `LATENCY_THRESHOLD_SEC` (default 0.5s). Because the service is slower than the threshold, the monitor should detect the problem, log an alert, and call the admin restart endpoint.
- Watch for these signs:
  - `docker compose logs -f monitor` shows an alert and a `Restart triggered` message.
  - `docker compose logs -f admin` shows the restart request received and the admin executing `docker restart`.
  - `docker compose logs -f critical` may show the container restarted (or you can run `docker ps` or `docker logs critical` in another terminal).

3) Simulate an error (unreachable / 5xx)

- In Tab B open: http://localhost:8080/critical-service/set_failure_mode/error
- The `status` endpoint will return HTTP 500 and JSON `{ status: "ERROR" }`.
- Monitor should detect the non-200 response and trigger a restart of the `critical` container.

4) Return to healthy

- In Tab B open: http://localhost:8080/critical-service/set_failure_mode/off
- Refresh Tab A — response should be `{ "status": "OK" }` again.

## Environment variables and Telegram

Edit `.env` (copied from `.env.example`) to control:
- `POLL_INTERVAL` (seconds between monitor checks)
- `LATENCY_THRESHOLD_SEC` (seconds; when exceeded the monitor will consider service too slow)
- `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` (optional) — if provided, monitor will try to send alerts to the specified Telegram chat.

If you don't provide Telegram credentials the monitor will simply print alerts to its logs.

## Windows notes / Docker socket

- The `admin-service` expects to run `docker restart <service>` inside the container. The compose file mounts the host Docker socket (`/var/run/docker.sock`) into the container to allow this. On Linux and WSL2 this works as-is.
- On native Windows (without WSL2) `/var/run/docker.sock` may not be present or accessible. If you see failures in `admin` logs like `Restart failed: ...`, consider these options:
  - Run the stack inside WSL2 (recommended) where the Unix socket is available.
  - Run `admin-service` locally (not in a container) so it uses the host's Docker CLI.
  - Replace the restart mechanism with a Docker API-based approach or use an alternative recovery mechanism (e.g., `docker compose restart critical` from host).

## Troubleshooting

- If monitor never triggers a restart:
  - Check `POLL_INTERVAL`/`LATENCY_THRESHOLD_SEC` in `.env` and the `monitor` logs.
  - Ensure `monitor` can reach `CRITICAL_URL` (service names are resolved via Docker network when containers are used; in local host tests use `localhost:8080`).
- If `admin` fails to restart the container:
  - Check `docker compose logs admin` for the error from the `exec` call.
  - Ensure the Docker CLI is available to the admin container (see Windows notes above).

## Suggested exercises for students

1. Tweak `LATENCY_THRESHOLD_SEC` and `POLL_INTERVAL` to see how detection speed and sensitivity change.
2. Add a POST-based API for `critical-service` to set failure modes instead of GET.
3. Replace `admin-service`'s `exec('docker restart ...')` with direct Docker Engine API calls or Docker SDK usage.
4. Add a small web UI that shows current mode and allows toggling it from one page (single-page demo).

## Summary

This project is a compact, hands-on demo of a self-healing pattern: a monitor detects service degradation and asks an admin component to recover the failing service. Use the links above to toggle the `critical-service` state in a second tab and watch the monitor react in the first tab.

If you want, I can also:
- Add a tiny HTML page to `admin-service` that triggers the restart endpoint from a browser link (so everything is clickable), or
- Convert `docker-compose.yml` to use environment variable substitution (so `.env` values are picked up automatically), or
- Add a short automated test script that hits the links and validates expected behavior.

Which of those would you like next?
