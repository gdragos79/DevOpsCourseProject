# Document 13 — Two-layer PR validation update

## Why this update was needed
With only one PR validation workflow targeting `staging`, code could enter `development` from feature branches without any CI gate. That left an important gap in the branch protection model.

## Updated model
The pack now uses two PR validation workflows:

### Workflow A — Development PR Validation
- File: `.github/workflows/00-pr-development.yml`
- Trigger: pull request into `development`
- Purpose: fast developer protection
- Checks:
  - backend tests
  - frontend lint
  - frontend tests
  - frontend build

### Workflow B — Pipeline 1 - CI Validation
- File: `.github/workflows/01-ci-validation.yml`
- Trigger: pull request into `staging`
- Purpose: stronger promotion gate before release-candidate branch
- Checks:
  - temporary PostgreSQL service container
  - backend tests
  - backend startup and live `/api/health`
  - backend `/api/db`
  - frontend lint
  - frontend tests
  - backend Docker build validation
  - frontend Docker build validation

### Workflow C — Pipeline 2 - Staging Deploy
- File: `.github/workflows/02-staging-deploy.yml`
- Trigger: push to `staging`
- Purpose: build, push, deploy, and smoke-test the live staging environment

### Workflow D — Pipeline 3 - Production Blue Green
- File: `.github/workflows/03-production-bluegreen.yml`
- Trigger: manual
- Purpose: deploy an already-built release tag to the idle production color and switch proxy traffic

## Why running validations twice is acceptable
This is not waste. It is a branch-promotion strategy:
- fast checks protect `development`
- stronger checks protect `staging`

The mature question is not “How do I avoid running twice at all costs?” but “Which checks should run at each promotion stage?”

## Branch protection recommendation
Require these checks:

### On `development`
Require:
- `Fast PR checks for development`

### On `staging`
Require:
- `Frontend lint and tests, backend tests, health verification, Docker build validation`

That gives you both early protection and stronger release promotion checks.
