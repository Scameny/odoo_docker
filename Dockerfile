FROM odoo:18

USER root

# Dependencias python en un directorio propio
RUN mkdir -p /opt/odoo-python-libs && \
    pip3 install --no-cache-dir --target=/opt/odoo-python-libs \
      openpyxl ofxparse qifparse


ENV PYTHONPATH="/opt/odoo-python-libs:$PYTHONPATH"

COPY ./addons /opt/bootstrap-addons
RUN chown -R odoo:odoo /opt/bootstrap-addons
RUN chown -R odoo:odoo /mnt/extra-addons

# Tu entrypoint si lo necesitas
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]