#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

BUNDLE_DIR="${1:?Usage: verify-supabase-backup.sh /opt/backups/supabase/daily/<timestamp>}"
[[ -d "$BUNDLE_DIR" ]] || { echo 'Backup bundle does not exist.' >&2; exit 1; }
( cd "$BUNDLE_DIR" && sha256sum --check manifest.sha256 )

IMAGE="$(awk -F= '$1 == "postgres_image" {print $2}' "$BUNDLE_DIR/manifest.env")"
[[ -n "$IMAGE" ]] || { echo 'postgres_image missing from manifest.' >&2; exit 1; }
NAME="financeiro-backup-verify-$(date +%s)"
PASSWORD="$(openssl rand -hex 24)"
cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

# The Supabase image normally bootstraps its own schemas.  Start a pristine
# cluster from the same image so the logical dump is tested without colliding
# with those bootstrap objects.
docker run -d --rm --name "$NAME" --network none --user postgres -e POSTGRES_PASSWORD="$PASSWORD" \
  --entrypoint bash "$IMAGE" -lc '
    set -Eeuo pipefail
    export PGDATA=/tmp/financeiro-restore-check
    initdb -D "$PGDATA" --auth-local=trust --auth-host=scram-sha-256 >/dev/null
    pg_ctl -D "$PGDATA" -o "-c listen_addresses=''" -w start >/dev/null
    tail -f /dev/null
  ' >/dev/null
for _ in $(seq 1 60); do
  if docker exec "$NAME" pg_isready -U postgres -d postgres >/dev/null 2>&1; then break; fi
  sleep 2
done
docker exec "$NAME" pg_isready -U postgres -d postgres >/dev/null

# A restore runs in a disposable cluster with the exact production image.
docker cp "$BUNDLE_DIR/postgres.dump" "$NAME:/tmp/postgres.dump"
docker cp "$BUNDLE_DIR/postgres-globals.sql" "$NAME:/tmp/postgres-globals.sql"
docker exec --user root "$NAME" chown postgres:postgres /tmp/postgres.dump /tmp/postgres-globals.sql
docker exec "$NAME" psql -U postgres -d postgres -f /tmp/postgres-globals.sql >/dev/null
docker exec "$NAME" pg_restore -U postgres -d postgres --no-owner /tmp/postgres.dump >/dev/null
docker exec "$NAME" psql -U postgres -d postgres -v ON_ERROR_STOP=1 -Atqc "select count(*) from pg_catalog.pg_class" >/dev/null

echo "Restore verification completed successfully with $IMAGE"
