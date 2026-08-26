#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

BACKUP_ROOT=/opt/backups/supabase
DAILY_DIR="$BACKUP_ROOT/daily"
WEEKLY_DIR="$BACKUP_ROOT/weekly"
MONTHLY_DIR="$BACKUP_ROOT/monthly"
PORTAINER_COMPOSE=/var/lib/docker/volumes/portainer_data/_data/compose/6/docker-compose.yml
TRAEFIK_CONFIG=/root/traefik.yaml

require_command() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1" >&2; exit 1; }; }
require_command docker
require_command sha256sum
require_command find

for directory in "$DAILY_DIR" "$WEEKLY_DIR" "$MONTHLY_DIR"; do
  install -d -m 0700 "$directory"
done

POSTGRES_CONTAINER="$(docker ps --filter 'label=com.docker.swarm.service.name=supabase_supabase_db' --format '{{.ID}}' | head -n 1)"
if [[ -z "$POSTGRES_CONTAINER" ]]; then
  echo 'Supabase PostgreSQL container not found.' >&2
  exit 1
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
TEMP_DIR="$(mktemp -d "$DAILY_DIR/.${STAMP}.XXXXXX")"
cleanup() { rm -rf -- "$TEMP_DIR"; }
trap cleanup EXIT

mkdir -p "$TEMP_DIR/config"

docker exec "$POSTGRES_CONTAINER" pg_dumpall -U postgres --globals-only > "$TEMP_DIR/postgres-globals.sql"
docker exec "$POSTGRES_CONTAINER" pg_dump -U postgres -d postgres --format=custom > "$TEMP_DIR/postgres.dump"

docker run --rm \
  --mount type=volume,src=supabase_storage,dst=/source,readonly \
  --mount type=bind,src="$TEMP_DIR",dst=/backup \
  alpine:3.20 tar -C /source -czf /backup/supabase-storage.tar.gz .

if [[ -f "$PORTAINER_COMPOSE" ]]; then
  install -m 0600 "$PORTAINER_COMPOSE" "$TEMP_DIR/config/portainer-supabase-compose.yml"
fi
if [[ -f "$TRAEFIK_CONFIG" ]]; then
  install -m 0600 "$TRAEFIK_CONFIG" "$TEMP_DIR/config/traefik.yaml"
fi
{
  echo "created_at_utc=$STAMP"
  echo "host=$(hostname -f 2>/dev/null || hostname)"
  echo "docker=$(docker version --format '{{.Server.Version}}')"
  echo "postgres_image=$(docker inspect "$POSTGRES_CONTAINER" --format '{{.Config.Image}}')"
  echo "postgres_version=$(docker exec "$POSTGRES_CONTAINER" psql -U postgres -d postgres -Atqc 'show server_version')"
  echo "storage_volume=supabase_storage"
} > "$TEMP_DIR/manifest.env"
( cd "$TEMP_DIR" && find . -type f ! -name manifest.sha256 -print0 | sort -z | xargs -0 sha256sum ) > "$TEMP_DIR/manifest.sha256"

FINAL_DIR="$DAILY_DIR/$STAMP"
mv "$TEMP_DIR" "$FINAL_DIR"
trap - EXIT

copy_set() {
  local destination="$1"
  local label="$2"
  cp -al "$FINAL_DIR" "$destination/$label" 2>/dev/null || cp -a "$FINAL_DIR" "$destination/$label"
}
[[ "$(date -u +%u)" == 7 ]] && copy_set "$WEEKLY_DIR" "$STAMP"
[[ "$(date -u +%d)" == 01 ]] && copy_set "$MONTHLY_DIR" "$STAMP"

prune_sets() {
  local directory="$1"
  local keep="$2"
  local -a entries=()
  mapfile -t entries < <(find "$directory" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -nr | awk '{print $2}')
  if (( ${#entries[@]} > keep )); then
    local entry
    for entry in "${entries[@]:keep}"; do
      rm -rf -- "$entry"
    done
  fi
}
prune_sets "$DAILY_DIR" 7
prune_sets "$WEEKLY_DIR" 4
prune_sets "$MONTHLY_DIR" 12

echo "Backup completed: $FINAL_DIR"
