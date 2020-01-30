# AiiDA Prerequisites

This repository adds
[PostgreSQL](https://www.postgresql.org/) and [RabbitMQ](https://www.rabbitmq.com/) servers on top of [phusion base image](https://github.com/phusion/baseimage-docker). Additionally, it creates a system profile ready to setup AiiDA under it.


# Docker image

The docker image:
 * Is based on [phusion base image](https://github.com/phusion/baseimage-docker).
 * Installs and launches [PostgreSQL](https://www.postgresql.org/) for $SYSTEM_USER.
 * Installs and launches [RabbitMQ](https://www.rabbitmq.com/).
 * Configures Linux environment for $SYSTEM_USER.

## Wait for services
The image provides a mechanism to wait until the startup script has *launched* all services.
Example of usage:

```
$ docker exec --tty $DOCKERID wait-for-services
```
This command will exit when all startup scripts are done.
Note, however, that the mechanism does not check that all services are actually running.

## Docker ARGs and ENVs
The the following arguments can be used during *build* time:
```
$ docker build  --build-arg NB_UID=200
```
ARG NB_USER="aiida"
ARG NB_UID="1000"
ARG NB_GID="1000"

The following variables can be used when running docker:
```
docker run -e SYSTEM_USER=aiida2
```
ENV SYSTEM_USER ${NB_USER}
ENV SYSTEM_USER_UID ${NB_UID}
ENV SYSTEM_USER_GID ${NB_GID}
ENV PYTHONPATH /home/$SYSTEM_USER

# Docker Hub repository

The docker image is built automatically on Docker Hub once new changes are pushed to the `master` or `develop` branches of this repository.
The `master` branch is available under the docker tag `stable`, while the `develop` branch is available under the docker tag `latest`.
In addition, any git tag pushed to the repository (say v1.0.1) will trigger a build on Docker Hub with the same docker tag without 'v' prefix (1.0.1).

All the images are available following this link: https://hub.docker.com/r/aiidateam/aiida-prerequisites


# Acknowledgements

This work is supported by the [MARVEL National Centre for Competency in Research](<http://nccr-marvel.ch>)
funded by the [Swiss National Science Foundation](<http://www.snf.ch/en>), as well as by the [MaX
European Centre of Excellence](<http://www.max-centre.eu/>) funded by the Horizon 2020 EINFRA-5 program,
Grant No. 676598.

![MARVEL](miscellaneous/logos/MARVEL.png)
![MaX](miscellaneous/logos/MaX.png)
