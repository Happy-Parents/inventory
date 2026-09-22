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
