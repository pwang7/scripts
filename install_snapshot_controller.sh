#! /bin/bash

shopt -s expand_aliases
# Load kubectl alias
ALIASES_FILE=~/.bash_aliases
if [ -f $ALIASES_FILE ]; then
    . $ALIASES_FILE
fi

# Install snapshot CRD
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml

# Install snapshot controller
wget --quiet https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
wget --quiet https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
sed -e 's/namespace\:\ default/namespace\:\ kube\-system/g' rbac-snapshot-controller.yaml > datenlord-rbac-snapshot-controller.yaml
sed -e 's/namespace\:\ default/namespace\:\ kube\-system/g' setup-snapshot-controller.yaml > datenlord-setup-snapshot-controller.yaml
kubectl apply -f datenlord-rbac-snapshot-controller.yaml
kubectl apply -f datenlord-setup-snapshot-controller.yaml
rm setup-snapshot-controller.yaml rbac-snapshot-controller.yaml datenlord-rbac-snapshot-controller.yaml datenlord-setup-snapshot-controller.yaml

