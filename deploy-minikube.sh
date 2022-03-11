#!/bin/bash

# Boot up a minikube cluster
minikube delete -p minikube-istio && minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.20.2 -n 2 -p minikube-istio

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

# sudo minikube tunnel -p minikube-istio
# http://127.0.0.1/productpage

echo "sudo minikube tunnel -p minikube-istio"
echo "http://127.0.0.1/productpage"

kubectl apply -f istio-1.13.1/samples/addons
kubectl rollout status deployment/kiali -n istio-system
istioctl dashboard kiali
