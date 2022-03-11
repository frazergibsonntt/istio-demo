#/bin/bash

PODS=$(kubectl get pod | awk '{print $1}' | tail -n +2)

for pd in $PODS
do
    while :
    do
        sleep 1
        if [[ $(kubectl get pod $pd | awk '{print $2}' | tail -n +2) == "2/2" ]] && [[ $(kubectl get pod $pd | awk '{print $3}' | tail -n +2) == "Running" ]]
        then
            echo "break"
            break
        fi
    done
done