# GitHub Self-Hosted Runners and Private VM Orchestration — Detailed Guide

## Goal

This guide generalizes the earlier staging-only runner document into a broader guide for your project’s private VM environment.

It explains:

- how to install a repository-level self-hosted GitHub Actions runner on any project VM
- how to adapt the installation depending on the VM role
- how the staging runner differs from the proxy/production runner
- how to configure passwordless SSH from the Proxy VM to Blue and Green
- how to make SSH usage easier for scripts by adding entries to `~/.ssh/config`

This guide is based on the earlier staging runner guide, which already established the core installation flow, the recommendation to install runners only after the VM works manually, and the use of project-specific runner names and labels such as `runner-aplicatie-staging` with label `staging` and `runner-prx-proxy` with label `proxy`. It also builds on your patched deployment guide, which already describes the proxy role, the optional proxy runner, and the root-owned cutover helper. fileciteturn18file0 fileciteturn18file8

---

## 1. Why this guide exists

The original runner guide was specifically written for VM Aplicatie (Staging) and used:

- runner name: `runner-aplicatie-staging`
- label: `staging` fileciteturn18file0

Later, your project evolved so that:

- Pipeline 2 should run on the staging VM using a self-hosted runner
- Pipeline 3 should run on the Proxy VM using a self-hosted runner
- the Proxy VM must orchestrate Blue/Green deployment by reaching VM Albastru and VM Verde over SSH

That means a more general guide is now useful.

---

## 2. What a self-hosted runner is

A self-hosted runner is a GitHub Actions agent installed on one of your own machines. It connects outward to GitHub and waits for jobs. When a workflow targets that runner, the job is executed on that machine instead of on GitHub’s cloud runner.

The original staging runner guide already described this model and showed a workflow target such as:

```yaml
runs-on: [self-hosted, linux, x64, staging]
```

where:

- `self-hosted` means your own runner
- `linux` means the runner must be Linux
- `x64` means the runner must be x64 architecture
- `staging` is your custom label fileciteturn18file0

For your project, the same principle applies to the proxy runner.

---

## 3. Important prerequisite

Install any runner only after the VM already works manually in its intended role.

This was already a key rule in the original staging guide: if the VM does not already work manually, then when a workflow fails you will not know whether the problem is the application, the VM setup, Docker permissions, the runner, or the workflow YAML. fileciteturn18file0

### In your project, that means:

#### Before a staging runner
The staging app VM should already:
- run the application manually
- pull GHCR images
- start frontend and backend
- answer local health checks on `http://localhost/` and `http://localhost:3000/api/health` fileciteturn18file7

#### Before a proxy runner
The Proxy VM should already:
- run nginx correctly
- have working `blue.conf`, `green.conf`, and `active.conf`
- proxy traffic correctly to Blue or Green
- have the root-owned cutover helper `/usr/local/bin/myproject-switch-proxy`
- have the limited sudo authorization for `deploy` to run only that helper
- be able to reach Blue and Green over SSH without a password

---

## 4. Recommended user

Install the runner as `deploy`, not as `root`.

This was already the recommendation in the staging guide and it remains correct for all your VMs because:

- it matches the deployment context
- it keeps automation separate from your personal account
- it avoids ownership confusion
- it is cleaner for CI/CD fileciteturn18file0

---

## 5. General folder layout for runners

Keep runner files separate from application files.

Recommended structure:

```text
/home/deploy/actions-runner
/home/deploy/myproject/app
/home/deploy/myproject/db
```

This follows the earlier recommendation not to mix runner files with app files. fileciteturn18file3

---

## 6. Common installation procedure for any VM runner

The basic procedure is the same whether the runner is installed on:

- VM Aplicatie (staging)
- VM Prx (proxy / production orchestration)
- optionally later VM Albastru
- optionally later VM Verde

### Step 1 — Preliminary checks
Log in as `deploy` and run:

```bash
whoami
hostname
pwd
docker --version
docker compose version
systemctl --version
id
groups
docker ps
```

The original guide already used these checks to confirm:

- the current user is `deploy`
- you are on the correct VM
- Docker works
- Docker Compose works
- systemd is available
- the runner user can use Docker if workflows need Docker fileciteturn18file0

### Step 2 — Prepare runner directory

```bash
mkdir -p ~/actions-runner
cd ~/actions-runner
pwd
```

Expected:

```text
/home/deploy/actions-runner
```

The earlier guide already used this dedicated folder approach. fileciteturn18file0

### Step 3 — Open GitHub runner page

In GitHub:

1. Open the repository
2. Go to **Settings**
3. Go to **Actions**
4. Go to **Runners**
5. Click **New self-hosted runner**
6. Choose:
   - **Linux**
   - **x64**

GitHub will show:
- download commands
- extraction commands
- `config.sh` registration command
- service commands

This process is the same as in the original staging document. fileciteturn18file0

### Step 4 — Download and extract runner
Use the exact GitHub-provided commands shown on the page. The original document already stressed that you should use GitHub’s current version and token rather than copying an old version manually. fileciteturn18file2

They will look similar to:

```bash
curl -o actions-runner-linux-x64-<VERSION>.tar.gz -L <github-provided-download-url>
tar xzf ./actions-runner-linux-x64-<VERSION>.tar.gz
```

### Step 5 — Configure the runner
Again, use GitHub’s provided `./config.sh` command, but set the correct project-specific name and labels.

### Step 6 — Test manually

```bash
./run.sh
```

Then check GitHub → **Settings → Actions → Runners** and confirm the runner appears as **Idle** or **Online**. The staging guide already used this exact manual validation before service installation. fileciteturn18file1

Stop the manual runner with:

```bash
Ctrl+C
```

### Step 7 — Install as service

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
systemctl status actions.runner.* --no-pager
```

The original guide already explained why this is important: `./run.sh` in a terminal is not enough because it stops on logout or reboot. fileciteturn18file2

---

## 7. Staging runner specifics

The earlier staging guide used:

- runner name: `runner-aplicatie-staging`
- label: `staging` fileciteturn18file0

A typical configuration command looks like:

```bash
./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPOSITORY --token YOUR_TEMP_RUNNER_TOKEN --name runner-aplicatie-staging --labels staging --work _work
```

### Recommended labels shown in GitHub
You should expect:
- `self-hosted`
- `Linux`
- `X64`
- `staging` fileciteturn18file2

### Purpose
The staging runner is meant to run Pipeline 2 locally on VM Aplicatie:
- local deploy
- local Docker Compose refresh
- local smoke tests

---

## 8. Proxy / production runner specifics

The scaffold guide already suggested, later, an optional proxy runner with:

- runner name: `runner-prx-proxy`
- label: `proxy` fileciteturn18file8

For your newer production pipeline design, I recommend adding an extra label:

- `production`

### Recommended runner name
`runner-prx-proxy`

### Recommended labels
`proxy,production`

### Why add `production`
Because Pipeline 3 is a production deployment orchestration job:
- detect active color
- deploy to idle color
- switch proxy
- monitor rollback window

### Example configuration command

```bash
./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPOSITORY --token YOUR_TEMP_RUNNER_TOKEN --name runner-prx-proxy --labels proxy,production --work _work
```

### Expected labels in GitHub
- `self-hosted`
- `Linux`
- `X64`
- `proxy`
- `production`

### Recommended `runs-on` target
For Pipeline 3:

```yaml
runs-on: [self-hosted, proxy]
```

or, if you want to be stricter:

```yaml
runs-on: [self-hosted, production, proxy]
```

---

## 9. Why the proxy runner is different from the staging runner

### Staging runner
The staging runner mostly works on the machine where the app itself runs.

It:
- pulls images
- runs local Docker Compose
- runs local smoke checks

### Proxy runner
The proxy runner is not primarily an app host. It is the orchestrator of Blue/Green production.

It:
- reads `/etc/nginx/upstreams/active.conf`
- decides which color is idle
- SSHes to Blue and Green
- deploys the selected release to the idle environment
- switches proxy traffic
- monitors rollback window

That is why the proxy runner has an extra prerequisite that the staging runner does not have:

the Proxy VM must be able to SSH to Blue and Green without a password.

---

## 10. Configure passwordless SSH from Proxy to Blue and Green

This part is now essential for your project’s Pipeline 3.

The goal is:

- `deploy` on Proxy VM can SSH to `deploy` on Blue VM without a password
- `deploy` on Proxy VM can SSH to `deploy` on Green VM without a password

### Why
Because Pipeline 3 now runs on the Proxy VM self-hosted runner and must orchestrate deployment remotely to Blue and Green.

### Step 1 — On Proxy VM, create a dedicated key pair as `deploy`

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_bluegreen_orchestrator -C "proxy-to-bluegreen"
```

When asked for passphrase:
- press **Enter**
- leave it empty
- press **Enter** again

This creates:
- `~/.ssh/id_ed25519_bluegreen_orchestrator`
- `~/.ssh/id_ed25519_bluegreen_orchestrator.pub`

### Step 2 — Display the public key

```bash
cat ~/.ssh/id_ed25519_bluegreen_orchestrator.pub
```

Copy the full output.

### Step 3 — Add the public key to Blue VM

On Blue VM, as `deploy`, ensure:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Open the file:

```bash
nano ~/.ssh/authorized_keys
```

Paste the Proxy VM public key on a new line.

Then:

```bash
chmod 600 ~/.ssh/authorized_keys
chown -R deploy:deploy ~/.ssh
```

### Step 4 — Add the same public key to Green VM

Repeat the same process on Green VM:
- paste the same public key into `~/.ssh/authorized_keys`
- set correct permissions

### Step 5 — Test from Proxy VM

```bash
ssh -i ~/.ssh/id_ed25519_bluegreen_orchestrator deploy@BLUE_IP
ssh -i ~/.ssh/id_ed25519_bluegreen_orchestrator deploy@GREEN_IP
```

Both should log in without prompting for a password.

---

## 11. Why `authorized_keys` can contain multiple keys

It is perfectly valid for `~/.ssh/authorized_keys` to contain multiple public keys.

Each key must be:
- on its own single line
- separated by a normal newline

This is useful in your project because the same `deploy` account may need to trust:
- your personal laptop key
- a CI/CD-specific key
- possibly other administrative keys

That is normal and does not require commas or semicolons.

---

## 12. Make SSH easier for scripts with `~/.ssh/config`

To make the Blue/Green orchestration scripts easier to read and maintain, create an SSH config file on the Proxy VM for the `deploy` user.

Create or edit:

```bash
nano ~/.ssh/config
```

Add:

```sshconfig
Host blue-vm
  HostName 192.168.238.149
  User deploy
  IdentityFile ~/.ssh/id_ed25519_bluegreen_orchestrator

Host green-vm
  HostName 192.168.238.150
  User deploy
  IdentityFile ~/.ssh/id_ed25519_bluegreen_orchestrator
```

Then secure it:

```bash
chmod 600 ~/.ssh/config
```

### Why this helps
Without an SSH config, scripts often need long commands like:

```bash
ssh -i ~/.ssh/id_ed25519_bluegreen_orchestrator deploy@192.168.238.149
```

With the config file, the same target can be reached more cleanly:

```bash
ssh blue-vm
ssh green-vm
```

That makes scripts:
- shorter
- easier to read
- less repetitive
- less error-prone

### Important note
If your scripts still use environment variables like `APP_BLUE_SSH_HOST`, you can either:
- keep those variables and continue using raw IPs
- or refactor the scripts later to call `ssh blue-vm` and `ssh green-vm`

For an exam, the config-file method is a nice improvement because it shows good operational hygiene.

---

## 13. Proxy-specific prerequisite: limited sudo helper for cutover

Your proxy-based production workflow also depends on the root-owned cutover helper:

`/usr/local/bin/myproject-switch-proxy`

and the limited sudo rule that allows `deploy` to run only that helper without a password.

The patched deployment guide already includes the root-owned helper design, its secure ownership and permissions, and the manual tests with `nginx -t` and local proxy health verification. fileciteturn18file8

### Why this matters
This is what allows Pipeline 3 to:
- switch from blue to green
- or green to blue
without granting `deploy` unrestricted passwordless sudo.

That is the right least-privilege model for your project.

---

## 14. Minimal runner test workflows

### Staging runner test

Create:

`.github/workflows/test-staging-runner.yml`

```yaml
name: Test staging runner

on:
  workflow_dispatch:

jobs:
  test-runner:
    runs-on: [self-hosted, linux, x64, staging]

    steps:
      - name: Show basic info
        run: |
          whoami
          hostname
          pwd
          uname -a

      - name: Check Docker
        run: |
          docker --version
          docker compose version
```

This is consistent with the original staging guide. fileciteturn18file1

### Proxy runner test

Create:

`.github/workflows/test-proxy-runner.yml`

```yaml
name: Test proxy runner

on:
  workflow_dispatch:

jobs:
  test-runner:
    runs-on: [self-hosted, linux, x64, proxy]

    steps:
      - name: Show basic info
        run: |
          whoami
          hostname
          pwd
          uname -a

      - name: Check nginx and local proxy files
        run: |
          nginx -v
          ls -l /etc/nginx/upstreams
          cat /etc/nginx/upstreams/active.conf

      - name: Check proxy cutover helper
        run: |
          sudo -n /usr/local/bin/myproject-switch-proxy blue >/dev/null
          sudo -n /usr/local/bin/myproject-switch-proxy green >/dev/null
```

This test is not identical to the staging one because the proxy runner’s role is different.

---

## 15. Common mistakes

### Mistake 1 — installing a runner before the VM works manually
This was already highlighted in the original guide and remains one of the biggest sources of confusion. fileciteturn18file0

### Mistake 2 — forgetting the custom label
If the runner does not have the expected label, the workflow stays queued. The staging guide already highlighted this. fileciteturn18file3

### Mistake 3 — mixing runner files with app files
Keep:
- app under `~/myproject/...`
- runner under `~/actions-runner` fileciteturn18file3

### Mistake 4 — not installing the runner as a service
If you rely only on `./run.sh`, it stops when the terminal closes. This was already explained in the original document. fileciteturn18file2

### Mistake 5 — assuming Proxy can reach Blue/Green over SSH without explicit setup
This was the real blocker in your production pipeline later. It must be configured deliberately.

### Mistake 6 — using hostnames that the Proxy VM cannot resolve
If the Proxy VM cannot resolve the Blue/Green hostnames, SSH fails with “Could not resolve hostname.” In that case, use real reachable IPs or a correctly configured SSH config.

---

## 16. Recommended final role mapping for your project

### VM Aplicatie
- runner name: `runner-aplicatie-staging`
- labels: `staging`
- purpose: Pipeline 2 deployment target

### VM Prx
- runner name: `runner-prx-proxy`
- labels: `proxy,production`
- purpose: Pipeline 3 orchestration and cutover control

### VM Albastru
- no runner required right now
- receives deployment from Proxy via SSH

### VM Verde
- no runner required right now
- receives deployment from Proxy via SSH

### VM BazaDeDate
- no runner recommended
- keep DB VM simple

This is consistent with the scaffold’s original emphasis on keeping the DB VM simple and optional runner installation only on the relevant automation VMs. fileciteturn18file5

---

## 17. Final validation checklist

You are done when all of these are true:

### Staging runner
- appears in GitHub under **Settings → Actions → Runners**
- status is **Online** or **Idle**
- labels include:
  - `self-hosted`
  - `Linux`
  - `X64`
  - `staging`
- Docker is usable by `deploy`

### Proxy runner
- appears in GitHub under **Settings → Actions → Runners**
- status is **Online** or **Idle**
- labels include:
  - `self-hosted`
  - `Linux`
  - `X64`
  - `proxy`
  - optionally `production`
- nginx works manually
- `/usr/local/bin/myproject-switch-proxy` works
- `deploy` can run that helper via limited passwordless sudo
- `deploy` on Proxy can SSH to Blue and Green without a password
- `~/.ssh/config` simplifies Blue/Green SSH access if you choose to use it

---

## 18. Final recommendation

Use the same runner installation mechanics on every VM, but adapt:

- runner name
- labels
- prerequisites
- post-install checks

to the actual VM role.

For your project, the two key self-hosted runners are:

- staging runner on VM Aplicatie
- proxy / production runner on VM Prx

And the key additional production requirement beyond runner installation is:

- passwordless SSH from Proxy to Blue/Green
- optionally simplified with `~/.ssh/config`

That gives you a much cleaner and more realistic private-network CI/CD design than trying to force GitHub-hosted runners to SSH into VMware-private VMs.
