# Chalkstack base image
#    sets up ubuntu, conda and jupyter and registers std python envs.

#   Copyright 2016 Jake Bouma
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

FROM ubuntu:14.04
MAINTAINER Jake Bouma <jake@chalkstack.co.za>
ENV DEBIAN_FRONTEND noninteractive
ENV USERID 1001
ENV USERNAME cks
ENV CONDA_DIR /miniconda

RUN apt-get update && apt-get install -y curl jq

# Add a default user $USERNAME
RUN useradd -c 'Notebook User' -m -d /home/$USERNAME -u $USERID -s "/bin/bash" $USERNAME \
    && echo "$USERNAME:$USERNAME" | chpasswd \
    && adduser $USERNAME sudo

# Install miniconda for user $USERNAME
USER root
RUN curl -LO http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -p $CONDA_DIR -b
RUN chown -R $USERNAME:$USERNAME $CONDA_DIR
USER $USERNAME
ENV PATH=${CONDA_DIR}/bin:${PATH}
RUN conda update -y conda

# Install Jupyter
RUN conda install -y jupyter ipyparallel
RUN mkdir /home/${USERNAME}/.jupyter
COPY jupyter_notebook_config.py /home/cks/.jupyter/jupyter_notebook_config.py

##################################
# Installation of Spark and Mesos follows steps at
#    https://github.com/jupyter/docker-stacks/blob/master/pyspark-notebook/Dockerfile
##################################
USER root

# Spark dependencies
ENV APACHE_SPARK_VERSION 1.6.0
RUN apt-get -y update && \
    apt-get install -y --no-install-recommends openjdk-7-jre-headless wget

RUN cd /tmp && \
        wget -q http://d3kbcqa49mib13.cloudfront.net/spark-${APACHE_SPARK_VERSION}-bin-hadoop2.6.tgz && \
        echo "439fe7793e0725492d3d36448adcd1db38f438dd1392bffd556b58bb9a3a2601 *spark-${APACHE_SPARK_VERSION}-bin-hadoop2.6.tgz" | sha256sum -c - && \
        tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop2.6.tgz -C /usr/local && \
        rm spark-${APACHE_SPARK_VERSION}-bin-hadoop2.6.tgz
RUN cd /usr/local && ln -s spark-${APACHE_SPARK_VERSION}-bin-hadoop2.6 spark

# Mesos dependencies
RUN sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E56151BF && \
    DISTRO=ubuntu && \
    CODENAME=trusty && \
    echo "deb http://repos.mesosphere.io/${DISTRO} ${CODENAME} main" > /etc/apt/sources.list.d/mesosphere.list && \
    apt-get -y update && \
    apt-get install -y mesos

# Spark and Mesos config
ENV SPARK_HOME /usr/local/spark
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.9-src.zip
ENV MESOS_NATIVE_LIBRARY /usr/local/lib/libmesos.so
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info

##################################

# Install and register a python2.7 kernel
USER $USERNAME
RUN conda create --quiet --yes -p $CONDA_DIR/envs/py27 python=2.7 \
    'ipython' \
    'ipywidgets' \
    pyzmq \
    && conda clean -tipsy
RUN bash -c '. activate py27 && \
    python -m ipykernel install --name=py27 --display-name="Python 2.7 (py27)" --prefix=$CONDA_DIR && \
    . deactivate'
# Set PYSPARK_HOME in the python2 spec
RUN jq --arg v "${CONDA_DIR}/envs/py27/bin/python" \
        '.["env"]["PYSPARK_PYTHON"]=$v' \
        ${CONDA_DIR}/share/jupyter/kernels/py27/kernel.json > /tmp/kernel.json && \
        mv /tmp/kernel.json $CONDA_DIR/share/jupyter/kernels/py27/kernel.json

# Add Tini. Tini operates as a process subreaper for jupyter. This prevents
# kernel crashes.
USER root
ENV TINI_VERSION v0.9.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]

# Secure
# https://jupyter-notebook.readthedocs.io/en/stable/public_server.html#adding-hashed-password-to-your-notebook-configuration-file
USER root
COPY NotebookApp.password /etc/cks/NotebookApp.password
COPY cks.password /etc/cks/cks.password
COPY mycert.pem /etc/cks/mycert.pem
COPY mykey.key /etc/cks/mykey.key
RUN echo c.NotebookApp.password = u$(cat /etc/cks/NotebookApp.password) >> /home/${USERNAME}/.jupyter/jupyter_notebook_config.py
RUN echo "cks:$(cat /etc/cks/cks.password)" | chpasswd
RUN rm /etc/cks/*.password

# Spark config files
ADD spark-* /tmp/
RUN cp /tmp/spark-* ${SPARK_HOME}/conf/

# Clean up
USER root
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN rm Miniconda3-latest-Linux-x86_64.sh

# Run
USER $USERNAME
EXPOSE 8899
WORKDIR /home/${USERNAME}
RUN mkdir /home/${USERNAME}/dev
RUN mkdir /home/${USERNAME}/dat
VOLUME /home/${USERNAME}/dev
VOLUME /home/${USERNAME}/dat
VOLUME $CONDA_DIR
CMD ["jupyter", "notebook", "--no-browser"]
