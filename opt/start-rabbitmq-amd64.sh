#!/bin/bash
set -em

# Activate the conda environment with RabbitMQ installed in it.
conda activate rmq

DIR_RABBITMQ="/home/${SYSTEM_USER}/.rabbitmq"

mkdir -p "${DIR_RABBITMQ}"
#chown rabbitmq:rabbitmq "${DIR_RABBITMQ}"

# Set base directory for RabbitMQ to persist its data. This needs to be set to a folder in the system user's home
# directory as that is the only folder that is persisted outside of the container.
echo MNESIA_BASE="${DIR_RABBITMQ}" >> /opt/conda/envs/rmq/etc/rabbitmq/rabbitmq-env.conf
echo LOG_BASE="${DIR_RABBITMQ}/log" >> /opt/conda/envs/rmq/etc/rabbitmq/rabbitmq-env.conf

# Explicitly define the node name. This is necessary because the mnesia subdirectory contains the hostname, which by
# default is set to the value of $(hostname -s), which for docker containers, will be a random hexadecimal string. Upon
# restart, this will be different and so the original mnesia folder with the persisted data will not be found. The
# reason RabbitMQ is built this way is through this way it allows to run multiple nodes on a single machine each with
# isolated mnesia directories. Since in the AiiDA setup we only need and run a single node, we can simply use localhost.
echo NODENAME=rabbit@localhost >> /opt/conda/envs/rmq/etc/rabbitmq/rabbitmq-env.conf

rabbitmq-server -detached
