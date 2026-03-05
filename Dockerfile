FROM odoo:18

USER root

# Dependencias python en un directorio propio
RUN mkdir -p /opt/odoo-python-libs && \
    pip3 install --no-cache-dir --target=/opt/odoo-python-libs \
      openpyxl ofxparse qifparse

ENV PYTHONPATH="/opt/odoo-python-libs:$PYTHONPATH"


# Ajusta permisos para el usuario odoo (UID típico 101 en imagen oficial, pero mejor por nombre)
RUN chown -R odoo:odoo /var/lib/odoo

# Tu entrypoint si lo necesitas
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]