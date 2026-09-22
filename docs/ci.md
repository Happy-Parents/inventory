# CI

## What runs, and why it matches pre-push

`.github/workflows/ci.yml` runs on every pull request and on every push to
`main`. Its jobs are the same checks Overcommit runs on `git push`
(`.overcommit.yml`, `.git-hooks/pre_push/`), so CI never disagrees with a local
push:

| CI job                  | Check run name          | Command                                  | Pre-push hook |
| ----------------------- | ----------------------- | ---------------------------------------- | ------------- |
| `lint`                  | `Lint`                  | `bin/rubocop -f github`                  | `RuboCop`     |
| `scan_ruby`             | `Security (Ruby)`       | `bin/brakeman`, `bin/bundler-audit`      | `BundlerAudit`|
| `scan_js`               | `Security (JavaScript)` | `bin/importmap audit`                    | —             |
| `test`                  | `Test (RSpec)`          | `bin/rails db:test:prepare && bundle exec rspec` | `RSpec` |

Brakeman and the importmap audit have no pre-push counterpart on purpose: they
are slow enough to be annoying on a push, and cheap enough to always run here.

No job on this workflow takes a repository secret. `Test (RSpec)` gets its
database credentials from the `DB_*` variables the Postgres service is started
with, and Rails makes up a throwaway `secret_key_base` in the test environment
when no `config/master.key` and no `RAILS_MASTER_KEY` are around -- so nothing
here has to decrypt `config/credentials.yml.enc`. Handing the job a key is not
just unnecessary, it is a way to break it: the wrong key aborts the boot with
`ActiveSupport::MessageEncryptor::InvalidMessage`, and a pull request from a
fork cannot read secrets at all. The `RAILS_MASTER_KEY` secret this repository
does hold is `config/credentials/production.key` (see README), which by design
does not open `config/credentials.yml.enc`; it belongs to the deploy workflow.

The check run name is the job's `name:`. **Renaming a job renames the status
check, and a required check that no longer reports blocks every merge** — update
the ruleset below in the same change.

## Making the checks required for merge

Branch protection is repository configuration, not a file in the repo: GitHub
does not read anything under `.github/` for this. `.github/rulesets/main-required-checks.json`
is the ruleset in importable form — apply it one of two ways.

### Import in the UI

Settings → Rules → Rulesets → **New ruleset → Import a ruleset** → upload
`.github/rulesets/main-required-checks.json` → Create.

### Apply with the API

Requires admin on the repository and a token with the `repo` scope:

```sh
gh api --method POST /repos/Happy-Parents/inventory/rulesets \
  --input .github/rulesets/main-required-checks.json
```

To update it later, find the id with `gh api /repos/Happy-Parents/inventory/rulesets`
and `PUT` to `/repos/Happy-Parents/inventory/rulesets/<id>` with the same file.

### What the ruleset enforces on `main`

- A pull request is required; direct pushes to `main` are rejected.
- `Lint`, `Security (Ruby)`, `Security (JavaScript)` and `Test (RSpec)` must all
  be green before the merge button unlocks.
- `strict_required_status_checks_policy` is on: the branch must also be up to
  date with `main`, so the checks that pass are the checks for the code that
  actually lands.
- Force-pushing to and deleting `main` are blocked.
- Zero approving reviews are required — the checks are the gate, not review.
  Raise `required_approving_review_count` in the JSON if that changes.

Note that a required check that has never reported once leaves a PR pending
forever. Merge this workflow to `main` first, let one run finish, then apply the
ruleset.

## Deploying from the Actions tab

`.github/workflows/deploy.yml` runs `bin/kamal deploy` on a GitHub runner — the
same command, the same `config/deploy.yml` and the same `.kamal/secrets` as a
deploy from a laptop, including the `pre-deploy` hook that runs
`bin/preflight --remote`. It only runs when someone starts it:
**Actions → Deploy → Run workflow**.

The **branch** input decides what ships. It defaults to `main`; type any branch,
tag or SHA to deploy that instead. The **Use workflow from** dropdown above it
is a GitHub control that only picks which copy of `deploy.yml` executes — it
does *not* change what gets built, so leave it on `main` unless the workflow
file itself is what you are testing.

Deploys are serialised (`concurrency: deploy-production`) and never cancelled
mid-rollout.

### Secrets it needs

Two of the deploy's inputs are gitignored and so cannot come from the checkout.
Add them under Settings → Secrets and variables → Actions:

| Secret | Value |
| ------ | ----- |
| `RAILS_PRODUCTION_KEY` | Contents of `config/credentials/production.key`. Unlocks the registry PAT, the database password and the origin TLS key. |
| `KAMAL_SSH_PRIVATE_KEY` | Private half of `~/.ssh/koi_vps_deployer`, whole PEM including the header and footer lines. Written back to that same path, because `ssh.keys` in `config/deploy.yml` names it explicitly. |
| `KAMAL_SSH_KNOWN_HOSTS` | *Optional but recommended.* Output of `ssh-keyscan 193.169.188.144`. Without it the workflow keyscans at deploy time and trusts whatever answers. |

Nothing else is needed: Kamal logs in to GHCR with the PAT it reads out of the
encrypted production credentials, so `GITHUB_TOKEN` is not involved and the job
only asks for `contents: read`.

The workflow targets a `production` environment, which GitHub creates on the
first run. Add required reviewers or a branch restriction there (Settings →
Environments → production) if deploys should need an approval.
