FROM debian:stable
RUN apt-get update && apt-get -y upgrade && apt-get -y install python3-pip
RUN python3 -m pip install sqlalchemy psycopg2-binary
COPY ./setup_rita.sh /setup_rita.sh
RUN chmod +x /setup_rita.sh && bash /setup_rita.sh
COPY ./config.yaml /etc/rita/config.yaml
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
COPY ./refresh-database.py /refresh-database.py
CMD ["bash", "/docker-entrypoint.sh"]
