## Istio demo

Prereqs:
istioctl
docker
minikube


to run:
```
./deploy-minikube.sh 
```

forward to localhost:
```
sudo minikube tunnel -p minikube-istio
```

Use firefox and add CA cert through browser