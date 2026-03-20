# Pipeline 3 — Production Blue/Green Deployment — exam companion

This companion explains the manual production blue/green workflow in exam language. Each explanation includes the line interval, a strong color marker, what the code does, why the design choice was made, and how you can justify the choice during an exam defense.

> This workflow consumes artifacts already built by Pipeline 2. That means production receives the exact image tag that passed staging, rather than a fresh rebuild that could drift.

> Blue/green deployment reduces production risk because traffic is switched only after the new target environment is already deployed and validated.

## How to explain this pipeline in an exam

> Pipeline 3 is the controlled production release workflow. It is started manually with a previously built release tag, detects the currently inactive color, deploys that exact tagged artifact to the idle environment, runs smoke tests, switches proxy traffic only if the idle environment is healthy, and then monitors a rollback window.

## Section-by-section explanation

### [1-2] Red marker — Workflow Identity

```yaml
  1  name: Pipeline 3 - Production Blue Green
  2  
```

**What it does:** Defines the production deployment workflow name.


**Why it is written this way:** A specific title makes it obvious that this workflow is different from validation and staging and should be treated with greater care.

### [3-9] Orange marker — Manual Trigger and Release Input

```yaml
  3  on:
  4    workflow_dispatch:
  5      inputs:
  6        release_tag:
  7          description: 'Tag built by Pipeline 2, for example build-20260317-14'
  8          required: true
  9          type: string
```

**What it does:** Allows only workflow_dispatch and requires the operator to provide a release tag produced by Pipeline 2.


**Why it is written this way:** This enforces controlled production releases and ties production to a known validated artifact instead of rebuilding ad hoc.

### [11-12] Yellow marker — Minimum Permissions

```yaml
 11  permissions:
 12    contents: read
```

**What it does:** Requests read access to repository contents.


**Why it is written this way:** The workflow mainly uses repository scripts and environment secrets. It does not need package push or PR comment permissions.

### [14-17] Green marker — Production Job and Environment Binding

```yaml
 14  jobs:
 15    deploy-production:
 16      runs-on: ubuntu-latest
 17      environment: production
```

**What it does:** Declares the production deployment job on a GitHub-hosted runner and binds it to the production environment.


**Why it is written this way:** Using a production environment allows secrets and optional approvals to be scoped specifically to production.

### [19-21] Cyan marker — Repository Checkout

```yaml
 19      steps:
 20        - name: Check out repository tools
 21          uses: actions/checkout@v4
```

**What it does:** Retrieves the helper scripts stored in the repository.


**Why it is written this way:** This workflow uses repository-managed deployment scripts so the deployment logic remains version controlled and auditable.

### [23-33] Blue marker — SSH Preparation and Known Hosts

```yaml
 23        - name: Prepare SSH key for proxy
 24          env:
 25            PROXY_SSH_KEY: ${{ secrets.PROXY_SSH_KEY }}
 26          run: |
 27            mkdir -p ~/.ssh
 28            printf '%s
 29  ' "$PROXY_SSH_KEY" > ~/.ssh/id_ed25519
 30            chmod 600 ~/.ssh/id_ed25519
 31            ssh-keyscan -H "${{ secrets.PROXY_SSH_HOST }}" >> ~/.ssh/known_hosts
 32            ssh-keyscan -H "${{ secrets.APP_BLUE_SSH_HOST }}" >> ~/.ssh/known_hosts
 33            ssh-keyscan -H "${{ secrets.APP_GREEN_SSH_HOST }}" >> ~/.ssh/known_hosts
```

**What it does:** Writes the proxy SSH key to disk, secures its permissions, and preloads host keys for proxy, blue, and green hosts.


**Why it is written this way:** Non-interactive automation needs trusted SSH connectivity. Preloading known_hosts prevents interactive host verification prompts from breaking the workflow.

### [35-44] Indigo marker — Inactive Color Detection

```yaml
 35        - name: Detect inactive color
 36          id: detect
 37          env:
 38            PROXY_SSH_HOST: ${{ secrets.PROXY_SSH_HOST }}
 39            PROXY_SSH_USER: ${{ secrets.PROXY_SSH_USER }}
 40          run: |
 41            ACTIVE=$(ssh ${PROXY_SSH_USER}@${PROXY_SSH_HOST} "bash /opt/remote-print/bin/get-active-color.sh")
 42            if [ "$ACTIVE" = "blue" ]; then TARGET=green; else TARGET=blue; fi
 43            echo "active=$ACTIVE" >> "$GITHUB_OUTPUT"
 44            echo "target=$TARGET" >> "$GITHUB_OUTPUT"
```

**What it does:** SSHes into the proxy host, reads which color is currently active, and computes the idle target color as workflow output.


**Why it is written this way:** This step is fundamental to blue/green logic: deploy to the environment that is not currently serving users.

### [46-56] Purple marker — Deploy Tagged Release to Idle Environment

```yaml
 46        - name: Deploy selected release to idle environment
 47          env:
 48            TARGET_COLOR: ${{ steps.detect.outputs.target }}
 49            RELEASE_TAG: ${{ inputs.release_tag }}
 50            APP_BLUE_SSH_HOST: ${{ secrets.APP_BLUE_SSH_HOST }}
 51            APP_BLUE_SSH_USER: ${{ secrets.APP_BLUE_SSH_USER }}
 52            APP_GREEN_SSH_HOST: ${{ secrets.APP_GREEN_SSH_HOST }}
 53            APP_GREEN_SSH_USER: ${{ secrets.APP_GREEN_SSH_USER }}
 54            GHCR_USERNAME: ${{ github.actor }}
 55            GHCR_TOKEN: ${{ secrets.GITHUB_TOKEN }}
 56          run: bash scripts/deploy-target.sh
```

**What it does:** Passes the target color, selected release tag, app host details, and registry credentials to a deployment script.


**Why it is written this way:** The deployment is parameterized so the same script can handle both blue and green. Using the release tag ensures production gets the exact artifact tested in staging.

### [58-65] Magenta marker — Remote Smoke Tests on Idle Environment

```yaml
 58        - name: Run remote smoke tests on idle environment
 59          env:
 60            TARGET_COLOR: ${{ steps.detect.outputs.target }}
 61            APP_BLUE_SSH_HOST: ${{ secrets.APP_BLUE_SSH_HOST }}
 62            APP_BLUE_SSH_USER: ${{ secrets.APP_BLUE_SSH_USER }}
 63            APP_GREEN_SSH_HOST: ${{ secrets.APP_GREEN_SSH_HOST }}
 64            APP_GREEN_SSH_USER: ${{ secrets.APP_GREEN_SSH_USER }}
 65          run: bash scripts/remote-healthcheck.sh
```

**What it does:** Runs health checks against the newly deployed idle environment before any traffic switch occurs.


**Why it is written this way:** This is the safety barrier of blue/green deployment. Traffic is switched only after the candidate environment proves it is healthy.

### [67-72] Teal marker — Proxy Switch

```yaml
 67        - name: Switch proxy to new environment
 68          env:
 69            TARGET_COLOR: ${{ steps.detect.outputs.target }}
 70            PROXY_SSH_HOST: ${{ secrets.PROXY_SSH_HOST }}
 71            PROXY_SSH_USER: ${{ secrets.PROXY_SSH_USER }}
 72          run: bash scripts/switch-proxy.sh
```

**What it does:** Calls the script that updates the proxy to send production traffic to the newly validated target color.


**Why it is written this way:** Separating the switch into its own step makes the change auditable and keeps a clear boundary between deploy and go-live.

### [74-82] Lime marker — Rollback Monitoring Window

```yaml
 74        - name: Monitor for rollback window
 75          env:
 76            TARGET_COLOR: ${{ steps.detect.outputs.target }}
 77            PREVIOUS_COLOR: ${{ steps.detect.outputs.active }}
 78            PROXY_SSH_HOST: ${{ secrets.PROXY_SSH_HOST }}
 79            PROXY_SSH_USER: ${{ secrets.PROXY_SSH_USER }}
 80            PUBLIC_FRONTEND_URL: ${{ secrets.PUBLIC_FRONTEND_URL }}
 81            PUBLIC_BACKEND_HEALTH_URL: ${{ secrets.PUBLIC_BACKEND_HEALTH_URL }}
 82          run: bash scripts/monitor-rollback.sh
```

**What it does:** Monitors the new live environment for a defined window and uses the previous color if rollback becomes necessary.


**Why it is written this way:** A safe release process should not assume success immediately after cutover. Monitoring after the switch addresses failures that appear only under real load or integration conditions.


## Typical exam questions and concise answers

### Why is Pipeline 3 manual?
Because production release is a higher-risk operation than CI or staging. A manual gate gives the release manager explicit control over when traffic is switched.

### Why detect the inactive color first?
Because blue/green deployment depends on updating the idle environment while the active environment continues serving traffic. Only after the idle side is healthy should traffic be switched.

### Why keep a rollback window after switching?
Because some failures appear only under real user traffic. A post-switch monitoring period lets the workflow automatically revert to the previous stable color if the new release behaves badly.
