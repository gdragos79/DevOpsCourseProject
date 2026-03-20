# Document 4 — Pipeline 3 blue/green hand-held implementation

## 1. Files involved
- `.github/workflows/03-production-bluegreen.yml`
- `scripts/deploy-target.sh`
- `scripts/remote-healthcheck.sh`
- `scripts/switch-proxy.sh`
- `scripts/monitor-rollback.sh`

## 2. Expected VM-side file locations
This pack assumes these paths:
- Blue app root: `/home/deploy/myproject/app`
- Green app root: `/home/deploy/myproject/app`
- Staging root: `/home/deploy/myproject/app`
- Proxy active upstream file: `/etc/nginx/upstreams/active.conf`
- Proxy blue upstream file: `/etc/nginx/upstreams/blue.conf`
- Proxy green upstream file: `/etc/nginx/upstreams/green.conf`
- Proxy privileged helper: `/usr/local/bin/myproject-switch-proxy`

## 3. How SSH secrets are used
- `APP_BLUE_SSH_*` lets the workflow reach the blue app VM.
- `APP_GREEN_SSH_*` lets the workflow reach the green app VM.
- `PROXY_SSH_*` lets the workflow detect the active color and call the root-owned helper on the proxy VM.

## 4. Switching logic
1. Ask the proxy which color is currently live.
2. Choose the other color as the target.
3. Deploy the chosen release tag to the idle target.
4. Run smoke tests on that idle target.
5. Only if those tests pass, change the proxy to point to the new color.

## 5. Smoke tests
The provided script checks the backend health endpoint remotely. You should extend it with:
- a frontend HTTP check
- API route checks
- optional UI tests if practical

## 6. Rollback logic
After the traffic switch, the workflow monitors public health URLs for up to 10 minutes. If a check fails, the workflow calls the proxy helper again and switches traffic back to the previous color.

## 7. What you still must customize
Replace the placeholders in `deploy-target.sh` with your real commands for:
- GHCR login on the target VM
- `docker compose pull`
- `docker compose up -d`
- database sync or migration commands if required by your exam interpretation


## Important implementation update

The production application deploy steps are now aligned to the confirmed VM scaffold:

- Blue and Green app roots: `/home/deploy/myproject/app`
- env file: `/home/deploy/myproject/app/env/app.env`
- compose file: `/home/deploy/myproject/app/docker-compose.yml`
- frontend port: `80`
- backend port: `3000`
- backend health endpoint: `/api/health`
- DB probe endpoint: `/api/db`

The deployment scripts now update the `TAG` line in `app.env`, then run Docker Compose pull and restart commands on the idle color.

### Proxy cutover status

The proxy-side blocker has now been addressed with a **limited passwordless sudo design**:

- `/usr/local/bin/myproject-switch-proxy` is owned by `root`
- `deploy` is allowed to run **only that command** through sudo without a password
- the helper updates `/etc/nginx/upstreams/active.conf`, runs `nginx -t`, and reloads nginx

That means Pipeline 3 can now automate the proxy cutover without granting broad root access to `deploy`.
