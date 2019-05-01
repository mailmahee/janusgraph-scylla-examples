#!/usr/bin/env bash
#
# Setup GKE cluster
#
# 2019 - Ryan Stauffer, Enharmonic, Inc.

# TODO: Change the default project
PROJECT="symphony-graph17038"

# NETWORK=enharmonic
CLUSTER_NAME=graph-deployment
ZONE="us-west1-b"
VM_TYPE="n1-standard-4"
KUBERNETES_VERSION="1.12.7-gke.10"

while getopts ":hp:" opt; do
  case $opt in
    h) echo ""
       echo "Automated Data System Deployment"
       echo "GKE Setup"
       echo "©2019 Enharmonic, Inc."
       echo ""
       echo "Description"
       echo "==========="
       echo "Creates a Google Kubernetes Engine cluster for Enharmonic Graph Data System deployment"
       echo ""
       echo ""
       echo "   Usage   "
       echo "==========="
       echo "-p  GCP Project to be used for deployment (default: $PROJECT). Usage '-p [MyProject]'"
       echo ""
       echo "-h  Display this help message and exit"
       echo ""
       exit 2
       ;;
    p)  PROJECT=$OPTARG ;;
    \?)  echo "Invalid option: -$OPTARG"
        exit 2
        ;;
    :)  echo "Option -$OPTARG requires and argument."
        exit 2
        ;;
  esac
done

# Create a single zone cluster
gcloud container clusters create $CLUSTER_NAME \
  --zone $ZONE \
  --machine-type $VM_TYPE \
  --num-nodes 3 \
  --cluster-version $KUBERNETES_VERSION \
  --disk-size=40
