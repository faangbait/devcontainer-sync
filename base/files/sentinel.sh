#!/usr/bin/env bash
# sentinel.sh — resolve the project root ONCE, the same way in every context.
#
# The point of the whole conversation: don't re-derive "where is home" per
# script. Read it from a layer beneath the language.
#
#   1. $PROJECT_ROOT stamped at the boundary  -> trust it, zero filesystem work.
#   2. Only if unset: walk up to a sentinel marker, from an EXPLICIT start dir,
#      guarded so it errors instead of wandering into / or /proc.
#
# Source it:  . sentinel.sh; root=$(project_root) || exit 1
# Marker:     an empty file named .project-root at each project root.

SENTINEL_MARKER=".project-root"

project_root() {
    # 1. Boundary already answered? Trust it. No walk at all — this is the
    #    layer that works identically in all 30 languages.
    if [ -n "${PROJECT_ROOT:-}" ]; then
        printf '%s\n' "$PROJECT_ROOT"
        return 0
    fi

    # 2. Walk up from an EXPLICIT start: first arg, else $PWD.
    #    Deliberately NOT $0/BASH_SOURCE — those lie under `sh -c`, curl|bash,
    #    sourcing, and cron, which is how you end up walking into /proc.
    local dir
    dir=$(cd -- "${1:-$PWD}" 2>/dev/null && pwd) || return 1

    while [ "$dir" != "/" ]; do
        if [ -e "$dir/$SENTINEL_MARKER" ]; then
            printf '%s\n' "$dir"
            return 0
        fi
        dir=$(dirname -- "$dir")
    done

    # Hit / without a marker. Error loudly; never echo "/".
    printf 'project_root: no %s found above %s\n' \
        "$SENTINEL_MARKER" "${1:-$PWD}" >&2
    return 1
}

# Runnable self-check when executed directly (not when sourced).
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    set -euo pipefail
    unset PROJECT_ROOT
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    mkdir -p "$tmp/a/b/c"
    : > "$tmp/a/$SENTINEL_MARKER"

    # walks up to the marker
    [ "$(project_root "$tmp/a/b/c")" = "$tmp/a" ] || { echo "FAIL: walk"; exit 1; }

    # boundary stamp wins, no walk, arg ignored
    [ "$(PROJECT_ROOT=/stamped project_root "$tmp/a/b/c")" = /stamped ] \
        || { echo "FAIL: stamp"; exit 1; }

    # no marker -> error, never prints /
    if project_root /tmp >/dev/null 2>&1; then echo "FAIL: should-error"; exit 1; fi

    echo "ok: walk, stamp, and guard all hold"
fi
