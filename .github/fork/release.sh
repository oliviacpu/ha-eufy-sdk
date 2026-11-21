#!/usr/bin/env bash
# Release main: set manifest.json's version to <upstream version>-oliviacpu.<YYYYMMDD>[.N], commit it, tag
# oliviacpu-YYYY.MM.DD[.N] and create the GitHub Release listing the fork changes. Expects checked-out main.
set -euo pipefail

manifest=custom_components/eufy_sdk/manifest.json
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git fetch --quiet --force --tags origin
git fetch --quiet https://github.com/mega-yfue/ha-eufy-sdk.git main:refs/remotes/upstream/main

day=$(date -u +%Y.%m.%d)
count=$(git tag -l "oliviacpu-$day" "oliviacpu-$day.*" | wc -l | tr -d ' ')
suffix=""
[ "$count" -gt 0 ] && suffix=".$((count + 1))"
tag="oliviacpu-$day$suffix"
prev=$(git tag -l 'oliviacpu-*' --sort=-v:refname | head -n 1)

base=$(python3 -c "import json; print(json.load(open('$manifest'))['version'].split('-oliviacpu')[0])")
version="$base-oliviacpu.$(date -u +%Y%m%d)$suffix"
python3 - "$manifest" "$version" <<'PY'
import json, sys
path, version = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
data["version"] = version
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
git add "$manifest"
git commit -q -m "chore(release): $tag ($version)"
git push origin HEAD:main
git tag "$tag" HEAD
git push origin "$tag"

repo="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY"
fmt="- %s ([%h]($repo/commit/%H))"
notes=$(mktemp)
{
  echo "Integration \`$version\`, on upstream \`main\` at $(git rev-parse --short refs/remotes/upstream/main)."
  echo
  if [ -n "$prev" ]; then
    echo "## New since $prev"
    echo
    git log --no-merges --reverse --invert-grep --grep '^chore(release):' --format="$fmt" "$prev..HEAD" --not refs/remotes/upstream/main
    echo
  fi
  echo "## All fork changes not in upstream"
  echo
  echo "What each one fixes, why, and how: [FORK.md]($repo/blob/$tag/FORK.md)."
  echo
  git log --no-merges --reverse --invert-grep --grep '^chore(release):' --format="$fmt" refs/remotes/upstream/main..HEAD
} >"$notes"
gh release create "$tag" --verify-tag --title "$version" --notes-file "$notes"
echo "released $tag ($version)"
