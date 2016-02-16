#Chalkstack Jupyter Image
Sets up `conda` and `jupyter` in a docker container.
Registers python 2.7, python 3.4 and R kernels.
All under user `cks`, with default password `cks`.

##Installation

###Required files
Certificates and passwords must be provided as separate files, to secure the notebook as documented in [*running a public notebook server](http://jupyter-notebook.readthedocs.org/en/latest/public_server.html#running-a-public-notebook-server).  The Dockerfile requires:

 - `NotebookApp.password`: File containing hashed notebook password for secure connection to the notebook server.
To generate this password use

    from notebookapp.auth import passwd
    passwd()

 - `mycert.pem` and `mykey.key`: Self-signed certificates can be generated with

    openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout mykey.key -out mycert.pem

 - `cks.password`: Linux password for the default (sudoer) user `cks`


###Build

Clone the git repository, generate the required files, enter the directory and build the docker image;

    /media/jake/cksdevs/transnet/build/stackrun.sh
    cd cks-build
    docker build --tag=cks/base ./

Run the docker image;

    docker run -ti --name cks cks/base
