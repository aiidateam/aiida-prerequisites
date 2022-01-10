# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# Based on Ubuntu 20.04
FROM phusion/baseimage:impish
MAINTAINER AiiDA Team

# Use the following arguments during *build* time:
# $ docker build  --build-arg NB_UID=200
ARG NB_USER="aiida"
ARG NB_UID="1000"
ARG NB_GID="1000"

# Use the following variables when running docker:
# $ docker run -e SYSTEM_USER=aiida2
ENV SYSTEM_USER ${NB_USER}
ENV SYSTEM_USER_UID ${NB_UID}
ENV SYSTEM_USER_GID ${NB_GID}
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

# Modify this section for the conda/python update.
# This list of miniconda installer versions together with their SHA256 check sums are available:
# https://docs.conda.io/en/latest/miniconda_hashes.html
ENV PYTHON_VERSION py38
ENV CONDA_VERSION 4.10.3
ENV MINICONDA_VERSION ${PYTHON_VERSION}_${CONDA_VERSION}

# Always activate /etc/profile, otherwise conda won't work.
ENV BASH_ENV /etc/profile

USER root

# Fix locales.
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Add switch mirror to fix the issue.
# https://github.com/aiidalab/aiidalab-docker-stack/issues/9
# Not sure needed continue. This mirror not contains packages for arm64 therefore commented
# RUN echo "deb http://mirror.switch.ch/ftp/mirror/ubuntu/ bionic main \ndeb-src http://mirror.switch.ch/ftp/mirror/ubuntu/ bionic main \n" >> /etc/apt/sources.list

# Install debian packages.
# Note: prefix all 'apt-get install' lines with 'apt-get update' to prevent failures in partial rebuilds
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    tzdata

# Install required ubuntu packages.
# The libpq-dev is needed for arm64 to pypi build psycopg2-binary in aiida-core
RUN apt-get update && apt-get install -y --no-install-recommends  \
    build-essential       \
    bzip2                 \
    git                   \
    gir1.2-gtk-3.0        \
    gnupg                 \
    graphviz              \
    locales               \
    less                  \
    postgresql            \
    psmisc                \
    rabbitmq-server       \
    rsync                 \
    ssh                   \
    unzip                 \
    vim                   \
    wget                  \
    zip                   \
    libpq-dev             \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean all

# Install conda.
RUN cd /tmp && \
    export ARCH=`uname -m` && \
    if [ "$ARCH" = "x86_64" ]; then \
       echo "x86_64" && \
       export MINICONDA_ARCH=x86_64 && \
       export MINICONDA_SHA256=935d72deb16e42739d69644977290395561b7a6db059b316958d97939e9bdf3d; \
    elif [ "$ARCH" = "aarch64" ]; then \
       echo "aarch64" && \
       export MINICONDA_ARCH=aarch64 && \
       export MINICONDA_SHA256=19584b4fb5c0656e0cf9de72aaa0b0a7991fbd6f1254d12e2119048c9a47e5cc; \
    else \
       echo "unknown arch"; \
    fi && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-${MINICONDA_ARCH}.sh && \
    echo "${MINICONDA_SHA256} *Miniconda3-${MINICONDA_VERSION}-Linux-${MINICONDA_ARCH}.sh" | sha256sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-${MINICONDA_ARCH}.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-${MINICONDA_ARCH}.sh && \
    echo "conda ${CONDA_VERSION}" >> $CONDA_DIR/conda-meta/pinned  && \
    conda config --system --prepend channels conda-forge  && \
    conda config --system --set auto_update_conda false  && \
    conda config --system --set show_channel_urls true  && \
    conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> $CONDA_DIR/conda-meta/pinned  && \
    conda install --quiet --yes conda  && \
    conda install --quiet --yes pip  && \
    conda update --all --quiet --yes  && \
    conda clean --all -f -y

# Upgrade ruamel.py version. Fixes https://github.com/aiidateam/aiida-core/issues/4339.
# Note: miniconda 4.10.3 installs 0.15.80 by default
RUN conda install ruamel.yaml==0.16.10

# This is needed to let non-root users create conda environments.
RUN touch /opt/conda/pkgs/urls.txt

# Copy the script load-singlesshagent.sh to /usr/local/bin.
COPY bin/load-singlesshagent.sh /usr/local/bin/load-singlesshagent.sh

# Create system user.
COPY my_init.d/create-system-user.sh /etc/my_init.d/10_create-system-user.sh

# Launch rabbitmq server
COPY my_init.d/start-rabbitmq.sh /etc/my_init.d/20_start-rabbitmq.sh

# Launch postgres server.
COPY opt/start-postgres.sh /opt/start-postgres.sh
COPY my_init.d/start-postgres.sh /etc/my_init.d/30_start-postgres.sh

# Check if init script is finished.
COPY my_init.d/finalize_init.sh /etc/my_init.d/99_finalize_init.sh

# Add wait-for-services script.
COPY bin/wait-for-services /usr/local/bin/wait-for-services

# Enable prompt color in the skeleton .bashrc before creating the default ${SYSTEM_USER}.
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

# Always activate conda.
COPY profile.d/activate_conda.sh /etc/profile.d/

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
