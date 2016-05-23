# Chalkstack Jupyter Image
Contains:
 - latest `jupyter` on `python 3.5` running by default on port 8899, configurable with `jupyter_notebook_config.py` file.
 - `python 2.7` conda kernel
 - `python 3.5` root conda kernel
 - `Spark 1.6.0` configurable with `spark-env.sh` and `spark-defaults.conf`.

Registers python 2.7 and python 3.5 kernels.
Installs Spark for pyspark.
Default username is `cks` with default password for notebook and root access `cks`.

Requires the following files to build:
 - `mycert.pem`
 - `mykey.key`
 - `NotebookApp.password` - Jupyter password, quoted in "'" and hashed as described at [jupyter-notebook.readthedocs](https://jupyter-notebook.readthedocs.io/en/stable/public_server.html#preparing-a-hashed-password).
 - `cks.password` - password for sudo
