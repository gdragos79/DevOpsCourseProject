# Document 3 — Pipeline 1 and Pipeline 2 hand-held implementation

## Part A — Files you must copy
Copy these files into your monorepo:
- `.github/workflows/00-pr-development.yml`
- `.github/workflows/01-ci-validation.yml`
- `.github/workflows/02-staging-deploy.yml`
- `scripts/staging-deploy.sh`
- `.env.secrets.example`
- `apps/frontend/.eslintrc.cjs`
- `apps/frontend/src/smoke.test.jsx`

## Part B — Why there are now two PR validation workflows
Your repository now uses two PR validation layers:

1. `00-pr-development.yml` for pull requests into `development`
2. `01-ci-validation.yml` for pull requests into `staging`

This matches the recommended promotion model:
- feature work is checked before entering `development`
- stronger promotion checks run before code enters `staging`
- deployment still happens only after a push to `staging`

## Part C — What the development PR validation does
The development PR workflow is intentionally faster and lighter. It runs:
- backend tests
- frontend lint
- frontend tests
- frontend build

It does **not** start the backend service, use a CI database, or validate Docker builds. The purpose is to protect `development` without paying the cost of a full promotion-style validation on every feature PR.

## Part D — What Pipeline 1 does for PRs into `staging`
Pipeline 1 remains the stronger validation gate and runs:
1. a temporary PostgreSQL service container inside GitHub Actions
2. backend dependency install
3. frontend dependency install
4. backend tests
5. backend startup on the CI runner
6. live `/api/health` verification
7. live `/api/db` verification
8. frontend lint
9. frontend tests
10. backend Docker build validation
11. frontend Docker build validation

## Part E — Why the CI database variables are named `TEST_*`
The workflow-level values are named `TEST_DB_*` and `TEST_DATABASE_URL` to show that they belong to the temporary CI database used only inside the runner. They are not staging or production secrets.

## Part F — Why the frontend got an ESLint config and a smoke test
Two fixes were needed to make CI validation actually runnable:
- `apps/frontend/.eslintrc.cjs` because the repo had a lint script but no ESLint config file
- `apps/frontend/src/smoke.test.jsx` because the repo had a Vitest test script but no test files

The smoke test is not pretending to be full frontend coverage. Its role is to prove that the frontend test stage is wired correctly and can be extended later with real component or UI tests.

## Part G — What Pipeline 2 does
1. Runs on push to `staging`.
2. Generates a unique build tag.
3. Builds backend and frontend images.
4. Pushes them to GHCR.
5. Uses SSH to execute `scripts/staging-deploy.sh` on the staging target.
6. Performs smoke tests against the live staging backend and frontend.

## Part H — First safe tests to run
### Test development PR validation
1. Create a small change on a feature branch.
2. Open a PR from your feature branch into `development`.
3. Watch **Development PR Validation** in the **Actions** tab.
4. Confirm backend tests, frontend lint, frontend tests, and frontend build pass.

### Test Pipeline 1
1. Merge the feature PR into `development`.
2. Open a PR from `development` to `staging`.
3. Watch **Pipeline 1 - CI Validation** in the **Actions** tab.
4. Confirm database startup, backend health checks, frontend checks, and Docker build validation all pass.

### Test Pipeline 2
1. Merge the PR into `staging`.
2. Watch **Pipeline 2 - Staging Deploy**.
3. Confirm a build tag was generated.
4. Confirm both images were pushed to GHCR.
5. Confirm the staging smoke tests succeeded.
