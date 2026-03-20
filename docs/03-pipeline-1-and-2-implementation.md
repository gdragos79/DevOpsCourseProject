# Document 3 — Pipeline 1 and Pipeline 2 hand-held implementation

## Part A — Files you must copy
Copy these files into your monorepo:
- `.github/workflows/01-ci-validation.yml`
- `.github/workflows/02-staging-deploy.yml`
- `scripts/staging-deploy.sh`
- `.env.secrets.example`

## Part B — Backend `package.json` scripts expected by Pipeline 1
Your backend should expose scripts similar to these:

```json
{
  "scripts": {
    "lint": "eslint .",
    "test": "jest --runInBand",
    "test:integration": "jest --runInBand tests/integration",
    "start:test": "node src/index.js"
  }
}
```

## Part C — Frontend `package.json` scripts expected by Pipeline 1
```json
{
  "scripts": {
    "lint": "eslint .",
    "test": "vitest run"
  }
}
```

## Part D — What Pipeline 1 does
1. Starts a **temporary PostgreSQL service container** inside the GitHub runner.
2. Installs backend and frontend dependencies.
3. Runs backend lint and unit tests.
4. Starts the backend on a local CI port.
5. Waits for `/api/health` to respond.
6. Runs backend integration/API tests against that temporary CI setup.
7. Runs frontend lint and unit tests.
8. Builds backend and frontend Docker images only to validate the Dockerfiles.

## Part E — Why the CI database variables are named `TEST_*`
The workflow-level values are named `TEST_DB_*` and `TEST_DATABASE_URL` to show that they belong to the temporary CI test database, not to staging or production.

## Part F — What Pipeline 2 does
1. Runs on push to `staging`.
2. Generates a unique build tag.
3. Builds backend and frontend images.
4. Pushes them to GHCR.
5. Uses SSH to execute `scripts/staging-deploy.sh` on the staging target.
6. Performs a smoke test against the live staging backend.
7. Leaves a placeholder step where you can add UI tests against the live staging environment.

## Part G — First safe tests to run
### Test Pipeline 1
1. Create a small change on `development`.
2. Open a PR from `development` to `staging`.
3. Watch **Pipeline 1 - CI Validation** in the **Actions** tab.
4. Verify lint, tests, health check, and Docker build validation all pass.

### Test Pipeline 2
1. Merge the PR into `staging`.
2. Watch **Pipeline 2 - Staging Deploy**.
3. Confirm a build tag was generated.
4. Confirm both images were pushed to GHCR.
5. Confirm the staging smoke test succeeded.


## Important implementation update

This pack was later aligned to the confirmed project state:

- real monorepo paths are `apps/backend` and `apps/frontend`
- backend scripts available are only `start` and `test`
- frontend scripts available are `lint`, `test`, `build`, and `preview`
- no real Prisma migration script currently exists in the backend package
- staging deploy writes the release tag into `/home/deploy/myproject/app/env/app.env` and then runs Docker Compose from `/home/deploy/myproject/app/docker-compose.yml`

Because of that, Pipeline 1 validates the backend through real tests plus live endpoint checks instead of inventing backend lint or migration steps.
