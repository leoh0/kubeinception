#!/bin/sh

BANNER=kubernetes
for i in $(seq 1 $DEPTH); do
    BANNER=$(printf "kubernetes in %s\n" "$BANNER")
done

echo
echo -e "\033[00;36m###############################################\033[00m"
echo -e "\033[00;32m$BANNER\033[00m"
echo -e "\033[00;31mSTAGE: $DEPTH\033[00m"
echo -e "\033[00;36m###############################################\033[00m"
echo
sleep 3
echo 
echo -e "\033[00;36m####### LAUNCH DOCKER DAEMON #######\033[00m"
echo 
nohup dockerd --host=unix:///var/run/docker.sock --host=tcp://127.0.0.1:2375 > dockerd.log 2>&1 &

wait=0
while true; do
    docker ps -q > /dev/null 2>&1 && break
    if [[ ${wait} -lt 10 ]]; then
        wait=$((wait+1))
        echo "waiting for docker ..."
        sleep ${wait}
    else
        echo "docker is broken ..."
        exit 1
    fi
done

echo 
echo -e "\033[00;36m####### CREATE KIND CLUSTER #######\033[00m"
echo 
kind create cluster
kind get kubeconfig > file

cat file

# waiting admission controller
wait=0;
while true; do
    kubectl --kubeconfig=/kube/file get sa default && break
    if [[ ${wait} -lt 10 ]]; then
        wait=$((wait+1))
        echo "waiting for creating sa ..."
        sleep ${wait}
    else
        echo "sa is not ready ..."
        exit 1
    fi
done

# confirm creating kube-system component
# From https://github.com/groundnuty/k8s-wait-for/blob/master/wait_for.sh
wait=0;
while true; do
    STATUS=$(kubectl --kubeconfig=/kube/file get pods -n kube-system -o go-template='
{{- define "checkStatus" -}}
  {{- $rootStatus := .status }}
  {{- $hasReadyStatus := false }}
  {{- range .status.conditions -}}
    {{- if eq .type "Ready" -}}
      {{- $hasReadyStatus = true }}
      {{- if eq .status "False" -}}
        {{- if .reason -}}
          {{- if ne .reason "PodCompleted" -}}
            {{ .status }}
            {{- range $rootStatus.containerStatuses -}}
              {{- if .state.terminated.reason -}}
              :{{ .state.terminated.reason }}
              {{- end -}}
            {{- end -}}
          {{- end -}}
        {{- else -}}
          {{ .status }}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- else -}}
    {{- printf "No resources found.\n" -}}
  {{- end -}}
  {{- if ne $hasReadyStatus true -}}
    {{- printf "False" -}}
  {{- end -}}
{{- end -}}
{{- if .items -}}
    {{- range .items -}}
      {{ template "checkStatus" . }}
    {{- end -}}
{{- else -}}
    {{ template "checkStatus" . }}
{{- end -}}')
    if [[ "$STATUS" == "" ]] ; then
        break
    fi
    if [[ ${wait} -lt 10 ]]; then
        wait=$((wait+1))
        echo "waiting for kube-system component ..."
        sleep ${wait}
    else
        echo "one of kube-system component is broken ..."
        exit 1
    fi
done

echo 
echo -e "\033[00;36m####### REBIRTH KIND POD #######\033[00m"
echo 
NEWDEPTH=$((DEPTH+1))
sed -i "s/value:.*$/value: \"$NEWDEPTH\"/g" /kube/create-kind.yaml
kubectl --kubeconfig=/kube/file apply -f /kube/create-kind.yaml || :

# sometime kind api is not ready for getting pods log
# it return empty logs with 200
# so before finding a cause just sleep some seconds
echo "sleep 10 secs for waiting pod ..."
sleep 10

# confirm creating kind pod
wait=0;
while true; do
    STATUS=$(kubectl --kubeconfig=/kube/file get pods -o go-template='
{{- define "checkStatus" -}}
  {{- $rootStatus := .status }}
  {{- $hasReadyStatus := false }}
  {{- range .status.conditions -}}
    {{- if eq .type "Ready" -}}
      {{- $hasReadyStatus = true }}
      {{- if eq .status "False" -}}
        {{- if .reason -}}
          {{- if ne .reason "PodCompleted" -}}
            {{ .status }}
            {{- range $rootStatus.containerStatuses -}}
              {{- if .state.terminated.reason -}}
              :{{ .state.terminated.reason }}
              {{- end -}}
            {{- end -}}
          {{- end -}}
        {{- else -}}
          {{ .status }}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- else -}}
    {{- printf "No resources found.\n" -}}
  {{- end -}}
  {{- if ne $hasReadyStatus true -}}
    {{- printf "False" -}}
  {{- end -}}
{{- end -}}
{{- if .items -}}
    {{- range .items -}}
      {{ template "checkStatus" . }}
    {{- end -}}
{{- else -}}
    {{ template "checkStatus" . }}
{{- end -}}')
    if [[ "$STATUS" == "" ]] ; then
        break
    fi
    if [[ ${wait} -lt 10 ]]; then
        wait=$((wait+1))
        echo "waiting for kind ..."
        sleep ${wait}
    else
        echo "newer kind is broken ..."
        exit 1
    fi
done

wait=0;
while true; do
    kubectl --kubeconfig=/kube/file logs kubeinception > /dev/null && break
    if [[ ${wait} -lt 10 ]]; then
        wait=$((wait+1))
        echo "waiting for creating pod ..."
        sleep ${wait}
    else
        echo "pod is not ready ..."
        exit 1
    fi
done

kubectl --kubeconfig=/kube/file logs kubeinception -f
