# docker-odoo-custom
An Odoo docker image with extended capabilities and fixes over the official one

# Locales

Locales are generated for en_GB, and are set as default in the environment.

# Extra fonts

* fonts-dejavu
* fonts-dejavu-extra
* Reportlab barcode font

# Addons Bundles

An `--addons-path` argument is automatically built on each startup to contain any subdirectories within `/mnt/extra-addons-bundles` that contain at least one valid Odoo addon.  This could be a checkout of a repository from https://github.com/OCA for example.

So you can check out a set of modules directly into there (in a volume or copied in via a Dockerfile extending this one) and have Odoo pick them up, instead of having to flatten the tree yourself or manually build an addons_path in the config file.

## Serving Suggestion

Create a git repo with the following structure:

* a directory `addons-bundles` containing the repositories we are using modules from as git submodules (though sometimes customer-specific modules live in a plain subdirectory of this directory),
* a `Dockerfile`

The Dockerfile might have something like this in it:

```
FROM quay.io/opusvl/odoo-custom:8.0

USER root

COPY addons-bundles/ /mnt/extra-addons-bundles
RUN chmod -R o+rX /mnt/extra-addons-bundles

USER odoo
```

# Run Odoo from a git checkout

Setting the `DEV_ODOO` environment variable to a path, e.g. `/opt/odoo`, where you have
mounted a git clone of an Odoo source tree, will cause that path to be prepended to the
PATH and the default addons path to point to it.

# Old DB config environment variables still work

EXPERIMENTAL

The `DB*` environment variables we have in our existing docker-compose setups are, if set, copied to the new equivalents as of about 6 months ago.

This is for backwards compatibility with existing environments that are configured using the `DB*` variables.  If they are set, then they will override the official ones - depending on internal feedback or feedback from you, the community, we may change the priorities so consider this particular bit experimental.


# How it works

There is a new entrypoint `opusvl-entrypoint.py` which augments environment variables and the command line with its own stuff depending on environment variables you set and what it finds in `/mnt/extra-addons-bundles`, then despatches to the upstream `entrypoint.sh`, re-using the logic contained therein.
