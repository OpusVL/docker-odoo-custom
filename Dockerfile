FROM odoo:9.0
MAINTAINER OpusVL <community@opusvl.com>

USER root
ENV PG_MAJOR 10

# Install some more fonts and locales
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        fonts-dejavu \
        fonts-dejavu-core \
        fonts-dejavu-extra \
        unzip \
        locales-all \
        locales \
    && rm -rf /var/lib/apt/lists/*


COPY odoo-pg-client-gpg-key.asc /
RUN cat /odoo-pg-client-gpg-key.asc | apt-key add -
RUN set -ex; \
   echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main $PG_MAJOR" > /etc/apt/sources.list.d/pgdg.list; \
           apt-get update ; \
apt-get -y install "postgresql-client-$PG_MAJOR" postgresql-client-9.4-

# Generate British locales, as this is who we mostly serve
RUN locale-gen en_GB.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB:en
ENV LC_ALL en_GB.UTF-8

RUN mkdir /mnt/extra-addons-bundles && chmod -R o+rX /mnt/extra-addons-bundles

# Put this in your bundle:
# COPY addons-bundles/ /mnt/extra-addons-bundles/
# RUN chmod -R o+rX /mnt/extra-addons-bundles

# This custom entypoint augments the environment variables and the command line, and then despatches to the upstream /entrypoint.sh
COPY opusvl-entrypoint.py /
RUN chmod a+rx /opusvl-entrypoint.py
ENTRYPOINT ["/opusvl-entrypoint.py"]

USER odoo
