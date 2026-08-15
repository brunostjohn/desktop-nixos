#!/usr/bin/env bash
# Bump the pinned version and hash of the repacked AI desktop apps.
#
# Both vendors publish a Debian repository index that carries an authoritative
# SHA256 for every package, so a bump needs no download: read the index, convert
# the hex digest to SRI, rewrite the two lines in packages/<name>.nix.
#
# Retention differs sharply between the two, which is why this exists:
# Anthropic keeps every published version in its pool indefinitely, while OpenAI
# prunes objects after roughly one to two weeks. A stale chatgpt-desktop pin
# eventually fails to fetch, and the fix is to run this.

set -Eeuo pipefail

readonly claude_index="https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages"
readonly chatgpt_index="https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-amd64/Packages"

check_only=0
updated_any=0

usage() {
  cat <<'EOF'
Usage: update-ai-desktops [--check] [configuration-directory]

  Reads the upstream apt indexes and updates the pinned version + hash in
  packages/claude-desktop.nix and packages/chatgpt-desktop.nix.

  --check  Report what would change and exit non-zero if anything is stale,
           without writing. Suitable for CI or a pre-update sanity check.
EOF
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

# Emit "<version> <sha256-hex>" for the newest version of $2 in the index at $1.
# The Claude index lists every release it has ever published, so the newest must
# be selected by version sort rather than by position.
latest_from_index() {
  local index_url="$1" package_name="$2" index

  index=$(curl -fsSL --max-time 60 "$index_url") ||
    fail "could not fetch the package index at $index_url"

  printf '%s\n' "$index" |
    awk -v want="$package_name" '
      /^Package:/ { pkg = $2 }
      /^Version:/ { version = $2 }
      /^SHA256:/  { if (pkg == want) print version, $2 }
    ' |
    sort -V |
    tail -n 1
}

update_package() {
  local nix_file="$1" index_url="$2" package_name="$3"
  local latest version digest sri current_version current_hash

  [[ -f "$nix_file" ]] || fail "no such file: $nix_file"

  latest=$(latest_from_index "$index_url" "$package_name")
  [[ -n "$latest" ]] || fail "$package_name not found in $index_url"
  read -r version digest <<<"$latest"

  sri=$(nix hash convert --hash-algo sha256 --to sri "$digest") ||
    fail "could not convert the digest for $package_name"

  current_version=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$nix_file" | head -n 1)
  current_hash=$(sed -n 's/^    hash = "\(.*\)";$/\1/p' "$nix_file" | head -n 1)

  if [[ "$current_version" == "$version" && "$current_hash" == "$sri" ]]; then
    printf '%-16s %s (current)\n' "$package_name" "$version"
    return 0
  fi

  printf '%-16s %s -> %s\n' "$package_name" "${current_version:-unknown}" "$version"
  printf '  %s\n  %s\n' "$current_hash" "$sri"
  updated_any=1

  if ((check_only == 1)); then
    return 0
  fi

  # Anchored on the exact indentation these two lines are written with, so a
  # hash appearing anywhere else in the expression is never touched.
  sed -i \
    -e "s|^  version = \".*\";$|  version = \"$version\";|" \
    -e "s|^    hash = \".*\";$|    hash = \"$sri\";|" \
    "$nix_file"
}

main() {
  local repository

  while (($# > 0)); do
    case "$1" in
      --check)
        check_only=1
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      -*)
        usage >&2
        fail "unknown option: $1"
        ;;
      *)
        break
        ;;
    esac
  done

  repository=${1:-$PWD}
  [[ -d "$repository/packages" ]] ||
    fail "$repository does not look like the configuration directory"

  update_package "$repository/packages/claude-desktop.nix" "$claude_index" claude-desktop
  update_package "$repository/packages/chatgpt-desktop.nix" "$chatgpt_index" chatgpt

  if ((updated_any == 0)); then
    echo "Both packages are already pinned to the newest published build."
    return 0
  fi

  if ((check_only == 1)); then
    echo "Pins are stale. Re-run without --check to update them." >&2
    return 1
  fi

  echo
  echo "Pins updated. Rebuild to fetch the new packages:"
  echo "    nix run .#nixos-maintenance -- rebuild"
}

main "$@"
