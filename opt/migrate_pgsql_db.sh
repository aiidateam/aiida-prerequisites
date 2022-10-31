#!/bin/bash

OLD_PGSQL_DB_VERSION=10
NEW_PGSQL_DB_VERSION=12

# Make sure the new PostgreSQL database is shut down.
conda run -n pgsql pg_ctl -D /home/${SYSTEM_USER}/.postgresql stop


# Part 1: dump the old database.

# Make a backup of the database.
mv ~/.postgresql ~/.postgresql_bak

# Install the old version of PostgreSQL.
conda create -c conda-forge --yes -n pgsql-backup-${OLD_PGSQL_DB_VERSION} postgresql=${OLD_PGSQL_DB_VERSION} && conda clean --all -f -y

# Below is a solution to a strange bug with PGSQL=10
# Taken from https://github.com/tethysplatform/tethys/issues/667.
# This bug is not present for PGSQL=14. So as soon as we migrate, the line below can be removed.
if [ ${OLD_PGSQL_DB_VERSION} -eq 10 ]; then
    cp /usr/share/zoneinfo /home/aiida/.conda/envs/pgsql-backup-${OLD_PGSQL_DB_VERSION}/share/ -R
fi

# Start the old version of PostgreSQL.
conda run -n pgsql-backup-${OLD_PGSQL_DB_VERSION} pg_ctl -D /home/${SYSTEM_USER}/.postgresql_bak -l /home/${SYSTEM_USER}/.postgresql_bak/logfile start

# Dump the old database.
conda run -n pgsql-backup-${OLD_PGSQL_DB_VERSION} pg_dump -h localhost -p 5432 -d default_aiida_477d3dfc78a2042156110cb00ae3618f -U aiida_qs_aiida_477d3dfc78a2042156110cb00ae3618f > /home/${SYSTEM_USER}/pg_dumpall.sql

# Stop the old version of PostgreSQL.
conda run -n pgsql-backup-${OLD_PGSQL_DB_VERSION} pg_ctl -D /home/${SYSTEM_USER}/.postgresql_bak stop


# Part 2: restore the old database to the new version.

# Create a new database.
conda run -n pgsql initdb -D /home/${SYSTEM_USER}/.postgresql

# Start the new version of PostgreSQL.
conda run -n pgsql pg_ctl -w -D /home/${SYSTEM_USER}/.postgresql -l /home/${SYSTEM_USER}/.postgresql/logfile start

# Create new user.
conda run -n pgsql createuser -s aiida_qs_aiida_477d3dfc78a2042156110cb00ae3618f

# Creste new aiidadb database.
conda run -n pgsql psql -h localhost -d template1 -c "CREATE DATABASE default_aiida_477d3dfc78a2042156110cb00ae3618f OWNER aiida_qs_aiida_477d3dfc78a2042156110cb00ae3618f;"

# Grant privileges.
conda run -n pgsql psql -h localhost -d template1 -c "GRANT ALL PRIVILEGES ON DATABASE default_aiida_477d3dfc78a2042156110cb00ae3618f to aiida_qs_aiida_477d3dfc78a2042156110cb00ae3618f;"

# Restore the old database.
conda run -n pgsql psql -h localhost -d default_aiida_477d3dfc78a2042156110cb00ae3618f -f pg_dumpall.sql