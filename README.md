# Minimal monorepo skeleton

This archive contains the minimum practical files extracted from the provided project zip so the application and infrastructure can be rebuilt cleanly.

Included:
- `apps/backend` - Node/Express backend
- `apps/frontend` - React/Vite frontend with a corrected production Dockerfile
- `infra/db` - PostgreSQL container definition
- `infra/deploy` - app compose definition
- `infra/proxy-nginx` - blue/green proxy configs
- `infra/systemd` - example systemd units

Not included:
- notes, presentations, extra guides
- experimental or duplicate GitHub workflow files
- test/lint-only frontend files

Important:
- The frontend Dockerfile in the original archive was a dev-oriented file with a wrong copy path. In this clean repo it has been replaced with a production-ready multi-stage Dockerfile plus `nginx.conf`.
