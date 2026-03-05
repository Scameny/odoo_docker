FROM odoo:18

USER root
COPY entrypoint.sh /entrypoint.sh
# Install qifparse to a custom directory
RUN pip3 install --target=/opt/qiflibs qifparse
# Add that directory to PYTHONPATH
ENV PYTHONPATH="/opt/qiflibs:$PYTHONPATH"
RUN chmod +x /entrypoint.sh


ENTRYPOINT ["/entrypoint.sh"]

CMD ["odoo"]

