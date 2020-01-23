#!/bin/bash
set -em

# Add $SYSTEM_USER user (no password)
mkdir /home/$SYSTEM_USER                                                         && \
      useradd --home /home/$SYSTEM_USER --uid $SYSTEM_USER_UID --shell /bin/bash $SYSTEM_USER && \
      chown -R $SYSTEM_USER:$SYSTEM_USER /home/$SYSTEM_USER

# Add .bashrc file to the $SYSTEM_USER user
cp -v /etc/skel/.bashrc /etc/skel/.bash_logout /etc/skel/.profile /home/$SYSTEM_USER/

echo "export PYTHONPATH=\"/home/$SYSTEM_USER\"" >> /home/$SYSTEM_USER/.bashrc
echo "export PATH=$PATH:\"/home/$SYSTEM_USER/.local/bin\"" >> /home/$SYSTEM_USER/.bashrc

mkdir --mode=0700 /home/$SYSTEM_USER/.ssh/ &&  touch /home/$SYSTEM_USER/.ssh/known_hosts

chown $SYSTEM_USER:$SYSTEM_USER /home/$SYSTEM_USER -R