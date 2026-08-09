#!/usr/bin/env bash

set -Eeuo pipefail

readonly host_name="catpaws"
readonly nyx_cache_default="https://nyx-cache.chaotic.cx"
readonly nyx_key="nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
readonly nyx_signer="nyx-cache.chaotic.cx:"

lock_replaced=0
temporary_directory=""
original_lock=""
repository=""
flake_ref=""
declare -a lock_flags=()

usage() {
  cat <<'EOF'
Usage: nixos-maintenance <check|rebuild|update> [configuration-directory]

  check    Verify and cache-realise the main and rescue kernels.
  rebuild  Check the current kernels, build the system, and install for next boot.
  update   Test an updated candidate lock, then atomically install it for next boot.
EOF
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

atomic_install_lock() {
  local source_lock="$1"
  local staged_lock

  staged_lock=$(mktemp "$repository/.flake.lock.XXXXXX")
  install -m 0644 "$source_lock" "$staged_lock"
  mv -f "$staged_lock" "$repository/flake.lock"
}

cleanup() {
  local status=$?

  trap - EXIT INT TERM
  if ((lock_replaced == 1)) && [[ -n "$original_lock" && -f "$original_lock" ]]; then
    printf 'Restoring the original flake.lock after failure...\n' >&2
    atomic_install_lock "$original_lock" || true
  fi
  if [[ -n "$temporary_directory" && -d "$temporary_directory" ]]; then
    rm -rf -- "$temporary_directory"
  fi
  exit "$status"
}

require_clean_lock_sources() {
  if ! git -C "$repository" diff --quiet -- flake.nix flake.lock \
    || ! git -C "$repository" diff --cached --quiet -- flake.nix flake.lock; then
    git -C "$repository" status --short -- flake.nix flake.lock >&2
    fail "commit or stash flake.nix and flake.lock before rebuilding or updating"
  fi
}

kernel_output_paths() {
  local package_name="$1"

  nix derivation show --no-pretty --no-write-lock-file \
    "${lock_flags[@]}" "$flake_ref#$package_name" \
    | jq -r '
        (if has("derivations") then .derivations else . end)
        | .[]
        | .outputs[]
        | (.path // empty)
        | if startswith("/") then . else "/nix/store/" + . end
      '
}

check_kernel_package() {
  local package_name="$1"
  local output_text
  local path
  local signature_info
  local -a output_paths=()
  local cache_url="${NIXOS_KERNEL_CACHE_URL:-$nyx_cache_default}"

  output_text=$(kernel_output_paths "$package_name") \
    || fail "could not evaluate $package_name"
  mapfile -t output_paths <<<"$output_text"
  ((${#output_paths[@]} > 0)) || fail "$package_name has no statically known outputs"

  printf '%s kernel outputs:\n' "$package_name"
  for path in "${output_paths[@]}"; do
    [[ -n "$path" ]] || continue
    printf '  %s\n' "$path"
    signature_info=$(nix path-info --store "$cache_url" --sigs "$path") \
      || fail "$path is not available from $cache_url"
    grep -Fq "$nyx_signer" <<<"$signature_info" \
      || fail "$path is not signed by $nyx_signer"
  done
}

check_and_realise_kernels() {
  local cache_url="${NIXOS_KERNEL_CACHE_URL:-$nyx_cache_default}"

  check_kernel_package main-kernel
  check_kernel_package rescue-kernel

  printf 'Realising both kernel packages from signed caches only...\n'
  nix build --no-link --max-jobs 0 --no-write-lock-file \
    --option fallback false \
    --option require-sigs true \
    --extra-substituters "$cache_url" \
    --extra-trusted-public-keys "$nyx_key" \
    "${lock_flags[@]}" \
    "$flake_ref#main-kernel^*" \
    "$flake_ref#rescue-kernel^*"
}

build_system() {
  printf 'Building the complete %s system without activating it...\n' "$host_name"
  nix build --no-link --print-out-paths --no-write-lock-file \
    --option fallback false \
    "${lock_flags[@]}" \
    "$flake_ref#nixosConfigurations.$host_name.config.system.build.toplevel"
}

install_for_next_boot() {
  local rebuild_command

  rebuild_command=$(command -v nixos-rebuild) \
    || fail "nixos-rebuild is not available"
  sudo "$rebuild_command" boot --flake "$flake_ref#$host_name"
}

main() {
  local action="${1:-}"
  local repository_argument="${2:-$HOME/NixOS Configuration}"
  local candidate_lock
  local runtime_directory

  case "$action" in
    check | rebuild | update) ;;
    -h | --help | "")
      usage
      exit 0
      ;;
    *)
      usage >&2
      fail "unknown action: $action"
      ;;
  esac

  repository=$(realpath "$repository_argument")
  [[ -f "$repository/flake.nix" && -f "$repository/flake.lock" ]] \
    || fail "$repository is not a locked Nix flake"
  cd "$repository"
  flake_ref="path:."

  if [[ "$action" == check ]]; then
    check_and_realise_kernels
    exit 0
  fi

  runtime_directory="${XDG_RUNTIME_DIR:-/tmp}"
  exec 9>"$runtime_directory/nixos-maintenance-$UID.lock"
  flock -n 9 || fail "another NixOS maintenance command is already running"
  require_clean_lock_sources

  if [[ "$action" == rebuild ]]; then
    check_and_realise_kernels
    build_system
    install_for_next_boot
    exit 0
  fi

  temporary_directory=$(mktemp -d)
  original_lock="$temporary_directory/original.lock"
  candidate_lock="$temporary_directory/candidate.lock"
  cp --preserve=mode,timestamps "$repository/flake.lock" "$original_lock"
  trap cleanup EXIT INT TERM

  printf 'Creating an updated candidate lock without changing the repository...\n'
  nix flake update --output-lock-file "$candidate_lock" "$flake_ref"
  lock_flags=(--reference-lock-file "$candidate_lock")

  check_and_realise_kernels
  build_system

  require_clean_lock_sources
  cmp -s "$original_lock" "$repository/flake.lock" \
    || fail "flake.lock changed while the candidate was building"

  atomic_install_lock "$candidate_lock"
  lock_replaced=1
  install_for_next_boot
  lock_replaced=0

  printf 'Installed the tested candidate for the next boot. Reboot when ready.\n'
}

main "$@"
