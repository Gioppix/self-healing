# Self-Healing Services — Walkthrough

Welcome! This small project demonstrates a simple self-healing architecture made of three services running in Docker:

- critical-service — a toy service whose behavior can be toggled between `off` / `slow` / `error`.
- admin-service — receives restart requests and runs `docker restart <service>` to recover containers.
- monitor-service — polls `critical-service`, measures latency/status and triggers `admin-service` if problems are detected. It can also (optionally) send alerts to Telegram.

## Project layout

- `critical-service` — Express app exposing `/status`, `/set_failure_mode/:mode`, `/get_failure_mode` on port 8080.
- `admin-service` — Express app exposing a POST `/restart_service` endpoint on port 5001 which runs `docker restart <service>`.
- `monitor-service` — background poller that checks `CRITICAL_URL`, compares latency against `LATENCY_THRESHOLD_SEC`, and calls `ADMIN_RESTART_URL` when needed.
- `docker-compose.yml` — builds all three services and wires them together on a Docker network.

## What to prepare (requirements)

- Docker Desktop (or Docker Engine) installed and running.
- Docker Compose (Docker Desktop includes it).
- On Windows: WSL2 is required. This project depends on a Unix-style Docker socket (`/var/run/docker.sock`) which is available when Docker Desktop is used with the WSL2 backend. Run all commands from a WSL2 shell.

Using the provided `start.sh` script

- A convenience script `start.sh` is included to build and start the stack and tail the logs. Run it from Linux or a WSL2 shell:

```bash
./start.sh
```

- The script contains a placeholder `CHANNEL_ID` variable, replace it with a channel of your choice.

### Managing Telegram channels subscriptions

To receive Telegram notifications, follow these steps:

- Open `@self_healing_bot` on Telegram
- Send `/subscribe <channel_id>`
    - `channel_id` can only contain alphanumeric characters and underscores (e.g. `live_demo`)
    - Use a unique name to avoid conflicts with other users
- You can be subscribed to multiple channels at once
- You can also use `/unsubscribe <channel_id>` if needed

## Walkthrough scenarios

Follow these hands-on scenarios. Open two browser tabs side-by-side:

1. Baseline (healthy)

- In Tab A open: http://localhost:8080/critical-service/status — you should see a JSON response `{ "status": "OK" }` and HTTP 200.
- Watch the monitor logs in your terminal running `docker compose logs -f monitor` — the monitor should report `Status: 200` and low latency.

2. Simulate a slow service

- In Tab B open: http://localhost:8080/critical-service/set_failure_mode/slow
- Now switch back to Tab A and refresh http://localhost:8080/critical-service/status repeatedly. The endpoint will delay by about 1 second.
- The `monitor-service` polls every `POLL_INTERVAL` seconds (default 5s) and compares latency to `LATENCY_THRESHOLD_SEC` (default 0.5s). Because the service is slower than the threshold, the monitor should detect the problem, log an alert, and call the admin restart endpoint.
- Watch for these signs:
    - `docker compose logs -f monitor` shows an alert and a `Restart triggered` message.
    - `docker compose logs -f admin` shows the restart request received and the admin executing `docker restart`.
    - `docker compose logs -f critical` may show the container restarted (or you can run `docker ps` or `docker logs critical` in another terminal).
      These can also be viewed from the dedicated Docker GUI.

3. Simulate an error (unreachable / 5xx)

- In Tab B open: http://localhost:8080/critical-service/set_failure_mode/error
- The `status` endpoint will return HTTP 500 and JSON `{ status: "ERROR" }`.
- Monitor should detect the non-200 response and trigger a restart of the `critical` container.

4. Return to healthy

- In Tab B open: http://localhost:8080/critical-service/set_failure_mode/off
- Refresh Tab A — response should be `{ "status": "OK" }` again.

## Parameters to edit

Edit `start.sh` to control:

- `POLL_INTERVAL` (seconds between monitor checks)
- `LATENCY_THRESHOLD_SEC` (seconds; when exceeded the monitor will consider service too slow)
- `CHANNEL_ID` (Telegram channel ID: if not provided the monitor will simply print alerts to its logs.)

## Windows notes / Docker socket

- The `admin-service` expects to run `docker restart <service>` inside the container. The compose file mounts the host Docker socket (`/var/run/docker.sock`) into the container to allow this. On Linux and WSL2 this works as-is.
- The `admin-service` expects to run `docker restart <service>` inside the container. The compose file mounts the host Docker socket (`/var/run/docker.sock`) into the container to allow this. On Linux and WSL2 this works as-is.
- On Windows: ensure Docker Desktop WSL2 integration is enabled for your distribution. If `admin` fails to restart containers, check the `admin` logs and confirm the socket is available inside the container.

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

## Telegram Proxy

For more information about the Telegram proxy implementation, refer to the [telegram-bot-proxy repository](https://github.com/gioppix/telegram-bot-proxy/).
