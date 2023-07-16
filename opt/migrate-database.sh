#!/bin/bash
set -exuo pipefail

# This script is intended to be run in a container. Its job is to migrate the PGSQL database to a newer version.

# The following variables are required:
DB_FOLDER=/home/${SYSTEM_USER}/.postgresql

OLD_PGSQL_DB_VERSION=`cat ${DB_FOLDER}/PG_VERSION`  # The version of the database before the upgrade is taken from the PG_VERSION file.
NEW_PGSQL_DB_VERSION=`conda run -n pgsql psql -V | awk '{ print int( $3 ) }'`  # The new version of PGSQL is given by the `psql -V` command installed in the pgsql conda environment.

TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_DB_FOLDER=/home/${SYSTEM_USER}/.postgresql-bak-${TIMESTAMP}
OLD_DB_CONDA_ENV_NAME="pgsql-backup-${OLD_PGSQL_DB_VERSION}-${TIMESTAMP}"
DUMP_FILE_NAME="/home/${SYSTEM_USER}/pgsql-dump-${OLD_PGSQL_DB_VERSION}-${TIMESTAMP}.sql"

# Make sure the new PostgreSQL server is shut down.
conda run -n pgsql pg_ctl -D ${DB_FOLDER} stop || true # Ignore errors, as the database might not be running.

# Part 1: dump the old database.

# Make a backup of the database.
mv ${DB_FOLDER} ${BACKUP_DB_FOLDER}

# Install the old version of PostgreSQL.
conda create -c conda-forge --yes -n ${OLD_DB_CONDA_ENV_NAME} postgresql=${OLD_PGSQL_DB_VERSION} && conda clean --all -f -y

# Below is a solution to a strange bug with PGSQL=10
# Taken from https://github.com/tethysplatform/tethys/issues/667.
# This bug is not present for PGSQL=14. So as soon as we migrate, the line below can be removed.
if [ ${OLD_PGSQL_DB_VERSION} -eq 10 ]; then
    cp /usr/share/zoneinfo /home/aiida/.conda/envs/${OLD_DB_CONDA_ENV_NAME}/share/ -R
fi

# Start the old version of PostgreSQL.
conda run -n ${OLD_DB_CONDA_ENV_NAME} pg_ctl -D ${BACKUP_DB_FOLDER} -l ${BACKUP_DB_FOLDER}/logfile start

# Dump the old database.
conda run -n ${OLD_DB_CONDA_ENV_NAME} pg_dumpall -f ${DUMP_FILE_NAME}

# Stop the old version of PostgreSQL.
conda run -n ${OLD_DB_CONDA_ENV_NAME} pg_ctl -D ${BACKUP_DB_FOLDER} stop

# Delete the environment with old version of PostgreSQL.
conda env remove -n ${OLD_DB_CONDA_ENV_NAME}

# Part 2: restore the old database to the new version.

# Create a new database.
conda run -n pgsql initdb -D ${DB_FOLDER}

# Start the new version of PostgreSQL.
conda run -n pgsql pg_ctl -w -D ${DB_FOLDER} -l ${DB_FOLDER}/logfile start

# Restore the old database.
conda run -n pgsql psql -f ${DUMP_FILE_NAME} postgres

# Stop the new version of PostgreSQL to return everything to the original state.
conda run -n pgsql pg_ctl -D ${DB_FOLDER} stop
