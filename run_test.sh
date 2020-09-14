#! /bin/sh

set -xv # enable debug

# clean up
sudo umount -f /tmp/csi-mount/target
sudo rm -rf /tmp/csi-mount /tmp/csi-staging
ETCD_PID=`pgrep -x etcd`
sudo kill -9 $ETCD_PID
CSI_PIDS=`pgrep -x csi`
for PID in $CSI_PIDS; do
  sudo kill -9 $PID
done

# run etcd
ETCD_DATA_DIR=/tmp/etcd-data
sudo rm -rf $ETCD_DATA_DIR
HOST_NAME=`hostname`
ETCD_CLUSTER_NAME=etcd_cluster
ETCD_CLIENT_PORT=52379
ETCD_PEER_PORT=52380
ETCD_HEALTH_PORT=52381
./etcd \
  --data-dir=$ETCD_DATA_DIR \
  --name $ETCD_CLUSTER_NAME \
  --logger=zap \
  --initial-advertise-peer-urls http://$HOST_NAME:$ETCD_PEER_PORT \
  --listen-peer-urls http://0.0.0.0:$ETCD_PEER_PORT \
  --advertise-client-urls http://$HOST_NAME:$ETCD_CLIENT_PORT \
  --listen-client-urls http://0.0.0.0:$ETCD_CLIENT_PORT \
  --initial-cluster $ETCD_CLUSTER_NAME=http://$HOST_NAME:$ETCD_PEER_PORT \
  --listen-metrics-urls http://0.0.0.0:$ETCD_HEALTH_PORT &

# wait until etcd become healthy
while [ true ]; do
  curl 127.0.0.1:$ETCD_HEALTH_PORT/health
  if [ $? -eq 0 ]
  then
     echo "etcd health check passed"
     break
  fi
  sleep 3
  echo "check etcd health again"
done

# exit if any following command fails
set -e

cargo build

# enable bind_mounter suid permission
export BIND_MOUNTER=target/debug/bind_mounter
sudo chown root:root $BIND_MOUNTER
sudo chmod u+s $BIND_MOUNTER
ls -lsh $BIND_MOUNTER

# unit test
export ETCD_END_POINT="http://127.0.0.1:$ETCD_CLIENT_PORT"
export WORKER_PORT=60061
RUST_LOG=csi=debug RUST_BACKTRACE=full cargo test

# clear etcd data
export ETCDCTL_API=3
./etcdctl --endpoints=$ETCD_END_POINT del "" --prefix

# run controller and node seperately

export CSI_CONTROLLER_SOCKET=/tmp/controller.sock
target/debug/csi \
  -s unix://$CSI_CONTROLLER_SOCKET \
  -p $WORKER_PORT \
  -n $HOST_NAME \
  -r controller \
  -e http://127.0.0.1:$ETCD_CLIENT_PORT &

export CSI_NODE_SOCKET=/tmp/node.sock
target/debug/csi \
  -s unix://$CSI_NODE_SOCKET \
  -p $WORKER_PORT \
  -n $HOST_NAME \
  -r node \
  -e http://127.0.0.1:$ETCD_CLIENT_PORT &

./csi-sanity -csi.endpoint=$CSI_NODE_SOCKET -csi.controllerendpoint=$CSI_CONTROLLER_SOCKET

# kill csi processes
CSI_PIDS=`pgrep -x csi`
for PID in $CSI_PIDS; do
  sudo kill -9 $PID
done

# clear etcd data
./etcdctl --endpoints=$ETCD_END_POINT del "" --prefix

# run controller and node together

#export RUST_BACKTRACE=full
#export RUST_LOG=csi=debug
#export CSI_BOTH_SOCKET=/tmp/both.sock
#target/debug/csi \
#  -s unix://$CSI_BOTH_SOCKET \
#  -p $WORKER_PORT \
#  -n $HOST_NAME \
#  -r both \
#  -e http://127.0.0.1:$ETCD_CLIENT_PORT &
#
#./csi-sanity -csi.endpoint=$CSI_BOTH_SOCKET

# clean up
ETCD_PID=`pgrep etcd`
sudo kill -9 $ETCD_PID
CSI_PIDS=`pgrep -x csi`
for PID in $CSI_PIDS; do
  sudo kill -9 $PID
done
