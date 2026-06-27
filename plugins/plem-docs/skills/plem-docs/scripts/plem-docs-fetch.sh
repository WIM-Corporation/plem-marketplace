#!/usr/bin/env bash
# plem-docs-fetch.sh — resolve the docs version (PLEM_DOCS_VERSION pin, else the
# installed `plem` deb, else `latest`) and fetch that version's agent docs from
# Depot. Single tested implementation so every skill invocation reuses the same
# version-resolution + fallback logic.
#
#   Usage:  plem-docs-fetch.sh [file]
#     file   (default: llms.txt) — e.g. llms.txt, llms-full.txt, interfaces.md
#
# Version source: PLEM_DOCS_VERSION if set (pin a release explicitly — e.g. a dev
# laptop targeting a specific Jetson), else the installed `plem` meta-package —
# the same packaging/VERSION SSoT the manual builder (version.py) uses. A Debian
# epoch/revision (e.g. `1:0.2.8-1`) is stripped to the upstream `0.2.8`, which is
# what Depot publishes under. If neither resolves (dev machine without the deb, or
# that version isn't published yet) it falls back to Depot's `latest`. Override
# host/timeout with PLEM_DEPOT_URL / PLEM_DEPOT_TIMEOUT.
#
# Depot path contract: GET {DEPOT}/docs/{version}/{file} (and /docs/latest/{file})
# mirrors depot backend/app/docs/router.py; a route change there must update this
# fetcher in lockstep — see WIM_CONTROL .claude/rules/agent-docs-contract-checklist.md.
#
# Each fetch is BUFFERED and emitted only on full success — so a partial or
# timed-out transfer never concatenates a truncated pinned doc with the latest
# doc (which would feed the agent a corrupted, mixed-version document). Body goes
# to stdout only on success; a one-line notice goes to stderr on fallback. Exit 0
# on success; non-zero only if even `latest` is unreachable (offline / docs not
# yet deployed) — the caller should then say so and switch to clearly-labeled
# general guidance rather than refusing outright.
set -uo pipefail

DEPOT="${PLEM_DEPOT_URL:-https://depot.wimcorp.dev}"
TIMEOUT="${PLEM_DEPOT_TIMEOUT:-20}"   # generous enough for a large llms-full.txt on a slow Jetson link
FILE="${1:-llms.txt}"

# Explicit pin wins; else auto-detect the installed deb. dpkg only resolves on
# the device (Jetson) — off-device (a dev laptop) it is empty and we fall through
# to `latest`, unless the caller pinned PLEM_DOCS_VERSION.
ver="${PLEM_DOCS_VERSION:-}"
if [ -z "$ver" ]; then
    ver="$(dpkg-query -W -f='${Version}' plem 2>/dev/null || true)"
    ver="${ver##*:}"   # strip epoch:    1:0.2.8  -> 0.2.8
    ver="${ver%%-*}"   # strip revision: 0.2.8-1  -> 0.2.8
fi

# Buffer-then-emit: $(...) discards captured stdout on a non-zero exit, so a
# partial transfer produces no output and we fall through cleanly.
if [ -n "$ver" ]; then
    if body="$(curl -fsSL --max-time "$TIMEOUT" "${DEPOT}/docs/${ver}/${FILE}")"; then
        printf '%s' "$body"
        exit 0
    fi
    echo "plem-docs: PLEM ${ver} not reachable on Depot — trying latest" >&2
fi

# /docs/latest/<file> 302-redirects to the newest concrete version (-L follows).
body="$(curl -fsSL --max-time "$TIMEOUT" "${DEPOT}/docs/latest/${FILE}")" && printf '%s' "$body"
