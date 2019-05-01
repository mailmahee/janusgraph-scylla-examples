# We recommend running this deployment from a GCP VM
# For example:
# $ gcloud compute instances create deployment-manager \
#   --zone us-west1-b \
#   --machine-type n1-standard-1 \
#   --scopes=https://www.googleapis.com/auth/cloud-platform \
#   --image 'centos-7-v20190423' --image-project 'centos-cloud' \
#   --boot-disk-size 10 --boot-disk-type "pd-standard"

# $ gcloud compute ssh deployment-manager

# Prereqs
# Install Prereqs and Anaconda
# If you need to install conda
# sudo yum install -y bzip2 kubectl
# curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
# sh Miniconda3-latest-Linux-x86_64.sh

# Create a new environment and install prereqs
conda create --name graphdev python=3.7 -y
conda activate graphdev
pip install ruamel-yaml==0.15.94 ansible==2.7.10 gremlinpython==3.4.0

sh scripts/setup/setup_ansible_key.sh
sh scripts/setup/setup_networking.sh

# Setup GKE Cluster
sh scripts/setup/setup_gke.sh

# Uncomment to deploy Scylla w/ Local SSDs
# scripts/provision_and_join_new_scylla_vm.sh -c GraphDev -i 10.138.0.5 -t n1-standard-4

# Deploy Scylla w/ standard SSDs (comment if deploying w/ local SSDs)
# TODO: Add wrapper script for VM deployment
sh scripts/setup/provision_and_join_new_scylla_vm.sh -c GraphDev -i 10.138.21.5 -t n1-standard-4 -s 100
sh scripts/setup/provision_and_join_new_scylla_vm.sh -c GraphDev -n 10.138.21.5 -i 10.138.21.6 -t n1-standard-4 -s 100
sh scripts/setup/provision_and_join_new_scylla_vm.sh -c GraphDev -n 10.138.21.5 -i 10.138.21.7 -t n1-standard-4 -s 100

# Deploy Elasticsearch
kubectl apply -f k8s/elasticsearch/es-storage.yaml
kubectl apply -f k8s/elasticsearch/es-service.yaml
kubectl apply -f k8s/elasticsearch/es-statefulset.yaml

# Deploy JanusGraph