#!/usr/bin/env bash
#
# Nightly off-site backup of the production database.
#
# Dumps the primary database out of the Kamal Postgres accessory, verifies the
# archive is readable, uploads it to Cloudflare R2, and reports the outcome to
# Healthchecks.io. Run from cron as `deployer`; see config/backup.crontab.
#
# Only the primary database is dumped. hp_inventory_production_{cache,queue,cable}
# are Solid Cache/Queue/Cable scratch space and are recreated by `db:prepare`.

set -Eeuo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=script/backup-config.sh
. "$HERE/config.sh"

STAMP=$(date -u +%Y%m%dT%H%M%SZ)
NAME="${DB_NAME}-${STAMP}.dump"
WORK=$(mktemp -d)
LOG=$(mktemp)

# Keep the real stdout/stderr on fd 3/4 and send everything else to $LOG, so
# the exit trap can post the output as the Healthchecks body and still echo it
# to cron afterwards. Writing to the file directly (rather than through `tee`)
# means the trap never races a buffered writer.
exec 3>&1 4>&2
exec >>"$LOG" 2>&1

# $1 is the ping suffix: "" for success, /start or /fail otherwise. The log tail
# rides along as the body so a failure alert arrives with the error in it.
hc() {
  local suffix=${1:-}
  [ -n "${HEALTHCHECKS_BACKUP_URL:-}" ] || return 0
  curl -fsS -m 10 --retry 3 -o /dev/null \
    --data-raw "$(tail -c 9000 "$LOG")" \
    "${HEALTHCHECKS_BACKUP_URL}${suffix}" || true
}

finish() {
  local rc=$?
  docker exec "$DB_CONTAINER" rm -f "/tmp/$NAME" >/dev/null 2>&1 || true
  rm -rf "$WORK"
  if [ "$rc" -ne 0 ]; then
    echo "FAILED (exit $rc)"
    hc /fail
  fi
  cat "$LOG" >&3
  rm -f "$LOG"
}
trap finish EXIT

echo "$(date -u +%FT%TZ) starting backup of $DB_NAME"
hc /start

# Dump and prove the archive is readable, both inside the container.
# pg_restore --list parses the whole TOC, so a truncated or corrupt dump fails
# here rather than months later during a real restore.
docker exec "$DB_CONTAINER" bash -c \
  "pg_dump -U '$DB_USER' -d '$DB_NAME' -Fc --no-owner --no-privileges -f '/tmp/$NAME' \
   && pg_restore --list '/tmp/$NAME' > /dev/null"
docker cp "$DB_CONTAINER:/tmp/$NAME" "$WORK/$NAME"

SIZE=$(stat -c%s "$WORK/$NAME")
if [ "$SIZE" -lt "$MIN_DUMP_BYTES" ]; then
  echo "dump is $SIZE bytes, below the $MIN_DUMP_BYTES floor -- refusing to upload"
  exit 1
fi

"$RCLONE" copyto "$WORK/$NAME" "$REMOTE/daily/$NAME"
echo "uploaded daily/$NAME ($SIZE bytes)"

# Keep a yearly-retained copy on the first of the month. An `if` rather than a
# `[ ] && cmd` one-liner: under `set -e` a false test in an AND list aborts the
# script, which would turn the other 30 days of the month into failed runs.
if [ "$(date -u +%d)" = "01" ]; then
  "$RCLONE" copyto "$WORK/$NAME" "$REMOTE/monthly/$NAME"
  echo "uploaded monthly/$NAME"
fi

echo "$(date -u +%FT%TZ) backup complete"
hc
