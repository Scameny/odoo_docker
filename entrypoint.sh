#!/usr/bin/env bash
set -euo pipefail

HTTP_PORT="${PORT:-8069}"

# Requeridas para DB (Railway Postgres)
: "${PGHOST:?PGHOST no está definido}"
: "${PGPORT:?PGPORT no está definido}"
: "${PGUSER:?PGUSER no está definido}"
: "${PGPASSWORD:?PGPASSWORD no está definido}"

# Requerida para habilitar /web/database/manager (master password)
: "${ODOO_MASTER_PASSWORD:?Define ODOO_MASTER_PASSWORD en Railway Variables}"

# ODOO_EXTRA_ARGS debe ser opcional (puede estar vacío/no definido)
ODOO_EXTRA_ARGS="${ODOO_EXTRA_ARGS:-}"

# Escribir odoo.conf (necesita root)
if [ "$(id -u)" -eq 0 ]; then
  cat > /etc/odoo/odoo.conf <<EOF
[options]
admin_passwd = ${ODOO_MASTER_PASSWORD}
list_db = True
data_dir = /var/lib/odoo
max_cron_threads = 1
longpolling_port = False
limit_memory_soft = 536870912
limit_memory_hard = 1073741824
limit_time_cpu = 60
limit_time_real = 120
EOF

  chown odoo:odoo /etc/odoo/odoo.conf
  chmod 640 /etc/odoo/odoo.conf

  exec su -s /bin/bash odoo -c "odoo -c /etc/odoo/odoo.conf \
    --http-port='${HTTP_PORT}' \
    --db_host='${PGHOST}' \
    --db_port='${PGPORT}' \
    --db_user='${PGUSER}' \
    --db_password='${PGPASSWORD}' \
    ${ODOO_EXTRA_ARGS}"
else
  echo "ERROR: entrypoint debe ejecutarse como root para escribir /etc/odoo/odoo.conf"
  exit 1
fi
