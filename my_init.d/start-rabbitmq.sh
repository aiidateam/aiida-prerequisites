#!/bin/bash
set -em


# Technically, this is not necessary, one could have just put the content of /opt/start-rabbitmq.sh here.
# However, this way I was experiencing an issue with the startup of RabbitMQ. The error is different for
# different versions of RabbitMQ:
#
# For 3.7.8 it is:
#
# Warning: PID file not written; -detached was passed.
# =ERROR REPORT==== 29-Jul-2022::13:30:05.115493 ===
# No home for cookie file
#
# For 3.8.14 it would silently do nothing.
su -c /opt/start-rabbitmq.sh root
