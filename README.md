#Chalkstack Jupyter Image
Sets up `conda` and `jupyter` in a docker container.
Registers python 2.7, python 3.4 and R kernels.
All under user `cks`, with default password `cks`.

##Installation

Clone the git repository, enter the directory, and build the docker image;

    /media/jake/cksdevs/transnet/build/stackrun.sh
    cd cks-build
    docker build --tag=cks/base ./

Run the docker image;

    docker run -ti --name cks cks/base
