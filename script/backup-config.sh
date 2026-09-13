# Shared configuration for the database backup scripts. Sourced, never executed.
#
# Everything here is overridable from the environment so the scripts can be
# pointed at a different host, container, or bucket without editing them.
#
# Installed to /home/deployer/backup/config.sh by bin/backup-install.

# Absolute path, deliberately. Ubuntu ships rclone 1.60 at /usr/bin/rclone,
# which fails against Cloudflare R2 with "NotImplemented: 501" on every upload.
# The working build lives in ~/bin, and cron neither reads .profile nor puts
# ~/bin on PATH -- so a bare `rclone` in a cron job silently gets the broken one.
RCLONE=${RCLONE:-/home/deployer/bin/rclone}

# Remote name contains spaces, so every use of it must stay quoted.
REMOTE=${REMOTE:-"Cloudflare R2 db backups:hp-inventory-db-backups"}

# The Kamal accessory. Dumping through `docker exec` guarantees the pg_dump
# version always matches the Postgres actually running, and the official image
# trusts local-socket connections so no password is needed.
DB_CONTAINER=${DB_CONTAINER:-inventory-db}
DB_NAME=${DB_NAME:-hp_inventory_production}
DB_USER=${DB_USER:-hp_inventory}

BACKUP_HOME=${BACKUP_HOME:-/home/deployer/backup}

# A dump smaller than this means pg_dump produced a stub rather than a backup.
# The real thing is ~60 KB today; an empty-schema dump is under 5 KB.
MIN_DUMP_BYTES=${MIN_DUMP_BYTES:-10000}

# Throwaway database used by verify-backup.sh. Never a real database name.
VERIFY_DB=${VERIFY_DB:-backup_verify}

# HEALTHCHECKS_BACKUP_URL / HEALTHCHECKS_VERIFY_URL. Written mode 600 by
# bin/backup-install from the encrypted production credentials; absent on
# developer machines, where the scripts simply skip pinging.
if [ -r "$BACKUP_HOME/secrets.env" ]; then
  . "$BACKUP_HOME/secrets.env"
fi
