# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# Based on Ubuntu 18.04 since v0.11
FROM phusion/baseimage:0.11
MAINTAINER AiiDA Team

# Initial parameters
ARG NB_USER="aiida"
ENV SYSTEM_USER=${NB_USER}
ARG NB_UID="1000"
ENV SYSTEM_USER_UID=${NB_UID}
ARG NB_GID="1000"

USER root

# Fix locales
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Add switch mirror to fix the issue
# https://github.com/aiidalab/aiidalab-docker-stack/issues/9
RUN echo "deb http://mirror.switch.ch/ftp/mirror/ubuntu/ bionic main \ndeb-src http://mirror.switch.ch/ftp/mirror/ubuntu/ bionic main \n" >> /etc/apt/sources.list

# install debian packages
# Note: prefix all 'apt-get install' lines with 'apt-get update' to prevent failures in partial rebuilds
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    tzdata

# Install required ubuntu packages
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
    python3-dev           \
    python3-gi            \
    python3-gi-cairo      \
    python3-pip           \
    python3-psycopg2      \
    python3-setuptools    \
    python3-tk            \
    python3-wheel         \
    python-tk             \
    rabbitmq-server       \
    rsync                 \
    ssh                   \
    unzip                 \
    vim                   \
    wget                  \
    zip                   \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean all

# Add PostgreSQL bin folder to PATH variable
ENV PATH $PATH:/usr/lib/postgresql/10/bin

# Set Python3 be the default python version
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# update build-tools
RUN pip3 install -U pip setuptools wheel

# Launch rabbitmq server
COPY my_init.d/start-rabbitmq.sh /etc/my_init.d/10_start-rabbitmq.sh

# Create system user
COPY my_init.d/create-system-user.sh /etc/my_init.d/20_create-system-user.sh

# Launch postgres server
COPY opt/start-postgres.sh /opt/start-postgres.sh
COPY my_init.d/start-postgres.sh /etc/my_init.d/30_start-postgres.sh

# Health check
HEALTHCHECK --interval=10s CMD su $SYSTEM_USER -c "pg_ctl -D /home/$SYSTEM_USER/.postgresql status" || exit 1

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
