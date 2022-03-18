#!/bin/bash

# Boot up a minikube cluster
minikube delete -p minikube-istio && minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.20.2 -n 2 -p minikube-istio

# Install Istio on the cluster
istioctl install --set profile=demo -y

# Add a label to tell Istio to add sidecars in the default namespace
kubectl label namespace default istio-injection=enabled

# Apply the Bookinfo demo 
kubectl apply -f demo-resources/bookinfo.yaml

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

# sudo minikube tunnel -p minikube-istio

# Deploy Gateway and Virtual Service
kubectl apply -f demo-resources/bookinfo-gateway.yaml

# Deploy kiali
kubectl apply -f demo-resources/addons
kubectl rollout status deployment/kiali -n istio-system

cd demo-resources/keys

# root CA and private key
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=mydomain Inc./CN=mydomain.com' -keyout mydomain.com.key -out mydomain.com.crt

# certificate and private key
openssl req -out example.mydomain.com.csr -newkey rsa:2048 -nodes -keyout example.mydomain.com.key -subj "/CN=example.mydomain.com/O=example organization"
openssl x509 -req -sha256 -days 365 -CA mydomain.com.crt -CAkey mydomain.com.key -set_serial 0 -in example.mydomain.com.csr -out example.mydomain.com.crt

# ingress secret with keys
kubectl create -n istio-system secret tls example-credential --key=example.mydomain.com.key --cert=example.mydomain.com.crt

cd ../..

# /etc/hosts:
# 127.0.0.1        httpbin.example.com
# 127.0.0.1        example.mydomain.com


# istioctl dashboard kiali
echo "run:
istioctl dashboard kiali
"
# sudo minikube tunnel -p minikube-istio
echo "run:
sudo minikube tunnel -p minikube-istio
"

# add mydomain.com.crt to firefox and open in browser
# https://example.mydomain.com:443/productpage

# curl -vvvv https://example.mydomain.com:443/productpage --cacert demo-resources/keys/mydomain.com.crt
