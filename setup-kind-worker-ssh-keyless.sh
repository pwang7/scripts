#! /bin/sh

set -xv
set -e

NODES_IP="$(kubectl get nodes -A -o wide | awk 'FNR > 2 {print $6}')"
NODES="$(kubectl get nodes -A -o wide | awk 'FNR > 2 {print $1}')"
for node in ${NODES}; do
  USER="$(whoami)"
  docker cp /etc/apt/sources.list ${node}:/etc/apt/sources.list
  docker exec ${node} apt-get update
  docker exec ${node} apt-get install -y ssh sudo
  docker exec ${node} systemctl start sshd
  docker exec ${node} useradd -m ${USER}
  docker exec ${node} usermod -aG sudo ${USER}
  echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /tmp/${USER}
  docker cp /tmp/${USER} ${node}:/etc/sudoers.d/${USER}
  docker exec ${node} chown root:root /etc/sudoers.d/${USER}

  docker exec ${node} mkdir /home/${USER}/.ssh
  docker exec ${node} ls -al /home/${USER}/
  docker cp ${HOME}/.ssh/id_rsa.pub ${node}:/home/${USER}/.ssh/authorized_keys
  docker exec ${node} chown ${USER}:${USER} /home/${USER}/ -R
done
for ip in ${NODES_IP}; do
  ssh-keyscan -H $ip >> ${HOME}/.ssh/known_hosts
done
