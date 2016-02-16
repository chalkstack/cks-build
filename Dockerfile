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

RUN apt-get update && apt-get install curl -y

# Install miniconda
RUN curl -LO http://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh
RUN bash Miniconda-latest-Linux-x86_64.sh -p /miniconda -b
RUN rm Miniconda-latest-Linux-x86_64.sh
ENV PATH=/miniconda/bin:${PATH}
RUN conda update -y conda

# Install base tools and some jupyter dependencies
RUN apt-get update && apt-get install -y -q \
    build-essential \
    make \
    gcc \
    zlib1g-dev \
    git \
    python \
    python-dev \
    python-pip \
    python3-dev \
    python3-pip \
    python-sphinx \
    python3-sphinx \
    libzmq3-dev \
    sqlite3 \
    libsqlite3-dev \
    pandoc \
    libcurl4-openssl-dev \
    nodejs \
    nodejs-legacy \
    npm \
    vim \
    sudo

# Add a default user
RUN useradd -c 'Chalkstack User' -m -d /home/cks -s "/bin/bash" cks \
    && echo "cks:cks" | chpasswd \
    && adduser cks sudo
RUN chown -R cks:cks /miniconda
USER cks
WORKDIR /home/cks

# Install Jupyter
RUN conda install -y jupyter ipyparallel
RUN mkdir /home/cks/.jupyter
COPY jupyter_notebook_config.py /home/cks/.jupyter/jupyter_notebook_config.py
COPY NotebookApp.password /etc/cks/NotebookApp.password
USER root
RUN echo "c.NotebookApp.password = u'$(cat /etc/cks/NotebookApp.password)'" >> /home/cks/.jupyter/jupyter_notebook_config.py
USER cks

# Create default miniconda environments
RUN conda create -y -n py27 --use-index-cache python=2.7
RUN conda install -y --name=py27 --use-index-cache \
    ipython ipykernel jupyter_client
RUN conda create -y -n py34 --use-index-cache python=3.4
RUN conda install -y --name=py34 --use-index-cache \
    ipython ipykernel jupyter_client
#RUN conda create -y -n R_base -c r r-essentials

# Install Kernels
COPY kernels /tmp/kernels
RUN jupyter kernelspec install --prefix=/miniconda /tmp/kernels/py27
RUN jupyter kernelspec install --prefix=/miniconda /tmp/kernels/py34
#RUN jupyter kernelspec install --prefix=/miniconda /tmp/kernels/R_base

# Secure the notebook server
USER root
COPY cks.password /etc/cks/cks.password
COPY mycert.pem /etc/cks/mycert.pem
COPY mykey.key /etc/cks/mykey.key
RUN echo "cks:$(cat /etc/cks/cks.password)" | chpasswd

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
USER cks

CMD jupyter notebook
