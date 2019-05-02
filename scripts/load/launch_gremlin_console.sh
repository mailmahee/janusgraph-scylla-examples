kubectl create -f janusgraph-gremlin-console.yaml
sleep 5
kubectl exec -it janusgraph-gremlin-console -- bin/gremlin.sh
# Automatically delete the pod upon exit
kubectl delete -f janusgraph-gremlin-console.yaml
