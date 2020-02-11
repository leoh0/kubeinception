#!/bin/sh

echo 
echo "####### LAUNCH DOCKER DAEMON #######"
echo 
nohup dockerd --host=unix:///var/run/docker.sock --host=tcp://127.0.0.1:2375 &

wait=0
while true; do
    docker ps -q > /dev/null 2>&1 && break
    if [[ ${wait} -lt 30 ]]; then
        wait=$((wait+1))
        echo "waiting for docker ..."
        sleep 1
    else
        echo "docker is broken ..."
        exit 1
    fi
done

for i in $(seq 1 10); do 
  echo "waiting $i";
  sleep 1;
done;

echo 
echo "####### CREATE KIND CLUSTER #######"
echo 
kind create cluster
kind get kubeconfig > file

cat file

wait=0;
while true; do
    kubectl --kubeconfig=/kube/file get sa default && break
    if [[ ${wait} -lt 30 ]]; then
        wait=$((wait+1))
        echo "waiting for creating sa ..."
        sleep 1
    else
        echo "sa is not ready ..."
        exit 1
    fi
done

echo "sleep 10 secs for waiting core component ..."
sleep 10

echo 
echo "####### REBIRTH KIND POD #######"
echo 
kubectl --kubeconfig=/kube/file apply -f /kube/create-kind.yaml || :

wait=0;
while true; do
    kubectl --kubeconfig=/kube/file logs kubeinception && break
    if [[ ${wait} -lt 60 ]]; then
        wait=$((wait+1))
        echo "waiting for creating pod ..."
        sleep 1
    else
        echo "pod is not ready ..."
        exit 1
    fi
done

kubectl --kubeconfig=/kube/file logs kubeinception -f
