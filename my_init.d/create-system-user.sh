#!/bin/bash
set -em

# Add $SYSTEM_USER user (no password).
mkdir /home/$SYSTEM_USER                                                         && \
      useradd --home /home/$SYSTEM_USER --uid $SYSTEM_USER_UID --shell /bin/bash $SYSTEM_USER && \
      chown -R $SYSTEM_USER:$SYSTEM_USER /home/$SYSTEM_USER

# Add .bashrc file to the $SYSTEM_USER user.
cp -v /etc/skel/.bashrc /etc/skel/.bash_logout /etc/skel/.profile /home/$SYSTEM_USER/

# Update .bashrc file.
echo "export PATH=$PATH:\"/home/$SYSTEM_USER/.local/bin\"" >> /home/$SYSTEM_USER/.bashrc
grep "reentry scan" /home/$SYSTEM_USER/.bashrc || echo "reentry scan" >> /home/$SYSTEM_USER/.bashrc


# Create .ssh folder with an check that known_hosts file is present there
mkdir --mode=0700 /home/$SYSTEM_USER/.ssh/
touch /home/$SYSTEM_USER/.ssh/known_hosts

# Generate ssh key that works with `paramiko`
# See: https://aiida.readthedocs.io/projects/aiida-core/en/latest/get_started/computers.html#remote-computer-requirements
if [ ! -e /home/$SYSTEM_USER/.ssh/id_rsa ]; then
   ssh-keygen -f /home/$SYSTEM_USER/.ssh/id_rsa -t rsa -b 4096 -m PEM
fi

chown $SYSTEM_USER:$SYSTEM_USER /home/$SYSTEM_USER -R