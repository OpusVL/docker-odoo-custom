FROM odoo:8.0
MAINTAINER OpusVL <community@opusvl.com>

USER root

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
