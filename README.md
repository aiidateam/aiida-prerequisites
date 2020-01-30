# AiiDA Prerequisites

This repository adds
[PostgreSQL](https://www.postgresql.org/) and [RabbitMQ](https://www.rabbitmq.com/) servers on top of [phusion](https://github.com/phusion/baseimage-docker) base image. Additionally, it creates a system profile ready to setup AiiDA under it.


# Docker image

The docker image contains:
 * [PostgreSQL](https://www.postgresql.org/)
 * [RabbitMQ](https://www.rabbitmq.com/)
 * Configured Linux environment for $SYSTEM_USER.

## Wait for services
This image provides a mechanism to wait untill all the services were launched by the statup scripts. However, it does not
check that services did start. Example of usage:

```
$ docker exec --tty $DOCKERID wait-for-services
```
This command will exit when all startup scripts are done.

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
