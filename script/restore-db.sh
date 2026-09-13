#!/usr/bin/env bash
#
# Guided restore of a backup from R2.
#
#   ./restore-db.sh --list                        # what is available
#   ./restore-db.sh                               # newest daily -> a scratch copy
#   ./restore-db.sh --file <name> --target <db>   # a specific dump, somewhere specific
#   ./restore-db.sh --target hp_inventory_production --yes   # the real thing
#
# The default target is a scratch database, not production: the common reason
# to run this is "check what was in yesterday's data", and that should never be
# one typo away from overwriting live data.
#
# docs/backups.md has the fully manual command sequence for the case where this
# script itself is unavailable.

set -Eeuo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=script/backup-config.sh
. "$HERE/config.sh"

FILE=latest
TARGET="${DB_NAME}_restored"
ASSUME_YES=no
LIST_ONLY=no

while [ $# -gt 0 ]; do
  case "$1" in
    --list)   LIST_ONLY=yes; shift ;;
    --file)   FILE=$2; shift 2 ;;
    --target) TARGET=$2; shift 2 ;;
    --yes)    ASSUME_YES=yes; shift ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ "$LIST_ONLY" = yes ]; then
  echo "daily/"
  "$RCLONE" lsl "$REMOTE/daily/" | sort -k4
  echo
  echo "monthly/"
  "$RCLONE" lsl "$REMOTE/monthly/" | sort -k4
  exit 0
fi

if [ "$FILE" = latest ]; then
  FILE=$("$RCLONE" lsf "$REMOTE/daily/" | sort | tail -1)
  [ -n "$FILE" ] || { echo "no backups found under daily/" >&2; exit 1; }
fi

# Accept either a bare name or an explicit daily//monthly/ prefix.
case "$FILE" in
  daily/*|monthly/*) SRC="$REMOTE/$FILE" ;;
  *)                 SRC="$REMOTE/daily/$FILE" ;;
esac
BASE=$(basename "$FILE")

echo "source: $SRC"
echo "target: $TARGET"

if [ "$TARGET" = "$DB_NAME" ]; then
  cat <<WARN

  *** This overwrites the LIVE production database. ***

  Stop the app first, or the restore will fight open connections:

      bin/kamal app stop

  and afterwards:

      bin/kamal app boot

WARN
  if [ "$ASSUME_YES" != yes ]; then
    read -r -p "Type the database name to confirm: " CONFIRM
    [ "$CONFIRM" = "$DB_NAME" ] || { echo "aborted"; exit 1; }
  fi
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"; docker exec "$DB_CONTAINER" rm -f /tmp/restore.dump >/dev/null 2>&1 || true' EXIT

"$RCLONE" copyto "$SRC" "$WORK/$BASE"
echo "downloaded $BASE ($(stat -c%s "$WORK/$BASE") bytes)"

# Fail here rather than half way through the restore if the archive is corrupt.
docker cp "$WORK/$BASE" "$DB_CONTAINER:/tmp/restore.dump"
docker exec "$DB_CONTAINER" pg_restore --list /tmp/restore.dump > /dev/null
echo "archive verified"

if [ "$TARGET" = "$DB_NAME" ]; then
  # Restore in place, replacing existing objects.
  docker exec "$DB_CONTAINER" pg_restore -U "$DB_USER" -d "$TARGET" \
    --clean --if-exists --no-owner /tmp/restore.dump
else
  docker exec "$DB_CONTAINER" dropdb -U "$DB_USER" --if-exists "$TARGET"
  docker exec "$DB_CONTAINER" createdb -U "$DB_USER" "$TARGET"
  docker exec "$DB_CONTAINER" pg_restore -U "$DB_USER" -d "$TARGET" \
    --no-owner /tmp/restore.dump
fi

echo
echo "restored into $TARGET:"
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$TARGET" -c \
  "select (select count(*) from admins) as admins,
          (select count(*) from products) as products,
          (select count(*) from stock_items) as stock_items"
