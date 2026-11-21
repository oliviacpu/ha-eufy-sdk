# About this fork

A personal fork of [mega-yfue/ha-eufy-sdk](https://github.com/mega-yfue/ha-eufy-sdk), installed through HACS on one
Home Assistant instance that runs the [oliviacpu/ha-eufy-sdk-bridge](https://github.com/oliviacpu/ha-eufy-sdk-bridge)
fork. Its `main` is upstream's `main` (its releases) plus the changes listed below. Upstream's README,
`CONTRIBUTING.md` and docs still apply.

## Rules for changes

- **Nothing is sent upstream.** Changes still stay upstream-shaped: one change and its tests per commit, so any one of
  them could be cherry-picked onto an upstream branch later.
- **Upstream behaviour stays the default.** New entities only add to what upstream creates; existing entity ids,
  unique ids and stores don't change.
- **Work happens on `fork/*` branches**, merged into `main` by pull request in this repository.
- **Tests:** `uv venv --python 3.14 .venv-py314`, `uv pip install --python .venv-py314 -r requirements_common.txt -r
  requirements_dev.txt pytest`, then `.venv-py314/bin/python -m pytest tests -q`, `ruff check` and `ruff format
  --check` on `custom_components` and `tests`.

## Upstream, releases and HACS

- **Upstream sync:** `.github/workflows/fork-sync.yml` runs daily at 09:47 UTC. It merges upstream's `main` into this
  `main` when it doesn't have it yet, runs the tests and ruff, pushes, and releases. A merge that conflicts, fails, or
  changes upstream's workflow files (which the workflow's token may not push) opens or updates one issue labelled
  `upstream-sync`; nothing is pushed. Merge by hand then: `git fetch upstream`, branch from `main`,
  `git merge upstream/main`, fix, open a pull request here, merge, and run `fork-release.yml`.
- **Release:** `.github/workflows/fork-release.yml`, run by the sync or by hand. It tests, sets `manifest.json`'s
  version to `<upstream version>-oliviacpu.<YYYYMMDD>[.N]`, commits that to `main`, tags it
  `oliviacpu-YYYY.MM.DD[.N]` and creates a GitHub Release. Upstream's tags are bare versions, so the two never collide.
  HACS installs the tagged source (no zip).
- **Install:** HACS → custom repository `oliviacpu/ha-eufy-sdk` (Integration), with the upstream repository removed
  first: two HACS repositories writing one folder overwrite each other. The domain is still `eufy_sdk`, so the config
  entry and entities carry over. Updates are by hand in HACS, then a Home Assistant restart.
- **Rollback:** download an older release of this repository in HACS, or remove it and add upstream back.
- **Upstream's workflows are disabled here** except `test.yml`, `lint.yml` and `validate.yml`; `guard-release-branch.yml`
  polices upstream's own pull requests. After a manual upstream merge, check `gh workflow list --all` for new ones.

## Changes in this fork

Newest first.

### Online sensors judged from the bridge's liveness facts (2026-11-21)

- **What it changes:** a device's Online (connectivity) sensor gives the same verdict `device_offline` gives its other
  entities, and every camera and station gets one. Unique ids are unchanged, so existing Online entities come back.
- **Cause:** the sensor read only the cloud's `deviceStatus` (param 1131) and was created only for devices reporting
  it. The SDK's beta withholds 1131 on most cameras, since it means different things on different devices, so behind
  the current bridge every camera's Online sensor went unavailable. Upstream's `dev` reads `deviceStatus` the same way.
- **Change:** `entity.py` gains `has_liveness_facts` and `judges_online`; `binary_sensor.py`'s Online sensor uses
  `device_offline` when the bridge forwards any liveness fact (an availability observation, a live feed or station
  session, `lastSeenMs` against the device class's window), else `deviceStatus` as before. Tests:
  `tests/test_device_online.py`.
