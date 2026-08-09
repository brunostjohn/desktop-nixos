#!/usr/bin/env bash
# Find the newest codex-desktop-linux commit whose codex-desktop build is
# actually present in codex-desktop-linux.cachix.org, and print the flake URL to
# pin in flake.nix.
#
# Why this is needed: the package's src is the whole repo and it bakes in
# self.rev, so every commit is a different store path. Their CI
# (.github/workflows/cachix.yml) only builds and pushes on a push to main that
# touches flake.nix AND changes the upstream Codex DMG hash, so the overwhelming
# majority of commits are not in the cache. Tracking the branch means rebuilding
# ~900MB of vendored Electron on every `nix flake update`.
set -euo pipefail

REPO=ilysenko/codex-desktop-linux
CACHE=https://codex-desktop-linux.cachix.org
DEPTH=${DEPTH:-300}
MAX_CANDIDATES=${MAX_CANDIDATES:-15}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "Cloning $REPO (blobless, depth $DEPTH)..." >&2
git clone --quiet --filter=blob:none --depth "$DEPTH" \
  "https://github.com/$REPO.git" "$tmp/repo" >&2

# Only commits that touched flake.nix can possibly have triggered the workflow.
mapfile -t revs < <(git -C "$tmp/repo" log --format='%H' -- flake.nix | head -n "$MAX_CANDIDATES")

for rev in "${revs[@]}"; do
  date=$(git -C "$tmp/repo" log -1 --format='%ad' --date=short "$rev")
  subject=$(git -C "$tmp/repo" log -1 --format='%s' "$rev" | cut -c1-58)

  if ! path=$(nix eval --raw --no-write-lock-file \
      "github:$REPO/$rev#packages.x86_64-linux.codex-desktop" 2>/dev/null); then
    printf '  %.12s  %s  eval failed\n' "$rev" "$date" >&2
    continue
  fi

  hash=${path#/nix/store/}
  hash=${hash%%-*}
  code=$(curl -fsS -o /dev/null -w '%{http_code}' "$CACHE/$hash.narinfo" || echo 000)

  if [ "$code" = 200 ]; then
    printf '  %.12s  %s  CACHED  %s\n' "$rev" "$date" "$subject" >&2
    echo >&2
    echo "Pin this in flake.nix:" >&2
    echo "    codex-desktop-linux.url ="
    echo "      \"github:$REPO/$rev\";"
    exit 0
  fi

  printf '  %.12s  %s  miss    %s\n' "$rev" "$date" "$subject" >&2
done

echo "No cached rev found in the last $MAX_CANDIDATES flake.nix commits." >&2
echo "Raise MAX_CANDIDATES/DEPTH, or keep the current pin." >&2
exit 1
