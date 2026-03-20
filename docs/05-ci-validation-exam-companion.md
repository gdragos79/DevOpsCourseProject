# Pipeline 1 — CI Validation — exam companion

This companion explains the CI validation workflow in exam language. For each code section it shows the line interval, a strong color marker, what the section does, why it was designed that way, and which DevOps principle it supports.

> Important database clarification: the workflow-level variables named TEST_DB_* and TEST_DATABASE_URL refer only to a disposable PostgreSQL service container created inside the GitHub Actions runner for this single job. They are not staging or production secrets.

> Inside the service block, the names remain POSTGRES_DB, POSTGRES_USER, and POSTGRES_PASSWORD because the official postgres image expects those exact variable names for initialization.

## How to explain this pipeline in an exam

> Pipeline 1 is the validation gate between daily development and the staging release branch. It runs on pull requests into staging, creates an isolated temporary PostgreSQL database only for the job, validates backend and frontend quality, checks that the backend can actually start and answer the health endpoint, and validates that both Docker images can be built.

## Section-by-section explanation

### [1-2] Red marker — Workflow Identity

```yaml
  1  name: Pipeline 1 - CI Validation
  2  
```

**What it does:** Defines the human-readable name of the workflow in the Actions UI.


**Why it is written this way:** A clear name helps the evaluator immediately recognize this as Pipeline 1 and understand its role without opening the file.

### [3-8] Orange marker — Trigger Rules

```yaml
  3  on:
  4    pull_request:
  5      branches:
  6        - staging
  7      types: [opened, synchronize, reopened]
  8    workflow_dispatch:
```

**What it does:** Runs automatically for pull requests targeting staging and also supports manual execution.


**Why it is written this way:** PR validation is the right gate because staging acts as the practical release branch. Manual triggering is useful for demonstrations, debugging, and rerunning the workflow without creating a new PR.

### [10-12] Yellow marker — Minimum Permissions

```yaml
 10  permissions:
 11    contents: read
 12    pull-requests: write
```

**What it does:** Requests only the repository permissions needed by this workflow: read access to contents and permission to write a pull-request comment.


**Why it is written this way:** Least privilege is a core security principle. It reduces blast radius if a workflow step misbehaves.

### [14-22] Green marker — Global Settings and CI Test Database

```yaml
 14  env:
 15    NODE_VERSION: '20'
 16    FRONTEND_DIR: frontend
 17    BACKEND_DIR: backend
 18    BACKEND_PORT: '3000'
 19    BACKEND_HEALTH_PATH: /api/health
 20    TEST_DB_NAME: appdb
 21    TEST_DB_USER: postgres
 22    TEST_DB_PASSWORD: postgres
```

**What it does:** Stores non-secret pipeline settings such as Node version, directories, health path, and CI-only test database values.


**Why it is written this way:** These values belong in the workflow because they describe pipeline behavior, not runtime production configuration. The TEST_ prefix prevents confusion with real infrastructure secrets.

### [24-26] Cyan marker — Validation Job Definition

```yaml
 24  
 25  jobs:
 26    validate:
```

**What it does:** Declares one validation job on an Ubuntu GitHub-hosted runner.


**Why it is written this way:** A single sequential job is easier to explain and troubleshoot in a student project. GitHub-hosted runners reduce maintenance compared with self-hosted runners.

### [28-41] Blue marker — Temporary PostgreSQL Service

```yaml
 28      runs-on: ubuntu-latest
 29  
 30      services:
 31        postgres:
 32          image: postgres:16
 33          env:
 34            POSTGRES_DB: appdb
 35            POSTGRES_USER: postgres
 36            POSTGRES_PASSWORD: postgres
 37          ports:
 38            - 5432:5432
 39          options: >-
 40            --health-cmd="pg_isready -U postgres -d appdb"
 41            --health-interval=10s
```

**What it does:** Starts a disposable PostgreSQL container and health-checks it before tests depend on it.


**Why it is written this way:** This isolates CI from real infrastructure and guarantees a clean database for every run. The service is destroyed when the job ends, which is safer than sharing a persistent database.

### [43-45] Indigo marker — Repository Checkout

```yaml
 43            --health-retries=5
 44  
 45      steps:
```

**What it does:** Downloads the PR code into the runner workspace.


**Why it is written this way:** All later commands need the repository files. Keeping checkout explicit makes the workflow easier to explain in an exam.

### [47-54] Purple marker — Node.js Runtime Setup and Caching

```yaml
 47          uses: actions/checkout@v4
 48  
 49        - name: Set up Node.js
 50          uses: actions/setup-node@v4
 51          with:
 52            node-version: ${{ env.NODE_VERSION }}
 53            cache: npm
 54            cache-dependency-path: |
```

**What it does:** Installs the selected Node.js version and enables npm caching based on the lock files.


**Why it is written this way:** Pinning the runtime improves reproducibility. Dependency caching speeds up repeated runs without changing the intended software versions.

### [56-61] Magenta marker — Dependency Installation

```yaml
 56              ${{ env.FRONTEND_DIR }}/package-lock.json
 57  
 58        - name: Install backend dependencies
 59          working-directory: ${{ env.BACKEND_DIR }}
 60          run: npm ci
 61  
```

**What it does:** Installs backend and frontend dependencies with npm ci.


**Why it is written this way:** npm ci is preferred in CI because it uses package-lock.json exactly and is more deterministic than npm install.

### [63-69] Teal marker — Backend Static Checks and Unit Tests

```yaml
 63          working-directory: ${{ env.FRONTEND_DIR }}
 64          run: npm ci
 65  
 66        - name: Lint backend
 67          working-directory: ${{ env.BACKEND_DIR }}
 68          run: npm run lint
 69  
```

**What it does:** Runs backend linting and unit tests while providing a test-only database connection string.


**Why it is written this way:** Fast checks should happen before heavier runtime checks. Mapping DATABASE_URL from TEST_DATABASE_URL preserves application compatibility while keeping the workflow semantics clear.

### [71-86] Lime marker — Start Backend and Wait for Health

```yaml
 71          working-directory: ${{ env.BACKEND_DIR }}
 72          env:
 73            DATABASE_URL: ${{ env.TEST_DATABASE_URL }}
 74          run: npm test
 75  
 76        - name: Start backend for API tests
 77          working-directory: ${{ env.BACKEND_DIR }}
 78          env:
 79            PORT: ${{ env.BACKEND_PORT }}
 80            DATABASE_URL: ${{ env.TEST_DATABASE_URL }}
 81          run: |
 82            npm run start:test > /tmp/backend.log 2>&1 &
 83            echo $! > /tmp/backend.pid
 84  
 85        - name: Wait for backend health endpoint
 86          run: |
```

**What it does:** Starts the backend in the background, stores the process ID, and polls /api/health until the service is ready.


**Why it is written this way:** Integration tests are meaningful only after the application has actually started. The retry loop prevents flaky failures caused by normal startup delay.

### [88-94] Chartreuse marker — Backend Integration and API Tests

```yaml
 88              if curl -fsS "http://127.0.0.1:${BACKEND_PORT}${BACKEND_HEALTH_PATH}" > /dev/null; then
 89                exit 0
 90              fi
 91              sleep 2
 92            done
 93            echo "Backend did not become healthy in time"
 94            cat /tmp/backend.log || true
```

**What it does:** Runs integration tests against a live local backend instance via HTTP.


**Why it is written this way:** Unit tests prove internal logic; integration tests prove the application components work together, including routing and database access.

### [96-102] Amber marker — Frontend Quality Checks

```yaml
 96  
 97        - name: Run backend integration/API tests
 98          working-directory: ${{ env.BACKEND_DIR }}
 99          env:
100            API_BASE_URL: http://127.0.0.1:${{ env.BACKEND_PORT }}
101            DATABASE_URL: ${{ env.TEST_DATABASE_URL }}
102          run: npm run test:integration
```

**What it does:** Runs frontend linting and unit tests.


**Why it is written this way:** The release gate should cover the whole application, not only the backend.

### [104-108] Brown marker — Docker Build Validation

```yaml
104        - name: Lint frontend
105          working-directory: ${{ env.FRONTEND_DIR }}
106          run: npm run lint
107  
108        - name: Run frontend unit tests
```

**What it does:** Builds backend and frontend Docker images locally on the runner without pushing them anywhere.


**Why it is written this way:** The project is deployed as containers, so packaging must be validated early. This catches broken Dockerfiles and missing files before staging deployment.

### [110-115] Blue-grey marker — Cleanup

```yaml
110          run: npm test
111  
112        - name: Validate backend Docker build
113          run: docker build -t backend-ci-check ./backend
114  
115        - name: Validate frontend Docker build
```

**What it does:** Stops the background backend process even if an earlier step failed.


**Why it is written this way:** Good automation includes cleanup. It keeps the runner environment predictable and makes debugging clearer.

### [117-126] Deep red marker — Pull Request Feedback

```yaml
117  
118        - name: Stop backend process
119          if: always()
120          run: |
121            if [ -f /tmp/backend.pid ]; then
122              kill "$(cat /tmp/backend.pid)" || true
123            fi
124  
125        - name: Comment on PR if workflow failed
126          if: failure() && github.event_name == 'pull_request'
```

**What it does:** Posts a comment to the PR if the workflow failed.


**Why it is written this way:** A pipeline should help humans react to failures, not merely detect them. This improves collaboration and developer feedback.


## Typical exam questions and concise answers

### Why use a temporary CI database instead of the real staging database?
Because CI should be isolated, reproducible, and safe. A disposable database gives every run a clean state and prevents any accidental modification of a real environment.

### Why still pass DATABASE_URL to some backend steps?
Because many Node backends are already coded to read DATABASE_URL. The workflow maps DATABASE_URL from TEST_DATABASE_URL so the pipeline stays compatible while still making the test-only nature explicit.

### Why include Docker build validation in Pipeline 1?
Because the project is deployed as containers. Passing source-code tests is not enough if the Docker build itself is broken.
