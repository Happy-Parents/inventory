#!/usr/bin/env bash
#
# Weekly proof that the backups are actually restorable.
#
# Pulls the newest object from daily/, restores it into a throwaway database,
# asserts the schema and the data both arrived, then drops it. A dump that
# uploads cleanly but cannot be restored is not a backup, and the only way to
# know the difference is to restore it on a schedule.
#
# Run from cron as `deployer`; see config/backup.crontab.

set -Eeuo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=script/backup-config.sh
. "$HERE/config.sh"

# How old the newest backup may be before this counts as a failure. Catches the
# case where uploads quietly stopped but this job keeps happily restoring an
# ever-older dump.
MAX_AGE_HOURS=${MAX_AGE_HOURS:-48}

WORK=$(mktemp -d)
LOG=$(mktemp)

exec 3>&1 4>&2
exec >>"$LOG" 2>&1

hc() {
  local suffix=${1:-}
  [ -n "${HEALTHCHECKS_VERIFY_URL:-}" ] || return 0
  curl -fsS -m 10 --retry 3 -o /dev/null \
    --data-raw "$(tail -c 9000 "$LOG")" \
    "${HEALTHCHECKS_VERIFY_URL}${suffix}" || true
}

finish() {
  local rc=$?
  docker exec "$DB_CONTAINER" dropdb -U "$DB_USER" --if-exists "$VERIFY_DB" >/dev/null 2>&1 || true
  docker exec "$DB_CONTAINER" rm -f /tmp/verify.dump >/dev/null 2>&1 || true
  rm -rf "$WORK"
  if [ "$rc" -ne 0 ]; then
    echo "FAILED (exit $rc)"
    hc /fail
  fi
  cat "$LOG" >&3
  rm -f "$LOG"
}
trap finish EXIT

psql_verify() {
  docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$VERIFY_DB" -tAc "$1"
}

echo "$(date -u +%FT%TZ) starting restore verification"
hc /start

LATEST=$("$RCLONE" lsf "$REMOTE/daily/" | sort | tail -1)
if [ -z "$LATEST" ]; then
  echo "no objects under daily/ -- nothing has ever been backed up"
  exit 1
fi
echo "newest backup: $LATEST"

# Filenames carry a UTC stamp (…-20260912T021500Z.dump); reshape it into
# something date(1) will parse so staleness can be checked without trusting
# object metadata.
RAW=$(echo "$LATEST" | sed -E 's/.*-([0-9]{8})T([0-9]{6})Z\.dump$/\1T\2Z/')
ISO=$(echo "$RAW" | sed -E 's/^(....)(..)(..)T(..)(..)(..)Z$/\1-\2-\3T\4:\5:\6Z/')
AGE_HOURS=$(( ( $(date -u +%s) - $(date -u -d "$ISO" +%s) ) / 3600 ))
if [ "$AGE_HOURS" -gt "$MAX_AGE_HOURS" ]; then
  echo "newest backup is ${AGE_HOURS}h old, over the ${MAX_AGE_HOURS}h limit"
  exit 1
fi
echo "age: ${AGE_HOURS}h (limit ${MAX_AGE_HOURS}h)"

"$RCLONE" copyto "$REMOTE/daily/$LATEST" "$WORK/$LATEST"
docker cp "$WORK/$LATEST" "$DB_CONTAINER:/tmp/verify.dump"

docker exec "$DB_CONTAINER" dropdb -U "$DB_USER" --if-exists "$VERIFY_DB"
docker exec "$DB_CONTAINER" createdb -U "$DB_USER" "$VERIFY_DB"
docker exec "$DB_CONTAINER" pg_restore -U "$DB_USER" -d "$VERIFY_DB" --no-owner /tmp/verify.dump

# Assert the restore is real rather than merely exit-code-zero: the core tables
# must exist, and the two that can never legitimately be empty must have rows.
TABLES=$(psql_verify "select count(*) from information_schema.tables
                      where table_schema='public' and table_name in
                      ('admins','brands','categories','products','stock_items','warehouses')")
if [ "$TABLES" != "6" ]; then
  echo "expected 6 core tables in the restore, found $TABLES"
  exit 1
fi

ADMINS=$(psql_verify "select count(*) from admins")
PRODUCTS=$(psql_verify "select count(*) from products")
if [ "$ADMINS" -lt 1 ] || [ "$PRODUCTS" -lt 1 ]; then
  echo "restored schema but no data: admins=$ADMINS products=$PRODUCTS"
  exit 1
fi

echo "verified $LATEST: 6/6 core tables, $ADMINS admins, $PRODUCTS products"
echo "$(date -u +%FT%TZ) verification complete"
hc
