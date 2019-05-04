kubectl create -f k8s/gremlin-console/janusgraph-gremlin-console.yaml
sleep 5
kubectl exec -it janusgraph-gremlin-console -- bin/gremlin.sh
# Automatically delete the pod upon exit
kubectl delete -f k8s/gremlin-console/janusgraph-gremlin-console.yaml

# graph = JanusGraphFactory().build().set('storage.backend', 'cql').set('storage.hostname', '10.138.0.2').set('storage.cql.cluster-name', 'scylla-graph').open()
