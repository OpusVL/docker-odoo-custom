FROM odoo:11.0
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


# Install barcode font
RUN curl http://www.reportlab.com/ftp/pfbfer.zip --output /tmp/pfbfer.zip \
        && mkdir -p /usr/lib/python2.7/dist-packages/reportlab/fonts \
        && unzip /tmp/pfbfer.zip -d /usr/lib/python2.7/dist-packages/reportlab/fonts/

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

# Patch Odoo so it can work with PostgreSQL 10
# Eventually this will start failing to apply, if and when Odoo actually release a docker image with the patch in
COPY 7a4c6eb35d0dd662d2bd992f4725413efbe31a97.patch /root/
RUN set -ex ; \
    apt-get update ; \
    apt-get -y install patch ; \
    cd /usr/lib/python3/dist-packages/odoo ; \
    patch -p2 < /root/7a4c6eb35d0dd662d2bd992f4725413efbe31a97.patch

USER odoo

ONBUILD USER root
ONBUILD COPY ./addon-bundles/ /mnt/extra-addons-bundles/
ONBUILD RUN chmod -R u=rwX,go=rX /mnt/extra-addons-bundles
ONBUILD COPY ./requirements.txt /root/
ONBUILD RUN pip3 install -r /root/requirements.txt
ONBUILD USER odoo
