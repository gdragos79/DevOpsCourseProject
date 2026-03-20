# Helper Scripts — Color-Coded Exam Companion

This document mirrors the style used for the pipeline companions. Each section shows a code interval, a strong color marker, the exact code lines, then an exam-oriented explanation covering **what** the code does, **why** it was designed that way, and what background principle supports it.

## scripts/staging-deploy.sh

### [1-3] Red marker — Entry point and strict mode

```bash
#!/usr/bin/env bash
set -euo pipefail
: "${BUILD_TAG:?BUILD_TAG is required}"
```

**What this block does:** Entry point and strict mode.

**Why I designed it this way:** I start with a shebang and strict shell options so the script fails fast. In an exam, this shows I preferred predictable automation over silent failures.

**Background / justification:** `set -euo pipefail` is a standard defensive Bash pattern: stop on command failure, stop on unset variables, and do not hide pipeline errors.

### [4-7] Orange marker — Target path and deployment context

```bash
APP_ROOT="/opt/remote-print/staging"
echo "Deploying build tag ${BUILD_TAG} to staging at ${APP_ROOT}"
mkdir -p "$APP_ROOT"
cd "$APP_ROOT"
```

**What this block does:** Target path and deployment context.

**Why I designed it this way:** I define one clear staging root so the deployment is repeatable and does not depend on the caller's current directory.

**Background / justification:** A fixed application root under `/opt` is common on Linux servers because it separates managed application files from system files.

### [8-10] Blue marker — Placeholder deployment actions

```bash
# Replace the next lines with your real docker compose pull/up logic.
echo "Placeholder: docker login ghcr.io"
echo "Placeholder: docker compose pull && docker compose up -d"
```

**What this block does:** Placeholder deployment actions.

**Why I designed it this way:** I left these lines as placeholders on purpose, because the generic pack cannot safely invent your final compose file names, login method, or runtime flags.

**Background / justification:** This script is meant to be adapted to the real VM. The placeholders show where image pull and compose startup belong in the staging pipeline.

## scripts/deploy-target.sh

### [1-4] Red marker — Entry point, strict mode, and required inputs

```bash
#!/usr/bin/env bash
        set -euo pipefail
        : "${TARGET_COLOR:?TARGET_COLOR is required}"
        : "${RELEASE_TAG:?RELEASE_TAG is required}"
```

**What this block does:** Entry point, strict mode, and required inputs.

**Why I designed it this way:** This block makes the production deployment fail immediately if a required value is missing. That is important because production scripts should never guess values.

**Background / justification:** `TARGET_COLOR` and `RELEASE_TAG` are the two key runtime inputs: where to deploy, and which already-built artifact to deploy.

### [5-11] Orange marker — Blue/green target selection

```bash
        if [ "$TARGET_COLOR" = "blue" ]; then
          TARGET_HOST="$APP_BLUE_SSH_HOST"
          TARGET_USER="$APP_BLUE_SSH_USER"
        else
          TARGET_HOST="$APP_GREEN_SSH_HOST"
          TARGET_USER="$APP_GREEN_SSH_USER"
        fi
```

**What this block does:** Blue/green target selection.

**Why I designed it this way:** I branch on the target color to resolve the correct host and user. This keeps the rest of the script generic and avoids duplicating the full deployment logic twice.

**Background / justification:** Blue/green deployment works by keeping two parallel environments and sending traffic only to the chosen active one.

### [12-16] Blue marker — Deployment announcement and remote path preparation

```bash
        echo "Deploying ${RELEASE_TAG} to ${TARGET_COLOR} (${TARGET_USER}@${TARGET_HOST})"
        ssh ${TARGET_USER}@${TARGET_HOST} "mkdir -p /opt/remote-print/${TARGET_COLOR}"
        ssh ${TARGET_USER}@${TARGET_HOST} <<EOF
set -euo pipefail
cd /opt/remote-print/${TARGET_COLOR}
```

**What this block does:** Deployment announcement and remote path preparation.

**Why I designed it this way:** I print the deployment target for observability and create the target folder before doing anything more complex.

**Background / justification:** Creating the folder idempotently with `mkdir -p` is safer than assuming the path already exists.

### [17-20] Purple marker — Registry login and remote deploy placeholders

```bash
echo '${GHCR_TOKEN}' | docker login ghcr.io -u '${GHCR_USERNAME}' --password-stdin
# Replace placeholders below with your real compose, migration, and data sync steps.
echo "Placeholder: docker compose pull backend frontend"
echo "Placeholder: docker compose up -d"
```

**What this block does:** Registry login and remote deploy placeholders.

**Why I designed it this way:** I authenticate to GHCR on the target host and then leave explicit placeholder lines for compose pull, compose up, migrations, and data sync.

**Background / justification:** The exam-friendly design choice here is to separate artifact distribution from artifact deployment. Pipeline 2 builds the images, Pipeline 3 deploys the chosen tag.

### [21-21] Teal marker — Remote heredoc boundary

```bash
EOF
```

**What this block does:** Remote heredoc boundary.

**Why I designed it this way:** The heredoc closes the remote SSH command block cleanly so all deployment commands run on the target VM rather than on the GitHub runner.

**Background / justification:** This is a common SSH pattern when multiple remote commands must share one shell session.

## scripts/remote-healthcheck.sh

### [1-2] Red marker — Entry point and strict mode

```bash
#!/usr/bin/env bash
set -euo pipefail
```

**What this block does:** Entry point and strict mode.

**Why I designed it this way:** The script is intentionally small because smoke tests should be quick, explicit, and easy to troubleshoot.

**Background / justification:** A smoke test checks the most critical path after deployment rather than trying to replace the full test suite.

### [3-9] Orange marker — Resolve target host from color

```bash
if [ "$TARGET_COLOR" = "blue" ]; then
  TARGET_HOST="$APP_BLUE_SSH_HOST"
  TARGET_USER="$APP_BLUE_SSH_USER"
else
  TARGET_HOST="$APP_GREEN_SSH_HOST"
  TARGET_USER="$APP_GREEN_SSH_USER"
fi
```

**What this block does:** Resolve target host from color.

**Why I designed it this way:** Like the deploy script, this block maps the abstract color to a concrete server.

**Background / justification:** Using the same color abstraction across scripts keeps the pipeline readable.

### [10-11] Blue marker — Run backend health probe remotely

```bash
ssh ${TARGET_USER}@${TARGET_HOST} "curl -fsS http://127.0.0.1:3001/api/health"
echo "Backend health check succeeded on ${TARGET_COLOR}"
```

**What this block does:** Run backend health probe remotely.

**Why I designed it this way:** I run `curl` on the target VM itself so I test the service from the server side first. This helps isolate application readiness from public proxy issues.

**Background / justification:** Server-local health checks are useful immediately after deployment because they confirm the backend is running before traffic is switched.

## scripts/switch-proxy.sh

### [1-2] Red marker — Entry point and strict mode

```bash
#!/usr/bin/env bash
set -euo pipefail
```

**What this block does:** Entry point and strict mode.

**Why I designed it this way:** Even a short script should fail fast, because a half-applied proxy switch is operationally dangerous.

**Background / justification:** The proxy switch is the critical release moment in blue/green deployment.

### [3-4] Orange marker — Activate target color and reload Nginx

```bash
ssh ${PROXY_SSH_USER}@${PROXY_SSH_HOST} "bash /opt/remote-print/bin/set-active-color.sh '${TARGET_COLOR}' && sudo nginx -t && sudo systemctl reload nginx"
echo "Proxy switched to ${TARGET_COLOR}"
```

**What this block does:** Activate target color and reload Nginx.

**Why I designed it this way:** I call a dedicated helper on the proxy VM, then validate Nginx syntax before reloading. This reduces the chance of pushing broken proxy configuration live.

**Background / justification:** `nginx -t` before reload is an important safety gate. It prevents a reload based on invalid configuration.

## scripts/monitor-rollback.sh

### [1-3] Red marker — Entry point and failure counter

```bash
#!/usr/bin/env bash
set -euo pipefail
failures=0
```

**What this block does:** Entry point and failure counter.

**Why I designed it this way:** I initialize the rollback monitor with strict mode and a simple failure counter. The script is intentionally conservative: a failed post-switch check is enough to trigger rollback.

**Background / justification:** Rollback monitoring belongs after the proxy switch because some failures appear only under live traffic.

### [4-13] Orange marker — Timed health-check loop

```bash
for i in $(seq 1 10); do
  if curl -fsS "$PUBLIC_FRONTEND_URL" >/dev/null && curl -fsS "$PUBLIC_BACKEND_HEALTH_URL" >/dev/null; then
    echo "Minute $i: healthy"
  else
    failures=$((failures + 1))
    echo "Minute $i: unhealthy"
    break
  fi
  sleep 60
done
```

**What this block does:** Timed health-check loop.

**Why I designed it this way:** This loop watches the public frontend and public backend health endpoint during the rollback window. I chose a bounded loop so the workflow does not hang forever.

**Background / justification:** A fixed observation window is a common release-engineering pattern. It gives the new environment time to stabilize while keeping the operation auditable.

### [14-18] Blue marker — Rollback action on failure

```bash
if [ "$failures" -gt 0 ]; then
  ssh ${PROXY_SSH_USER}@${PROXY_SSH_HOST} "bash /opt/remote-print/bin/set-active-color.sh '${PREVIOUS_COLOR}' && sudo nginx -t && sudo systemctl reload nginx"
  echo "Rollback executed to ${PREVIOUS_COLOR}"
  exit 1
fi
```

**What this block does:** Rollback action on failure.

**Why I designed it this way:** If a post-switch check fails, I immediately switch traffic back to the previous color and fail the workflow run.

**Background / justification:** The workflow should surface the release as failed when rollback occurs. That preserves traceability and supports incident review.

### [19-19] Purple marker — Success message

```bash
echo "Rollback window finished successfully"
```

**What this block does:** Success message.

**Why I designed it this way:** If the whole window stays healthy, I print a clear completion message to make the release status easy to read in Actions logs.

**Background / justification:** Small observability messages improve operator confidence during manual reviews.
