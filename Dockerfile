FROM debian:jessie
MAINTAINER OpusVL <community@opusvl.com>

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
  apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    node-less \
    fonts-dejavu \
    fonts-dejavu-core \
    fonts-dejavu-extra \
    locales-all \
    locales \
    node-clean-css \
    python-gevent \
    python-pip \
    python-pyinotify \
    python-renderpm \
    python-support \
    unzip \
  && curl -o wkhtmltox.deb -SL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.2/wkhtmltox-0.12.2_linux-jessie-amd64.deb \
  && echo 'b6309d2bc45b6f97ad7f208810d468369a94d5c9 wkhtmltox.deb' | sha1sum -c - \
  && dpkg --force-depends -i wkhtmltox.deb \
  && apt-get -y install -f --no-install-recommends \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
  && rm -rf /var/lib/apt/lists/* wkhtmltox.deb \
  && pip install psycogreen==1.0

# install latest postgresql-client
RUN set -x; \
        echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' > etc/apt/sources.list.d/pgdg.list \
        && export GNUPGHOME="$(mktemp -d)" \
        && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
        && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
        && gpg --armor --export "${repokey}" | apt-key add - \
        && rm -rf "$GNUPGHOME" \
        && apt-get update  \
        && apt-get install -y postgresql-client \
        && rm -rf /var/lib/apt/lists/*

# Install Odoo
ENV ODOO_VERSION 8.0
ENV ODOO_RELEASE 20171001
RUN set -x; \
        curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && echo 'c41c6eaf93015234b4b62125436856a482720c3d odoo.deb' | sha1sum -c - \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb

# Install barcode font
RUN set -x; \
        curl -o pfbfer.zip -SL http://www.reportlab.com/ftp/pfbfer.zip \
        && mkdir -p /usr/lib/python2.7/dist-packages/reportlab/fonts \
        && unzip pfbfer.zip -d /usr/lib/python2.7/dist-packages/reportlab/fonts/

# Generate British locales, as this is who we mostly serve
RUN locale-gen en_GB.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB:en
ENV LC_ALL en_GB.UTF-8

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./openerp-server.conf /etc/odoo/

# This custom entypoint augments the environment variables and the command line, and then despatches to the upstream /entrypoint.sh
COPY ./opusvl-entrypoint.py /
RUN chmod a+rx /opusvl-entrypoint.py

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /var/lib/odoo \
        && chown -R odoo /var/lib/odoo
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
RUN mkdir /mnt/extra-addons-bundles \
        && chmod -R 755 /mnt/extra-addons-bundles

VOLUME ["/var/lib/odoo"]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV OPENERP_SERVER /etc/odoo/openerp-server.conf


ENTRYPOINT ["/opusvl-entrypoint.py"]

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
ONBUILD COPY ./openerp-server.conf /etc/odoo/
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
# ONBUILD RUN apt-get -y autoremove gcc g++

# Set default user when running the container
USER odoo
