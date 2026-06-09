# Runx Governed Skill Action

Run a governed `runx skill` command inside GitHub Actions.

This action is for CI workflows that already have a runx skill in the repository
or installable in the runner environment. It installs the `runx` CLI from npm by
default, runs `runx skill ...`, and exposes stdout, stderr, and the exit code as
action outputs.

It does not replace the hosted runx API planned for cloud orchestrators such as
n8n, Zapier, Make, or Pipedream. GitHub Actions can run local CLI work on its
runner; cloud automation directories need the hosted run-skill API.

## Usage

```yaml
name: runx

on:
  workflow_dispatch:

jobs:
  governed-skill:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: runxhq/runx-action@v0
        env:
          RUNX_RECEIPT_SIGN_KID: ci
          RUNX_RECEIPT_SIGN_ED25519_SEED_BASE64: ${{ secrets.RUNX_RECEIPT_SIGN_ED25519_SEED_BASE64 }}
          RUNX_RECEIPT_SIGN_ISSUER_TYPE: hosted
        with:
          skill: ./skills/deploy-check
          receipt-dir: .runx/receipts
          args: |
            --environment=staging
```

`args` is newline-delimited. Each non-empty line becomes one argument token after
the skill path. For values with spaces, use the `--name=value with spaces` form:

```yaml
with:
  skill: ./skills/release-note
  args: |
    --objective=Draft release notes for the current diff
```

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `skill` | required | Skill ref, skill directory, or `SKILL.md` path passed to `runx skill`. |
| `args` | empty | Additional `runx skill` arguments, one token per line. |
| `json` | `true` | Appends `--json` before `args`. Set to `false` if you manage output flags yourself. |
| `receipt-dir` | empty | Optional receipt output directory passed as `--receipt-dir`. |
| `working-directory` | `.` | Directory where `runx skill` runs. |
| `install` | `true` | Install the npm runx CLI before running. |
| `version` | `latest` | Version of `@runxhq/cli` to install. |
| `npm-package` | `@runxhq/cli` | npm package that provides the `runx` binary. |
| `runx-binary` | `runx` | Binary to execute when `install` is false or a custom binary is desired. |

## Outputs

| Output | Description |
| --- | --- |
| `exit-code` | Exit code from `runx skill`. |
| `stdout` | Standard output from `runx skill`. |
| `stderr` | Standard error from `runx skill`. |

## Receipts

runx skills can emit signed receipts depending on the skill, runtime, and
receipt configuration. Use `receipt-dir` or pass `--receipt-dir` in `args` when
you want receipt files to land in a known directory for later upload.

Current local runx execution requires receipt signing configuration:

- `RUNX_RECEIPT_SIGN_KID`
- `RUNX_RECEIPT_SIGN_ED25519_SEED_BASE64`
- `RUNX_RECEIPT_SIGN_ISSUER_TYPE`

Store the seed as a GitHub Actions secret. Do not commit a production signing
seed to the repository.

```yaml
- uses: runxhq/runx-action@v0
  env:
    RUNX_RECEIPT_SIGN_KID: ci
    RUNX_RECEIPT_SIGN_ED25519_SEED_BASE64: ${{ secrets.RUNX_RECEIPT_SIGN_ED25519_SEED_BASE64 }}
    RUNX_RECEIPT_SIGN_ISSUER_TYPE: hosted
  with:
    skill: ./skills/deploy-check
    receipt-dir: .runx/receipts
```

## Security

Do not put provider secrets directly in `args`. Use GitHub Actions secrets and
the normal runx credential inputs for your skill.

This action executes code through the local `runx` CLI on the GitHub Actions
runner. It is intended for repository-controlled skills and CI environments.
Third-party workflow platforms require the hosted runx API before they can safely
run governed skills without local shell access.
