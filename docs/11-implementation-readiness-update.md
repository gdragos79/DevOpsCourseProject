# Implementation Readiness Update

This note records the concrete project facts that were confirmed after the earlier pack was created, and explains how they changed the workflows and helper scripts.

## 1. Confirmed repository paths

The monorepo layout used by the working application is:

- `apps/backend`
- `apps/frontend`
- `infra/...`

Because of that, all workflow paths were corrected from `backend` / `frontend` to:

- `apps/backend`
- `apps/frontend`

This change was required so that `npm ci`, Docker builds, and package-lock caching point at the real directories.

## 2. Confirmed backend and frontend scripts

### Backend scripts actually available

```json
"scripts": {
  "start": "node index.js",
  "dev": "nodemon index.js",
  "test": "node --test"
}
```

### Frontend scripts actually available

```json
"scripts": {
  "dev": "vite",
  "build": "vite build",
  "lint": "eslint src --ext js,jsx --report-unused-disable-directives --max-warnings 0",
  "preview": "vite preview",
  "test": "vitest run"
}
```

## 3. Workflow impact of the confirmed scripts

Because the backend does **not** currently provide `lint`, `build`, or `test:integration`, Pipeline 1 was corrected to:

- run backend tests with `npm run test`
- start the backend with `npm run start`
- verify backend behavior through live endpoint checks:
  - `/api/health`
  - `/api/db`

This is more honest than inventing backend lint or integration scripts that do not exist.

The frontend does provide:

- `lint`
- `test`
- `build`
- `preview`

so Pipeline 1 keeps real frontend lint and test steps.

## 4. Database and migration decision

A `schema.prisma` file exists, but the backend package does **not** currently include:

- `prisma`
- `@prisma/client`
- a migration script such as `prisma:migrate:deploy`

That means an automated Prisma migration step would be misleading in the current project state.

For that reason, this revised pack does **not** include a fake migration command.

Current deployment scope is therefore:

- pull images
- update `TAG` in the environment file
- restart containers through Docker Compose
- verify backend health, DB probe, and frontend response

## 5. Confirmed remote paths

The working VM scaffold uses these paths:

### App VMs
- app root: `/home/deploy/myproject/app`
- compose file: `/home/deploy/myproject/app/docker-compose.yml`
- env file: `/home/deploy/myproject/app/env/app.env`

### DB VM
- db root: `/home/deploy/myproject/db`
- compose file: `/home/deploy/myproject/db/docker-compose.db.yml`
- env file: `/home/deploy/myproject/db/db.env`

### Proxy VM
- active upstream file: `/etc/nginx/upstreams/active.conf`
- blue upstream file: `/etc/nginx/upstreams/blue.conf`
- green upstream file: `/etc/nginx/upstreams/green.conf`

All deployment scripts were updated to use those real paths instead of the older `/opt/remote-print/...` placeholders.

## 6. Confirmed ports

The scaffolded working application uses:

- frontend on `80`
- backend on `3000`
- PostgreSQL on `5432`

Because of that, the production smoke test script was corrected to use:

- `http://127.0.0.1:3000/api/health`
- `http://127.0.0.1:3000/api/db`
- `http://127.0.0.1/`

This replaced the older temporary `3001` assumption from a different iteration.

## 7. Sudo reality on the proxy host

The `deploy` user does **not** have general passwordless sudo, and that is still correct from a security perspective.

However, the proxy host now uses a **limited passwordless sudo helper**:

- root-owned command: `/usr/local/bin/myproject-switch-proxy`
- sudoers entry: `deploy ALL=(root) NOPASSWD: /usr/local/bin/myproject-switch-proxy`

This means:

- `deploy` still cannot run arbitrary privileged commands without a password
- Pipeline 3 can automate nginx cutover by calling only the approved helper
- the design follows the principle of least privilege and is easier to justify in an exam

## 8. What is now implementation-ready

### Ready now
- Pipeline 1 path corrections
- real script names in Pipeline 1
- staging deployment using the real app path and env file
- blue/green app deployment using the real app path and env file
- smoke tests against the real app ports and endpoints

### Now unblocked by limited sudo helper
- automated proxy switch in Pipeline 3
- automated rollback in Pipeline 3 through the same approved helper pattern

## 9. Recommended next improvement

The recommended proxy design has now been applied:

1. A root-owned helper script performs the cutover.
2. `deploy` can run only that script without a password.

The next improvement would be to mirror the same pattern for any other privileged proxy maintenance actions so the CI/CD model stays consistent.
