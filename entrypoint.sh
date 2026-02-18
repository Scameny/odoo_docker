#!/usr/bin/env bash
set -euo pipefail

# Railway expone el puerto HTTP en $PORT
HTTP_PORT="${PORT:-8069}"

# Variables típicas de Railway Postgres: PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD
: "${PGHOST:?PGHOST no está definido}"
: "${PGPORT:?PGPORT no está definido}"
: "${PGUSER:?PGUSER no está definido}"
: "${PGPASSWORD:?PGPASSWORD no está definido}"
: "${ODOO_EXTRA_ARGS:?ODOO_EXTRA_ARGS no está definido}"
: "${ODOO_MASTER_PASSWORD:?Define ODOO_MASTER_PASSWORD en Railway Variables}"

if [ "$(id -u)" -eq 0 ]; then
  cat > /etc/odoo/odoo.conf <<EOF
[options]
admin_passwd = ${ODOO_MASTER_PASSWORD}
list_db = True
data_dir = /var/lib/odoo
EOF

chown odoo:odoo /etc/odoo/odoo.conf
chmod 640 /etc/odoo/odoo.conf

# Ejecutar odoo como usuario odoo
exec su -s /bin/bash odoo -c "odoo --http-port='${HTTP_PORT}' \
  --db_host='${PGHOST}' --db_port='${PGPORT}' --db_user='${PGUSER}' --db_password='${PGPASSWORD}' \
  ${ODOO_EXTRA_ARGS:-""}"