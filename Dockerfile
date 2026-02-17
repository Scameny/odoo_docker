FROM odoo:18

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]

