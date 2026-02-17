#!/usr/bin/env bash
set -euo pipefail

# Railway expone el puerto HTTP en $PORT
HTTP_PORT="${PORT:-8069}"

# Variables típicas de Railway Postgres: PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD
: "${PGHOST:?PGHOST no está definido}"
: "${PGPORT:?PGPORT no está definido}"
: "${PGDATABASE:?PGDATABASE no está definido}"
: "${PGUSER:?PGUSER no está definido}"
: "${PGPASSWORD:?PGPASSWORD no está definido}"

exec odoo \
  --http-port="${HTTP_PORT}" \
  --db_host="${PGHOST}" \
  --db_port="${PGPORT}" \
  --db_user="${PGUSER}" \
  --db_password="${PGPASSWORD}"
