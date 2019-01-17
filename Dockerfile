FROM odoo:10.0
MAINTAINER OpusVL <community@opusvl.com>

USER root

# Install some more fonts and locales, and common build requirements
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        fonts-dejavu \
        fonts-dejavu-core \
        fonts-dejavu-extra \
        unzip \
        patch \
        locales-all \
        locales \
        gnupg \
        build-essential \
        python2.7-dev \
    && rm -rf /var/lib/apt/lists/*

### MAKE DATABASE MANAGER WORK WITH PostgreSQL 10 ###
# pub   4096R/ACCC4CF8 2011-10-13 [expires: 2019-07-02]
#       Key fingerprint = B97B 0AFC AA1A 47F0 44F2  44A0 7FCC 7D46 ACCC 4CF8
# uid                  PostgreSQL Debian Repository
ENV PG_MAJOR 10
RUN set -ex; \
    key='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8'; \
    export GNUPGHOME="$(mktemp -d)"; \
    ( \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" \
    || gpg --keyserver pgp.mit.edu --recv-keys "$key" \
    || gpg --keyserver keyserver.pgp.com --recv-keys "$key" \
  ) ; \
    gpg --export "$key" > /etc/apt/trusted.gpg.d/postgres.gpg; \
    rm -rf "$GNUPGHOME"; \
  apt-key list
RUN set -ex; \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main $PG_MAJOR" > /etc/apt/sources.list.d/pgdg.list; \
            apt-get update ; \
apt-get -y install "postgresql-client-$PG_MAJOR" postgresql-client-9.4-

# Install barcode font
COPY pfbfer.zip /root/pfbfer.zip
RUN mkdir -p /usr/lib/python2.7/dist-packages/reportlab/fonts \
        && unzip /root/pfbfer.zip -d /usr/lib/python2.7/dist-packages/reportlab/fonts/

# Generate British locales, as this is who we mostly serve
RUN locale-gen en_GB.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB:en
ENV LC_ALL en_GB.UTF-8

RUN mkdir /mnt/extra-addons-bundles && chmod -R 755 /mnt/extra-addons-bundles

COPY ./odoo.conf /etc/odoo/

# This custom entypoint augments the environment variables and the command line, and then despatches to the upstream /entrypoint.sh
COPY opusvl-entrypoint.py /
RUN chmod a+rx /opusvl-entrypoint.py
ENTRYPOINT ["/opusvl-entrypoint.py"]

USER odoo

ONBUILD USER root
ONBUILD COPY ./addon-bundles/ /mnt/extra-addons-bundles/
ONBUILD RUN chmod -R u=rwX,go=rX /mnt/extra-addons-bundles
# If copy of build-hooks breaks your build:
#  mkdir build-hooks
#  touch build-hooks/.gitkeep
#  git add build-hooks/.gitkeep
# Introducing a directory for hooks means we can add more in
# future and allow you to add your own helper scripts without
# breaking the build again.
ONBUILD COPY ./build-hooks/ /root/build-hooks/
ONBUILD COPY ./requirements.txt /root/
ONBUILD RUN \
    pre_pip_hook="/root/build-hooks/pre-pip.sh" ; \
    if [ -f "$pre_pip_hook" ] ; \
    then \
        /bin/bash -x -e "$pre_pip_hook" \
            # reduce size of layer - probably last time we'll install anything using apt anyway \
            && rm -rf /var/lib/apt/lists/* \
            ; \
    fi
ONBUILD RUN pip install -r /root/requirements.txt
# Remove compiler for security in production
ONBUILD RUN apt-get -y autoremove gcc g++
