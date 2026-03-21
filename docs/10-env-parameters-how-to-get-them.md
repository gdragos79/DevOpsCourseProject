# `.env.secrets.example` Parameter Guide

This document explains how to obtain each parameter from `.env.secrets.example`, where it is used in the CI/CD pipeline, and why it should be stored as a GitHub secret rather than written in plain text.

## General rule

- Hostnames, usernames, private keys, and public URLs that belong to real environments should be treated as deployment configuration and stored in GitHub Secrets or GitHub Environment Secrets.
- CI-only temporary values used inside a local service container are a different category and can stay in workflow code if they are clearly marked as test-only.

## Parameters

## STAGING_SSH_HOST

**What it is:** The IP address or DNS name of the server that will host the live staging deployment.

**How to get it:** Get it from the VM provider panel, from `hostname -I` on the staging VM, or from your infrastructure notes. If you use the inactive blue/green VM as staging, this value is the host you chose for that purpose.

**Where it is used:** Pipeline 2 uses it to copy and execute `scripts/staging-deploy.sh` over SSH.

## STAGING_SSH_USER

**What it is:** The Linux user used by GitHub Actions to connect to the staging server.

**How to get it:** Get it from the user you created for deployments on the staging server, often `deploy` or a dedicated automation user. Confirm it with `whoami` after SSH login or by checking `/etc/passwd`.

**Where it is used:** Pipeline 2 uses it together with `STAGING_SSH_HOST` and `STAGING_SSH_KEY`.

## STAGING_SSH_KEY

**What it is:** The private SSH key corresponding to the public key installed in the staging server user's `~/.ssh/authorized_keys` file.

**How to get it:** Generate it with `ssh-keygen`, keep the private key locally, and place the public key on the staging host. The value stored in GitHub must be the full private key block, including the BEGIN/END lines.

**Where it is used:** Pipeline 2 writes this key into `~/.ssh/id_ed25519` on the runner before SSH and SCP.

## STAGING_BACKEND_URL

**What it is:** The full base URL of the staging backend used for post-deployment smoke tests, for example `http://<host>:3001` or `https://staging.example.com`.

**How to get it:** Get it from your staging routing design. If the backend is exposed directly on a non-production port, use that exact reachable URL. Confirm it manually with `curl <url>/api/health`.

**Where it is used:** Pipeline 2 appends `/api/health` and tests the staging backend after deployment.

## APP_BLUE_SSH_HOST

**What it is:** The IP or DNS name of the blue application VM.

**How to get it:** Get it from your cloud/VM panel, Tailscale, or the VM itself with `hostname -I`.

**Where it is used:** Pipeline 3 uses it when the selected target color is blue.

## APP_BLUE_SSH_USER

**What it is:** The deployment user on the blue VM.

**How to get it:** Use the Linux account dedicated to deployment, such as `deploy`. Verify by logging in manually over SSH.

**Where it is used:** Pipeline 3 and helper scripts use it to connect to blue.

## APP_BLUE_SSH_KEY

**What it is:** The private SSH key for the deployment user on the blue VM.

**How to get it:** Create or reuse a deployment key pair. Store the private key in GitHub Secrets and the matching public key in `authorized_keys` on the blue VM.

**Where it is used:** Used by Pipeline 3 when deploying or smoke-testing blue.

## APP_GREEN_SSH_HOST

**What it is:** The IP or DNS name of the green application VM.

**How to get it:** Get it from the VM provider, Tailscale, or `hostname -I` on the green VM.

**Where it is used:** Pipeline 3 uses it when the selected target color is green.

## APP_GREEN_SSH_USER

**What it is:** The deployment user on the green VM.

**How to get it:** Use the Linux deployment account on green and verify it manually with SSH.

**Where it is used:** Used by Pipeline 3 and scripts when green is the target.

## APP_GREEN_SSH_KEY

**What it is:** The private SSH key for the deployment user on the green VM.

**How to get it:** Same method as blue: generate or reuse a key pair, install the public key on the VM, and store the private key in GitHub Secrets.

**Where it is used:** Required when Pipeline 3 targets green.

## PROXY_SSH_HOST

**What it is:** The IP or DNS name of the proxy VM that runs Nginx and controls which color is live.

**How to get it:** Get it from the VM provider panel or from the proxy VM itself.

**Where it is used:** Pipeline 3 uses it to detect the active color and to switch traffic.

## PROXY_SSH_USER

**What it is:** The deployment or admin user on the proxy VM.

**How to get it:** Use the user that is allowed to execute the helper scripts and reload Nginx. It may be `deploy` if sudo is configured, or another automation user.

**Where it is used:** Used by `switch-proxy.sh` and the active-color detection step.

## PROXY_SSH_KEY

**What it is:** The private SSH key for the proxy deployment user.

**How to get it:** Generate or reuse a key pair and install the public key on the proxy VM. Store the private key in GitHub Secrets.

**Where it is used:** Pipeline 3 prepares this key first because the proxy participates in detection, switching, and rollback.

## PUBLIC_FRONTEND_URL

**What it is:** The public URL that real users open after the proxy switch, for example `https://app.example.com`.

**How to get it:** Get it from the domain or IP exposed by the proxy. Verify manually in a browser and with `curl`.

**Where it is used:** Used during the rollback window to confirm the public frontend remains healthy.

## PUBLIC_BACKEND_HEALTH_URL

**What it is:** The public backend health endpoint used after the proxy switch, for example `https://app.example.com/api/health`.

**How to get it:** Construct it from the public base URL plus the backend health path. Verify it manually with `curl -fsS` before trusting it in automation.

**Where it is used:** Used by `monitor-rollback.sh` to decide whether rollback is required.

## Good practice notes

1. **Never commit real values** for these parameters into Git.
2. **Prefer GitHub Environment Secrets** for staging and production so the two environments are clearly separated.
3. **Test each SSH value manually** from your machine before adding it to GitHub. If manual SSH fails, the workflow will also fail.
4. **Test each URL manually with `curl`** before using it in smoke tests or rollback monitoring.

## How I would justify this in an exam

> 'I separated real deployment values into secrets because they belong to live infrastructure. The workflows contain only non-secret pipeline structure and CI-only test values. This reduces accidental disclosure and makes the deployment stages easier to audit.'