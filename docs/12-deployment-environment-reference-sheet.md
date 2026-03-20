# 12. Deployment Environment Reference Sheet

This document consolidates the confirmed deployment facts for the current project state.
It is meant to be a quick reference for updating workflows, scripts, and exam explanations.

## 1. VM names
- Blue host placeholder: `Albastru_IP`
- Green host placeholder: `Verde_IP`
- Proxy host placeholder: `Prx_IP`
- DB host placeholder: `BazaDeDate_IP`
- Staging host placeholder: `Aplicatie_IP`

## 2. SSH
- Blue SSH user: `deploy`
- Green SSH user: `deploy`
- Proxy SSH user: `deploy`
- DB SSH user: `deploy`
- Staging SSH user: `deploy`
- General passwordless sudo: **NO**
- Limited passwordless sudo on Proxy VM: **YES**, only for:
  - `/usr/local/bin/myproject-switch-proxy`

### Why this matters
The deployment model follows least privilege. The `deploy` user does not have unrestricted root access. Proxy cutover is automated through one tightly scoped root-owned helper script instead of broad passwordless sudo.

## 3. Paths
- Blue app path: `/home/deploy/myproject/app`
- Green app path: `/home/deploy/myproject/app`
- Staging app path: `/home/deploy/myproject/app`
- Blue compose path: `/home/deploy/myproject/app/docker-compose.yml`
- Green compose path: `/home/deploy/myproject/app/docker-compose.yml`
- Staging compose path: `/home/deploy/myproject/app/docker-compose.yml`
- DB compose path: `/home/deploy/myproject/db/docker-compose.db.yml`
- DB env path: `/home/deploy/myproject/db/db.env`
- App env path: `/home/deploy/myproject/app/env/app.env`
- Proxy nginx upstream path: `/etc/nginx/upstreams`
- Active color file path: not defined in scaffold / not required by current proxy model
- Active file path: `/etc/nginx/upstreams/active.conf`
- Blue upstream file: `/etc/nginx/upstreams/blue.conf`
- Green upstream file: `/etc/nginx/upstreams/green.conf`
- Proxy site file: `/etc/nginx/sites-available/myproject.conf`
- Proxy enabled symlink: `/etc/nginx/sites-enabled/myproject.conf`
- Root-owned proxy switch helper: `/usr/local/bin/myproject-switch-proxy`
- Sudoers rule file on Proxy VM: `/etc/sudoers.d/myproject-deploy`

## 4. Ports
- Blue frontend: `80`
- Blue backend: `3000`
- Green frontend: `80`
- Green backend: `3000`
- Staging frontend: `80`
- Staging backend: `3000`
- DB: `5432`
- Proxy public ports: `80`, `443`

## 5. Compose
- Compose command: `docker compose`
- Compose file names:
  - `docker-compose.yml`
  - `docker-compose.db.yml`
- Layout: one app compose file per app VM, one DB compose file on DB VM

## 6. Database
- Topology: dedicated DB VM running Dockerized PostgreSQL
- Blue/Green shared DB: **yes**
- Staging shared with prod in current scaffold: **yes**
- DB name placeholder: `remote_print_db`
- DB user placeholder: `remote_print_user`
- DB password placeholder: `CHANGE_THIS_TO_A_STRONG_DB_PASSWORD`
- Migration command: none currently implemented
- Run migrations during deploy: **NO** in current implementation

### Why migrations are not automated now
A `schema.prisma` file exists, but the backend package is not currently wired for Prisma migrations. There is no Prisma runtime/tooling in the backend `package.json` and no migration script defined there. The honest implementation is therefore to deploy, start containers, and verify app/DB health without pretending migrations are active.

## 7. Repo commands
### Backend
- Lint: not implemented
- Test: `npm run test`
- Integration test: not implemented as a separate script
- Start for CI: `npm run start`
- Dev: `npm run dev`

### Frontend
- Lint: `npm run lint`
- Test: `npm run test`
- Build: `npm run build`
- Preview: `npm run preview`
- UI/E2E test: not implemented as a separate script

### Why this matters
The workflows must call only commands that really exist in the repository. Using guessed commands would make the pipeline look more complete than the application actually supports and would create avoidable failures.

## 8. Proxy switching
- Blue upstream target: `Albastru_IP:80` and `Albastru_IP:3000`
- Green upstream target: `Verde_IP:80` and `Verde_IP:3000`
- Nginx test command: `sudo nginx -t`
- Nginx reload command: `sudo systemctl reload nginx`
- Active proxy model: `active.conf` includes either `blue.conf` or `green.conf`
- Initial active color in scaffold: `blue`
- Automated cutover commands available to `deploy`:
  - `sudo -n /usr/local/bin/myproject-switch-proxy blue`
  - `sudo -n /usr/local/bin/myproject-switch-proxy green`
- Unrestricted sudo for `deploy`: **NO**
- Least-privilege automation model: **YES**

## Final note
This reference sheet reflects the confirmed project state after validating script names, sudo behavior, proxy switching permissions, and the actual deployment layout. It should be used as the source of truth when adapting workflow files, helper scripts, and exam explanation material.
