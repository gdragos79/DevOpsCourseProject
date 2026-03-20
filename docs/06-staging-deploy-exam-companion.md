# Pipeline 2 — Staging Deployment — exam companion

This companion explains the staging deployment workflow in exam language. For each code section it shows the line interval, a strong color marker, what the section does, why it exists, and how it supports the corrected three-pipeline architecture.

> This pipeline uses GitHub-hosted compute for building and pushing images, then uses SSH only for the remote deployment step. That keeps build tooling centralized while still testing a real remote environment.

> The staging target is intentionally separate from the production traffic switch. It validates the release candidate in a live environment before any blue/green production cutover is attempted.

## How to explain this pipeline in an exam

> Pipeline 2 runs after code reaches the staging branch. It creates a unique build tag, builds frontend and backend images, pushes them to GHCR, deploys the tagged release to a live staging target over SSH, and then verifies staging with health and follow-up tests.

## Section-by-section explanation

### [1-2] Red marker — Workflow Identity

```yaml
  1  name: Pipeline 2 - Staging Deploy
  2  
```

**What it does:** Defines the workflow name shown in GitHub Actions.


**Why it is written this way:** A descriptive title helps separate the release-validation stage from the earlier PR validation stage.

### [3-7] Orange marker — Trigger Rules

```yaml
  3  on:
  4    push:
  5      branches:
  6        - staging
  7    workflow_dispatch:
```

**What it does:** Runs automatically on pushes to staging and can also be started manually.


**Why it is written this way:** This fits the corrected branch model: once validated code reaches staging, the system should build, publish, and deploy it for release-candidate testing.

### [9-11] Yellow marker — Package Publishing Permissions

```yaml
  9  permissions:
 10    contents: read
 11    packages: write
```

**What it does:** Requests read access to repository contents and write access to packages.


**Why it is written this way:** This workflow needs package write permission because it pushes Docker images to GHCR. It does not ask for broader repository permissions than necessary.

### [13-18] Green marker — Global Image and Health Settings

```yaml
 13  env:
 14    REGISTRY: ghcr.io
 15    OWNER_LC: ${{ github.repository_owner }}
 16    BACKEND_IMAGE: devopscourseproject-backend
 17    FRONTEND_IMAGE: devopscourseproject-frontend
 18    STAGING_BACKEND_HEALTH_PATH: /api/health
```

**What it does:** Defines the registry, image names, owner, and staging backend health path.


**Why it is written this way:** These are pipeline configuration values, not secrets. Keeping them together makes image tagging and later deployment steps consistent and easier to maintain.

### [20-23] Cyan marker — Job and Environment Binding

```yaml
 20  jobs:
 21    build-push-deploy:
 22      runs-on: ubuntu-latest
 23      environment: staging
```

**What it does:** Defines one staging deployment job that runs on ubuntu-latest and is attached to the staging GitHub Environment.


**Why it is written this way:** Binding the job to the staging environment is useful because environment-level secrets and future protection rules can be scoped specifically to staging.

### [25-27] Blue marker — Repository Checkout

```yaml
 25      steps:
 26        - name: Check out staging code
 27          uses: actions/checkout@v4
```

**What it does:** Downloads the staging branch code for the build.


**Why it is written this way:** The workflow needs the application source and Dockerfiles to build the release images.

### [29-31] Indigo marker — Unique Build Tag Generation

```yaml
 29        - name: Build number
 30          id: meta
 31          run: echo "build_tag=build-$(date +%Y%m%d)-${GITHUB_RUN_NUMBER}" >> "$GITHUB_OUTPUT"
```

**What it does:** Creates a unique build tag combining the date and GitHub run number and stores it as step output.


**Why it is written this way:** A unique tag is essential for traceability. It lets you explain exactly which build was tested in staging and later promoted to production.

### [33-38] Purple marker — GHCR Authentication

```yaml
 33        - name: Log in to GHCR
 34          uses: docker/login-action@v3
 35          with:
 36            registry: ghcr.io
 37            username: ${{ github.actor }}
 38            password: ${{ secrets.GITHUB_TOKEN }}
```

**What it does:** Logs into GitHub Container Registry using the current GitHub actor and the built-in token.


**Why it is written this way:** Registry login is required before pushing images. Using GITHUB_TOKEN avoids managing a separate long-lived package password in many repository setups.

### [40-48] Magenta marker — Build and Push Backend and Frontend Images

```yaml
 40        - name: Build and push backend image
 41          run: |
 42            docker build -t ghcr.io/${OWNER_LC,,}/${BACKEND_IMAGE}:${{ steps.meta.outputs.build_tag }} ./backend
 43            docker push ghcr.io/${OWNER_LC,,}/${BACKEND_IMAGE}:${{ steps.meta.outputs.build_tag }}
 44  
 45        - name: Build and push frontend image
 46          run: |
 47            docker build -t ghcr.io/${OWNER_LC,,}/${FRONTEND_IMAGE}:${{ steps.meta.outputs.build_tag }} ./frontend
 48            docker push ghcr.io/${OWNER_LC,,}/${FRONTEND_IMAGE}:${{ steps.meta.outputs.build_tag }}
```

**What it does:** Builds the two Docker images and pushes them to GHCR using the unique build tag.


**Why it is written this way:** The workflow publishes immutable artifacts that can be referenced later by exact tag. This separates build from deploy and improves release reproducibility.

### [50-63] Teal marker — Remote Staging Deployment over SSH

```yaml
 50        - name: Deploy to staging target over SSH
 51          env:
 52            APP_SSH_HOST: ${{ secrets.STAGING_SSH_HOST }}
 53            APP_SSH_USER: ${{ secrets.STAGING_SSH_USER }}
 54            APP_SSH_KEY: ${{ secrets.STAGING_SSH_KEY }}
 55            BUILD_TAG: ${{ steps.meta.outputs.build_tag }}
 56          run: |
 57            mkdir -p ~/.ssh
 58            printf '%s
 59  ' "$APP_SSH_KEY" > ~/.ssh/id_ed25519
 60            chmod 600 ~/.ssh/id_ed25519
 61            ssh-keyscan -H "$APP_SSH_HOST" >> ~/.ssh/known_hosts
 62            scp scripts/staging-deploy.sh ${APP_SSH_USER}@${APP_SSH_HOST}:/tmp/staging-deploy.sh
 63            ssh ${APP_SSH_USER}@${APP_SSH_HOST} "chmod +x /tmp/staging-deploy.sh && BUILD_TAG='$BUILD_TAG' bash /tmp/staging-deploy.sh"
```

**What it does:** Creates an SSH key file on the runner, trusts the remote host key, copies the staging deployment script to the target, and runs it remotely with the build tag.


**Why it is written this way:** This is the bridge between CI/CD orchestration and the real staging host. SSH keeps the remote procedure explicit and understandable, which is useful in an exam setting.

### [65-68] Lime marker — Staging Backend Smoke Test

```yaml
 65        - name: Staging backend smoke test
 66          env:
 67            STAGING_BACKEND_URL: ${{ secrets.STAGING_BACKEND_URL }}
 68          run: curl -fsS "${STAGING_BACKEND_URL}${STAGING_BACKEND_HEALTH_PATH}"
```

**What it does:** Calls the staging backend health endpoint after deployment.


**Why it is written this way:** A deployment is not considered successful merely because the SSH command finished. The health check verifies that the deployed service is actually responding.

### [70-71] Chartreuse marker — Follow-up UI and API Test Placeholder

```yaml
 70        - name: Staging UI/API follow-up tests
 71          run: echo "Replace this placeholder with Playwright/UI and extra API tests against live staging."
```

**What it does:** Marks the place where live UI tests and deeper API checks against staging should be added.


**Why it is written this way:** The revised requirements expect live staging validation. Keeping an explicit placeholder is better than pretending the workflow is finished when the project-specific tests are not yet wired.


## Typical exam questions and concise answers

### Why build the images in Pipeline 2 and not again in Pipeline 3?
Because promoting by image tag is stronger DevOps practice than rebuilding the same code later. It guarantees production receives the exact artifact already validated in staging.

### Why use GHCR?
Because the revised project brief expects images to be pushed to GitHub Packages or GHCR, and GHCR integrates naturally with GitHub Actions and repository permissions.

### Why deploy to staging over SSH?
Because staging needs to be a real environment, not just a local runner simulation. SSH lets the workflow update a remote host while still keeping the orchestration simple for a student project.
