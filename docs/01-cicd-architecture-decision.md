# Document 1 — CI/CD architecture decision

## 1. Why the pipeline model changed
The revised brief defines **three distinct automated workflows**: Pipeline 1 for continuous integration, Pipeline 2 for staging deployment, and Pipeline 3 for manual blue/green production deployment. Monitoring and self-healing are explicitly optional and therefore are not treated as part of the first required implementation pack.

## 2. Branch roles in this repository
This pack assumes the following practical branch model:

- `development` = daily work branch
- `staging` = release branch used for pre-production validation and staging deployment
- `production` = release-approved branch representing production state

`main` is not used in the active promotion path because your current repo model already revolves around `development`, `staging`, and `production`.

## 3. Mapping the revised requirements to your repo
### Pipeline 1
- Trigger: Pull Request from `development` to `staging`
- Purpose: lint frontend/backend, run unit tests, run backend API tests, and block merge if checks fail

### Pipeline 2
- Trigger: push to `staging`
- Purpose: build Docker images, tag them with a unique build number, push to GHCR, deploy to a live staging target, and test that target

### Pipeline 3
- Trigger: manual `workflow_dispatch`
- Purpose: identify the idle color, deploy the selected tag there, run smoke tests, switch Nginx traffic, then monitor for rollback

## 4. Why images are built in Pipeline 2 and reused in Pipeline 3
This pack uses a stronger delivery model than rebuilding at production time. The staging pipeline builds and publishes a single versioned artifact. The production pipeline then deploys that exact artifact by tag.

## 5. Where monitoring fits later
Monitoring is postponed for now because the revised brief marks it optional. It can later be implemented with GitHub Actions, Prometheus/Grafana, or a VM-resident health loop.
