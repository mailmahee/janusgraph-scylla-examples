#!/usr/bin/env bash

kubectl create -f k8s/gremlin-console/janusgraph-gremlin-console.yaml
sleep 10
kubectl exec -it janusgraph-gremlin-console -- bin/gremlin.sh

# When you need to delete the pod upon exit, run:
# kubectl delete -f k8s/gremlin-console/janusgraph-gremlin-console.yaml
