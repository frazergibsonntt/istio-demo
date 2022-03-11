#!/bin/bash
# https://istio.io/latest/docs/setup/getting-started/#ip

# Boot up a kind cluster
if [[ $(kind get clusters) == *"istio-demo"* ]]
then
  kind delete clusters istio-demo && istio-1.13.1/samples/kind-lb/setupkind.sh --cluster-name istio-demo 
else
  istio-1.13.1/samples/kind-lb/setupkind.sh --cluster-name istio-demo 
fi

# Switch to the cluster
kubectl config use-context kind-istio-demo

# Install Istio on the cluster
istioctl install --set profile=demo -y

# Add a label to tell Istio to add sidecars in the default namespace
kubectl label namespace default istio-injection=enabled

# Apply the Bookinfo demo 
kubectl apply -f istio-1.13.1/samples/bookinfo/platform/kube/bookinfo.yaml

# Check all the pods are running
PODS=$(kubectl get pod | awk '{print $1}' | tail -n +2)

for pd in $PODS
do
    while :
    do
        sleep 1
        if [[ $(kubectl get pod $pd | awk '{print $2}' | tail -n +2) == "2/2" ]] && [[ $(kubectl get pod $pd | awk '{print $3}' | tail -n +2) == "Running" ]]
        then
            break
        fi
    done
done

# Check app is serving the html page in the cluster
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"

# Deploy Gateway and Virtual Service
kubectl apply -f istio-1.13.1/samples/bookinfo/networking/bookinfo-gateway.yaml


# Get URL
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT


echo "http://$GATEWAY_URL/productpage"
