FROM odoo:18

USER root

# (Opcional pero recomendable) actualiza pip
RUN pip3 install --no-cache-dir -U pip

# Dependencias del módulo base_accounting_kit
RUN pip3 install --no-cache-dir openpyxl ofxparse

# qifparse: el módulo recomienda instalarlo en un target y añadir PYTHONPATH (para Docker)
RUN pip3 install --no-cache-dir --target=/opt/qiflibs qifparse
ENV PYTHONPATH="/opt/qiflibs:$PYTHONPATH"

# Tu entrypoint si lo necesitas
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER odoo
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]