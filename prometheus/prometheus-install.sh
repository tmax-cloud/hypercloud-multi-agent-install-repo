## install jq
curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /usr/local/bin/jq
chmod a+x /usr/local/bin/jq

## export env
export PROMETHEUS_VERSION=v2.11.0
export PROMETHEUS_OPERATOR_VERSION=v0.34.0
export NODE_EXPORTER_VERSION=v0.18.1
##export GRAFANA_VERSION=6.4.3
export KUBE_STATE_METRICS_VERSION=v1.8.0
export CONFIGMAP_RELOADER_VERSION=v0.34.0
export CONFIGMAP_RELOAD_VERSION=v0.0.1
export KUBE_RBAC_PROXY_VERSION=v0.4.1
export PROMETHEUS_ADAPTER_VERSION=v0.5.0
export ALERTMANAGER_VERSION=v0.20.0

## set version
##sed -i 's/{ALERTMANAGER_VERSION}/'${ALERTMANAGER_VERSION}'/g' yaml/manifests/alertmanager-alertmanager.yaml
##sed -i 's/{GRAFANA_VERSION}/'${GRAFANA_VERSION}'/g' yaml/manifests/grafana-deployment.yaml
sed -i 's/{KUBE_RBAC_PROXY_VERSION}/'${KUBE_RBAC_PROXY_VERSION}'/g' yaml/manifests/kube-state-metrics-deployment.yaml
sed -i 's/{KUBE_STATE_METRICS_VERSION}/'${KUBE_STATE_METRICS_VERSION}'/g' yaml/manifests/kube-state-metrics-deployment.yaml
sed -i 's/{NODE_EXPORTER_VERSION}/'${NODE_EXPORTER_VERSION}'/g' yaml/manifests/node-exporter-daemonset.yaml
sed -i 's/{KUBE_RBAC_PROXY_VERSION}/'${KUBE_RBAC_PROXY_VERSION}'/g' yaml/manifests/node-exporter-daemonset.yaml
sed -i 's/{PROMETHEUS_ADAPTER_VERSION}/'${PROMETHEUS_ADAPTER_VERSION}'/g' yaml/manifests/prometheus-adapter-deployment.yaml
sed -i 's/{PROMETHEUS_VERSION}/'${PROMETHEUS_VERSION}'/g' yaml/manifests/prometheus-prometheus.yaml
sed -i 's/{PROMETHEUS_OPERATOR_VERSION}/'${PROMETHEUS_OPERATOR_VERSION}'/g' yaml/setup/prometheus-operator-deployment.yaml
sed -i 's/{CONFIGMAP_RELOADER_VERSION}/'${CONFIGMAP_RELOADER_VERSION}'/g' yaml/setup/prometheus-operator-deployment.yaml
sed -i 's/{CONFIGMAP_RELOAD_VERSION}/'${CONFIGMAP_RELOAD_VERSION}'/g' yaml/setup/prometheus-operator-deployment.yaml

## step1: apply setup
kubectl create -f yaml/setup/
sleep 30s

## step2: apply manifests
kubectl create -f yaml/manifests/
##kubectl get svc -n monitoring prometheus-k8s -o yaml | sed "s|type: NodePort|type: LoadBalancer|g" | kubectl replace -f -
##kubectl get svc -n monitoring grafana -o yaml | sed "s|type: ClusterIP|type: LoadBalancer|g" | kubectl replace -f -

kubectl get prometheus k8s -n monitoring -o json | jq 'del(.spec.storage)' > prometheus-k8s.json
kubectl delete prometheus k8s -n monitoring
kubectl apply -f prometheus-k8s.json

rm prometheus-k8s.json -f

## step3: apply discovery
kubectl create -f yaml/kube-controller-manager-prometheus-discovery.yaml
kubectl create -f yaml/kube-scheduler-prometheus-discovery.yaml

kubectl get servicemonitor -n monitoring kube-controller-manager -o json | jq 'del(.spec.endpoints[].metricRelabelings)' > kube-controller-manager.json
kubectl get servicemonitor -n monitoring kube-scheduler -o json | jq 'del(.spec.endpoints[].metricRelabelings)' > kube-scheduler.json

kubectl apply -f kube-controller-manager.json
kubectl apply -f kube-scheduler.json

rm kube-controller-manager.json  -f

## step4: add labels
pods=($(kubectl get pod -n kube-system  | grep kube-scheduler | awk '{print$1}'))

for i in "${pods[@]}"
do
   kubectl label pod $i  -n kube-system  k8s-app=kube-scheduler --overwrite
done

pods=($(kubectl get pod -n kube-system  | grep kube-controller-manager | awk '{print$1}'))

for i in "${pods[@]}"
do
   kubectl label pod $i  -n kube-system  k8s-app=kube-controller-manager --overwrite
done     
