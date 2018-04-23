FROM odoo:10.0
MAINTAINER OpusVL <community@opusvl.com>

USER root

# Install some more fonts and locales
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        fonts-dejavu \
        fonts-dejavu-core \
        fonts-dejavu-extra \
        unzip \
        patch \
        locales-all \
        locales \
    && rm -rf /var/lib/apt/lists/*


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

# Patch O1644 (fixes rendering of binary files with filenames during edit mode)
# [FIX] web: correctly display filename when uploading a file
# Eventually this will start failing to apply, if and when Odoo release a docker image with the patch in
COPY 27d5010fb5cf1fbd733adf0e84fac724f41ce8df.patch /root/
RUN cd /usr/lib/python2.7/dist-packages/odoo ; \
    patch -p1 < /root/27d5010fb5cf1fbd733adf0e84fac724f41ce8df.patch

USER odoo

ONBUILD USER root
ONBUILD COPY ./addon-bundles/ /mnt/extra-addons-bundles/
ONBUILD RUN chmod -R u=rwX,go=rX /mnt/extra-addons-bundles
ONBUILD COPY ./requirements.txt /root/
ONBUILD RUN pip install -r /root/requirements.txt
ONBUILD USER odoo
