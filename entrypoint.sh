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
list_db = False
data_dir = /var/lib/odoo
max_cron_threads = 1
longpolling_port = False
proxy_mode = True
limit_memory_soft = 671088640
limit_memory_hard = 1342177280
limit_time_cpu = 60
limit_time_real = 120
workers = 2
db_maxconn = 20
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/var/lib/odoo/extra-addons
EOF

  chown odoo:odoo /etc/odoo/odoo.conf
  chmod 640 /etc/odoo/odoo.conf

  # Asegurar directorios dentro del data_dir (especialmente con volumen montado)
  mkdir -p /var/lib/odoo/sessions /var/lib/odoo/filestore /var/lib/odoo/extra-addons

  # Railway monta el volumen con owner/perm que suelen ser root -> hay que corregirlo en runtime
  chown -R odoo:odoo /var/lib/odoo
  chmod 700 /var/lib/odoo/sessions


  if [ -d /opt/bootstrap-addons ] && [ -z "$(ls -A /var/lib/odoo/extra-addons 2>/dev/null)" ]; then
    cp -r /opt/bootstrap-addons/* /var/lib/odoo/extra-addons/
    chown -R odoo:odoo /var/lib/odoo/extra-addons
  fi

  # Modo reparación
  if [ "${RUN_REPAIR}" = "true" ]; then
    if [ -z "${DB_NAME}" ]; then
      echo "ERROR: DB_NAME es obligatorio cuando RUN_REPAIR=true"
      exit 1
    fi

    echo "==> Ejecutando reparación sobre la base ${DB_NAME}"

    cat > /tmp/repair_odoo.sql <<'SQL'
BEGIN;

-- Limpiar assets regenerables
DELETE FROM ir_attachment
WHERE name ILIKE '%assets%'
   OR url ILIKE '/web/content/%assets%';

-- Limpiar cachés web regenerables
DELETE FROM ir_attachment
WHERE url LIKE '/web/content/%';

-- Cerrar sesiones web
DELETE FROM ir_sessions;

-- Desactivar vista problemática hs_code si existe
UPDATE ir_ui_view
SET active = FALSE
WHERE active = TRUE
  AND (
        name = 'product.template.form.hs_code'
        OR arch_db ILIKE '%name="hs_code"%'
      );

-- Desbloquear sesiones POS en control de apertura
UPDATE pos_session
SET state = 'opened'
WHERE state = 'opening_control';

COMMIT;
SQL

    echo "==> Ejecutando SQL de saneado"
    su -s /bin/bash odoo -c "psql \
      --host='${PGHOST}' \
      --port='${PGPORT}' \
      --username='${PGUSER}' \
      --dbname='${DB_NAME}' \
      -f /tmp/repair_odoo.sql"

    echo "==> Actualizando módulos: ${REPAIR_MODULES}"
    exec su -s /bin/bash odoo -c "odoo -c /etc/odoo/odoo.conf \
      --http-port='${HTTP_PORT}' \
      --db_host='${PGHOST}' \
      --db_port='${PGPORT}' \
      --db_user='${PGUSER}' \
      --db_password='${PGPASSWORD}' \
      -d '${DB_NAME}' \
      -u '${REPAIR_MODULES}' \
      --stop-after-init"
  fi

  
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
