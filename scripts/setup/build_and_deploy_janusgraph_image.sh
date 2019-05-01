#!/usr/bin/env bash
# Build and deploy a JanusGraph Docker image to your project Google Container Registry

# sudo yum install -y docker
# sudo systemctl start docker

PROJECT="symphony-graph17038"

git clone https://github.com/JanusGraph/janusgraph-docker.git
cd janusgraph-docker
# TODO: Don't only allow docker use by root .../
sudo ./build-images.sh 0.3
sudo docker tag janusgraph/janusgraph:0.3.1 gcr.io/$PROJECT/janusgraph:0.3.1
sudo gcloud auth configure-docker
sudo docker push gcr.io/$PROJECT/janusgraph:0.3.1

# Push the image to your project GCR
kubectl run jg-new --image=gcr.io/symphony-graph17038/janusgraph:0.3.1
