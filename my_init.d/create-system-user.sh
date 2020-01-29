#!/bin/bash
set -em

PERFORM_CHOWN=false

# Create user's home folder, it should not exist at the beginning.
mkdir -p /home/${SYSTEM_USER}

# Add $SYSTEM_USER user (no password) if does not exist
if ! id -u ${SYSTEM_USER} ; then
  useradd --home /home/${SYSTEM_USER} --uid ${SYSTEM_USER_UID} --shell /bin/bash ${SYSTEM_USER}
  chown ${SYSTEM_USER}:${SYSTEM_USER} /home/${SYSTEM_USER}
fi

# Add .bashrc file to the $SYSTEM_USER's home folder.
if [[ ! -f /home/${SYSTEM_USER}/.bashrc ]]; then
  cp -v /etc/skel/.bashrc  /home/${SYSTEM_USER}/
  echo "export PATH=$PATH:\"/home/${SYSTEM_USER}/.local/bin\"" >> /home/${SYSTEM_USER}/.bashrc
  PERFORM_CHOWN=true
fi

if [[ ! -f /home/${SYSTEM_USER}/.bash_logout ]]; then 
  cp -v /etc/skel/.bash_logout /home/${SYSTEM_USER}/
  PERFORM_CHOWN=true
fi

if [[ ! -f /home/${SYSTEM_USER}/.profile ]]; then
  cp -v /etc/skel/.profile /home/${SYSTEM_USER}/
  PERFORM_CHOWN=true
fi

if [[ ! -d /home/${SYSTEM_USER}/.ssh/ ]]; then
  # Create .ssh folder with an check that known_hosts file is present there
  mkdir --mode=0700 /home/${SYSTEM_USER}/.ssh/
  touch /home/${SYSTEM_USER}/.ssh/known_hosts

  # Generate ssh key that works with `paramiko`
  # See: https://aiida.readthedocs.io/projects/aiida-core/en/latest/get_started/computers.html#remote-computer-requirements
  ssh-keygen -f /home/${SYSTEM_USER}/.ssh/id_rsa -t rsa -b 4096 -m PEM -N ''

  PERFORM_CHOWN=true
fi

if [[ ${PERFORM_CHOWN} == true ]]; then
  chown ${SYSTEM_USER}:${SYSTEM_USER} /home/${SYSTEM_USER} -R
fi
