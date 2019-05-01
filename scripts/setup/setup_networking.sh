#!/usr/bin/env bash
#
# Setup network and subnetworks in GCP for Graph Data System
#
# 2019 - Ryan Stauffer, ryan@enharmonic.ai

PROJECT="symphony-graph17038"

NETWORK=graph-data-system

while getopts ":hp:" opt; do
  case $opt in
    h) echo ""
       echo "Automated Data System Deployment"
       echo "Networking Setup"
       echo "©2019 Enharmonic, Inc."
       echo ""
       echo "Description"
       echo "==========="
       echo "Creates a new primary network and 1 subnetwork for Enharmonic Graph Data System deployment"
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

# Allow default network to have ingress/egress on port 80??
gcloud compute --project=$PROJECT \
  networks create $NETWORK \
  --description="Graph Data System main VPC network" \
  --subnet-mode=custom

gcloud compute --project=$PROJECT \
  networks subnets create graph-data-system-std \
  --network=$NETWORK \
  --region=us-west1 \
  --range=10.138.21.0/24 \
  --enable-private-ip-google-access

# Allow all internal traffic
gcloud compute --project=$PROJECT \
  firewall-rules create $NETWORK-allow-internal \
  --network $NETWORK \
  --allow tcp,udp,icmp \
  --source-ranges 10.138.21.0/24

# Allow SSH
gcloud compute --project=$PROJECT \
  firewall-rules create $NETWORK-allow-ssh \
  --network $NETWORK \
  --allow tcp:22

# Allow ICMP
gcloud compute --project=$PROJECT \
  firewall-rules create $NETWORK-allow-icmp \
  --network $NETWORK \
  --allow icmp
