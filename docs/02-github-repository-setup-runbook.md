# Document 2 — GitHub repository setup runbook

## Step 1 — Set the default branch
1. Open your repository on GitHub.
2. Click **Settings**.
3. Click **Branches**.
4. Under **Default branch**, choose `development`.
5. Confirm the change.

## Step 2 — Create the working branches if missing
Make sure these branches exist:
- `development`
- `staging`
- `production`

## Step 3 — Configure branch protection
### For `staging`
1. In **Settings → Branches**, click **Add branch ruleset** or **Add classic branch protection rule**.
2. Target branch: `staging`
3. Require a pull request before merging.
4. Require status checks to pass before merging.
5. Select the CI validation workflow status.

### For `production`
1. Add a second ruleset for `production`.
2. Require pull request or controlled workflow pushes according to your preferred governance model.
3. If your workflow must push directly, make sure your chosen protection model permits that.

## Step 4 — Create environments
Create these environments in **Settings → Environments**:
- `staging`
- `production`

## Step 5 — Add secrets
Open each environment and add the required secrets from `.env.secrets.example`.

## Step 6 — Set workflow permissions
In **Settings → Actions → General**:
1. Allow GitHub Actions to run.
2. Set workflow permissions to **Read and write permissions** if you want workflows to comment on PRs or push tags/packages.
3. Save changes.

## Step 7 — Verify GHCR package publishing
The staging workflow pushes to `ghcr.io` using `GITHUB_TOKEN`, so package write permissions must be enabled. The package namespace must match the repository owner.


## Additional branch protection update — two PR validation layers
Configure branch protection so each promotion step has its own required status check.

### Protect `development`
Require the workflow job:
- `Fast PR checks for development`

This ensures feature branches cannot merge into `development` without passing the lighter CI checks.

### Protect `staging`
Require the workflow job:
- `Frontend lint and tests, backend tests, health verification, Docker build validation`

This ensures code cannot merge from `development` into `staging` without passing the stronger promotion checks.
