#!/usr/bin/env bash
#
# This script references the ScyllaDB script `gce_deploy_and_install_scylla_cluster.sh`
# originally released under the Apache License, Version 2.0 and copyright ©2017 ScyllaDB
# https://github.com/scylladb/scylla-code-samples/tree/master/gce_deploy_and_install_scylla_cluster
#
# Additions and modifications by
# Ryan Stauffer, Enharmonic, Inc.
#
# Provisions and configures a new Scylla VM
# then joins it to an existing cluster (if it exists)
# We use a separate script for more control over the process,
# and to facilitate node type migrations and auto-scale up/down & out/in



## Variables
# Scylla
CLUSTER_NAME="scylla-graph"
SEED_NODES=""
RELEASE="3.0"

# GCP
PROJECT="default-project"
ZONE="us-west1-b"
VM_TYPE="n1-standard-8"
INTERNAL_IP=""
TAGS="scylla,graph-data-system"
SSD_SIZE="40"
NVME_NUM="2"
LOCAL_SSD=NO
IMAGE='centos-7-v20190423'
IMAGE_PROJECT='centos-cloud'
TIMESTAMP=`date "+%m-%d--%H%M"`

# Ansible / SSH
SSH_USERNAME=ansible
KEY_PATH=$HOME/.ssh/$SSH_USERNAME

while getopts ":hlp:z:s:c:t:n:i:" opt; do
  case $opt in
    h) echo ""
       echo "Scylla Node Deployment"
       echo ""
       echo "Description"
       echo "==========="
       echo "Creates and configures a new Scylla node and attaches it to an existing cluster."
       echo ""
       echo ""
       echo "   Usage   "
       echo "==========="
       echo "-p  GCP Project to be used for deployment (default: $PROJECT). Usage '-p [MyProject]'"
       echo "-z  Zone in which to deploy the Scylla VM (default: $ZOME). Usage '-z [MyZone]'"
       echo "-s  SSD Size in GB (default: $SSD_SIZE GB) to be attached to each VM. Usage '-s [DiskSize]'"
       echo "-c  Name of the Scylla cluster to join (default: $CLUSTER_NAME). Usage '-c [MyCluster]'"
       echo "-t  VM type (default: $VM_TYPE). Usage '-t [gce-vm-type]'"
       echo "-n  Seed nodes of the existing Scylla cluster to join (default: None). Usage '-n 10.128.10.11'"
       echo "-i  Internal IP to assign to the VM.  If none is supplied, the VM will be automatically assigned an IP by GCP"
       echo ""
       echo "-l  Use local SSDs (NVMe) instead of networked SSD drives"
       echo ""
       echo "-h  Display this help message and exit"
       echo ""
       exit 2
       ;;
    p)  PROJECT=$OPTARG ;;
    z)  ZONE=$OPTARG ;;
    s)  SSD_SIZE=$OPTARG ;;
    c)  CLUSTER_NAME=$OPTARG ;;
    t)  VM_TYPE=$OPTARG ;;
    n)  SEED_NODES=$OPTARG ;;
    i)  INTERNAL_IP=$OPTARG ;;
    l)  LOCAL_SSD=YES ;;
    \?)  echo "Invalid option: -$OPTARG"
        exit 2
        ;;
    :)  echo "Option -$OPTARG requires and argument."
        exit 2
        ;;
  esac
done

INSTANCE_NAME="scylla-$TIMESTAMP"
echo "Deploying Scylla VM with spec"
if [ $LOCAL_SSD == "YES" ]; then
  echo "$VM_TYPE | 2x 375GB local SSD (NVMe) drives | 20GB boot disk in zone $ZONE"
  # Create VM
  gcloud compute --project=$PROJECT \
    instances create $INSTANCE_NAME \
    --zone $ZONE \
    --machine-type $VM_TYPE \
    --maintenance-policy=MIGRATE \
    --private-network-ip $INTERNAL_IP \
    --scopes=https://www.googleapis.com/auth/devstorage.full_control,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
    --tags $TAGS \
    --local-ssd interface=nvme \
    --local-ssd interface=nvme \
    --image $IMAGE --image-project $IMAGE_PROJECT \
    --metadata ssh-keys="$SSH_USERNAME:$(cat $KEY_PATH.pub)" \
    --boot-disk-size 20 --boot-disk-type "pd-ssd" \
    --boot-disk-device-name $INSTANCE_NAME

else
  echo "$VM_TYPE | $SSD_SIZE GB PD-SSD drive | 20GB boot disk in zone $ZONE"
  # Create SSD Drive of size $SSD_SIZE
  DISK_NAME=$INSTANCE_NAME-ssd
  gcloud compute --project=$PROJECT \
    disks create $DISK_NAME \
    --size $SSD_SIZE \
    --type "pd-ssd" \
    --zone $ZONE

  # Create VM
  gcloud compute --project=$PROJECT \
    instances create $INSTANCE_NAME \
    --zone $ZONE \
    --machine-type $VM_TYPE \
    --maintenance-policy=MIGRATE \
    --private-network-ip $INTERNAL_IP \
    --scopes=https://www.googleapis.com/auth/devstorage.full_control,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
    --tags $TAGS \
    --disk "name=$DISK_NAME,device-name=$DISK_NAME,mode=rw,boot=no,auto-delete=yes" \
    --image $IMAGE --image-project $IMAGE_PROJECT \
    --metadata ssh-keys="$SSH_USERNAME:$(cat $KEY_PATH.pub)" \
    --boot-disk-size 20 --boot-disk-type "pd-ssd" \
    --boot-disk-device-name $INSTANCE_NAME
fi

# Wait for VM to come online before configuring Scylla with Ansible
echo ""
echo ""
echo "Waiting 45 seconds for VM network to start prior to Scylla configuration."
sleep 45

NEW_IP=`gcloud compute instances describe $INSTANCE_NAME --zone $ZONE | grep -i networkip | cut -d ":" -f2 | awk '{$1=$1};1'`
# Generate servers.ini file for Ansible.
echo "Creating inventory file (servers.ini) with VM  internal IP addresses"
echo "[scylla]" > servers.ini
echo $NEW_IP >> servers.ini


echo ""
echo "### Setting Seed IPs in playbook YAML file."
echo ""
# Update seed node IP and Scylla version and create a new playbook yaml file.
if [ ${#SEED_NODES} -ge 1 ]; then
  echo "### Setting Seed IPs to $SEED_NODES in playbook yaml file."
else
  SEED_NODES=$NEW_IP
  echo "### Setting Seed IP as new IP $SEED_NODES in playbook yaml file."
fi
sed -e s/seedIP/$SEED_NODES/g -e s/scyllaVer/$RELEASE/g scripts/setup/playbook_template/scylla_install_template.yaml > scylla_install_new.yaml

# Update cluster name in playbook yaml file.
echo ""
echo "### Setting unique cluster name in playbook yaml file"
echo ""
sed -i -s s/cluster_name_placeholder/$CLUSTER_NAME/g scylla_install_new.yaml

# Update disk names (NVMe) in playbook yaml file vars.
if [ "$LOCAL_SSD" == "YES" ]; then
  echo ""
  echo "### Local SSD NVMe drives, updating disk names in playbook.yaml file."
  echo ""
  for i in `seq 1 $NVME_NUM`; do DISK=$DISK"/dev/nvme0n$i,"; done
  x=`echo "$DISK" | sed 's/,$//'`
  sed -i -e s~\/dev\/sdb~$x~g scylla_install_new.yaml
fi

# Update remote_user name in playbook.yaml file.
echo ""
echo "### Setting Remote User to $SSH_USERNAME in playbook.yaml file."
echo ""
sed -i -e s/remoteUser/$SSH_USERNAME/g scylla_install_new.yaml

# Run the ansible playbook against the new IP
# This finishes the Scylla node configuration
# ansible-playbook scylla_install_new.yaml --private-key=$KEY_PATH -v -i "servers.ini"
# ansible-playbook scylla_install_new.yaml --private-key=~/.ssh/ansible -v -i "servers.ini"
# sed -i -e 's/^/#/' ~/.ssh/known_hosts
echo ""
echo "### Installing Scylla $RELEASE cluster using Ansible playbook"
echo ""
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook scylla_install_new.yaml --private-key=$KEY_PATH -v -i "servers.ini"

# End message
echo ""
echo "### New Scylla VM @ $NEW_IP should be running and joining the ring."
echo "### Loging to one of the nodes and run 'nodetools status'"
echo "### Note: it may take up to 1 minutes for the node to join the ring."
echo ""
echo ""
