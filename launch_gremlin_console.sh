kubectl create -f k8s/gremlin-console/janusgraph-gremlin-console.yaml
sleep 5
kubectl exec -it janusgraph-gremlin-console -- bin/gremlin.sh
# Automatically delete the pod upon exit
kubectl delete -f k8s/gremlin-console/janusgraph-gremlin-console.yaml

graph = JanusGraphFactory().build().set('storage.backend', 'cql').set('storage.hostname', '10.138.0.2').set('storage.cql.cluster-name', 'scylla-graph').open()

kubectl run jg-console --image=gcr.io/symphony-graph17038/janusgraph:0.3.1 \
  --generator=run-pod/v1 \
  --env="JANUS_PROPS_TEMPLATE=cql-es,janusgraph.storage.hostname=10.138.0.3,janusgraph.storage.cql.keyspace=graphdemo,janusgraph.index.search.hostname=elasticsearch-0.elasticsearch.default.svc.cluster.local,elasticsearch-1.elasticsearch.default.svc.cluster.local,elasticsearch-2.elasticsearch.default.svc.cluster.local" \
  -it -- bin/gremlin.sh
