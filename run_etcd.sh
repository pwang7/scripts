#! /bin/sh

set -xv # enable debug

# clean up
sudo umount -f /tmp/csi-mount/target
sudo rm -rf /tmp/csi-mount /tmp/csi-staging
sudo umount -f /tmp/target_volume_path
sudo umount -f /tmp/target_volume_path_1
sudo umount -f /tmp/target_volume_path_2
ETCD_PID=`pgrep -x etcd`
sudo kill -9 $ETCD_PID
CSI_PIDS=`pgrep -x csi`
for PID in $CSI_PIDS; do
  sudo kill -9 $PID
done

# quit if any following command fails
set -e

export BIND_MOUNTER=target/debug/bind_mounter
sudo chown root:root $BIND_MOUNTER
sudo chmod u+s $BIND_MOUNTER
ls -lsh $BIND_MOUNTER

ETCD_DATA_DIR=/tmp/etcd-data
sudo rm -rf $ETCD_DATA_DIR
HOST_NAME=`hostname`
ETCD_CLUSTER_NAME=etcd_cluster
ETCD_CLIENT_PORT=2379
ETCD_PEER_PORT=2380
ETCD_HEALTH_PORT=2381
./etcd \
  --data-dir=$ETCD_DATA_DIR \
  --name $ETCD_CLUSTER_NAME \
  --logger=zap \
  --initial-advertise-peer-urls http://$HOST_NAME:$ETCD_PEER_PORT \
  --listen-peer-urls http://0.0.0.0:$ETCD_PEER_PORT \
  --advertise-client-urls http://$HOST_NAME:$ETCD_CLIENT_PORT \
  --listen-client-urls http://0.0.0.0:$ETCD_CLIENT_PORT \
  --initial-cluster $ETCD_CLUSTER_NAME=http://$HOST_NAME:$ETCD_PEER_PORT \
  --listen-metrics-urls http://0.0.0.0:$ETCD_HEALTH_PORT
