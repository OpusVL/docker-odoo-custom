# docker-odoo-custom
An Odoo docker image with extended capabilities and fixes over the official one

# Addons Bundles

An `--addons-path` argument is automatically built on each startup to contain any subdirectories within `/mnt/extra-addon-bundles` that contain at least one valid Odoo addon.

So you can check out a set of modules directly into there (in a volume or copied in via a Dockerfile extending this one) and have Odoo pick them up, instead of having to flatten the tree yourself or manually build an addons_path in the config file.

# Developer Mode

Setting the `DEV_ODOO` environment variable to a path, e.g. `/opt/odoo`, where you have
mounted a git clone of an Odoo source tree, will cause that path to be prepended to the
PATH and the default addons path to point to it.
