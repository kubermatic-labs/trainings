v# KubeOne Master setup

Setup a Kubeone HA cluster, similar as described in [../../../k1_fundamentals](../../../k1_fundamentals):

## Prepare Secrets

### Option 1: Copy from K1 Fundamentals Training
If you did the k1 fundamentals labs, feel free to copy the needed secrets to your KKP secret  folder [`../../.secrets`](../../.secrets) of this lab:
```
cd [training-repo]  #kkp_fundamentals
pwd
# /home/kubermatic/mnt/kkp_fundamentals

### copy the secrets
cp -r ../k1_fundamentals/.secrets ./
```
**If not already happened ensure, that you destroyed the former KubeOne Cluster with [../../../k1_fundamentals/99_cluster-cleanup-or-pause](../../../k1_fundamentals/99_cluster-cleanup-or-pause)!**

## Option 2: Create fresh credentials
```bash
cd [training-repo]  #kkp_fundamentals
mkdir .secrets
```
To be able to create a new kubeone based master cluster, we need at least the following secrets under the  `.secrets` folder:
- SSH Key: `ssh-keygen -f .secrets/id_rsa`
- [GCP Service Account](../../../k1_fundamentals/01_create-cloud-credentials) 

```
#check if looks similar
ls -la .secrets

-rw-------  1 kubermatic root 2610 May 27 21:23 id_rsa
-rw-r--r--  1 kubermatic root  577 May 27 21:23 id_rsa.pub
-rw-------  1 kubermatic root 2333 May 27 21:23 k8c-cluster-provisioner-sa-key.json
```

## Create Master Cluster

Check the predefined manifests [`./kkp-master.template`](./kkp-master.template), and note:
- Master Control Plan count ``  is `1`, for production **HA control plan** at least 3 master are recommend! *For the training we reduce some costs and only hold 1 master VM*
- Worker Nodes are using Autoscaler settings what are more reactive as it should used in production.
- Worker Node OS doesn't get updated on the startup (speed up at scaling)

We will now look into the following steps to provision the basic cluster:

1. Replace the values with your individual one
```bash
./00_setup/setup.sh
#.... some output
#>>> GCP_PROJECT_ID=student-xx-XXX

# set now your project ID
export GCP_PROJECT_ID=student-xx-XXX

# copy the template to your source folder
mkdir src
cp -r 01_master_cluster/gce/kkp-master.template src/kkp-master
# replace TODO-YOUR-GCP-PROJECT-ID with your project id 
cd src/kkp-master
sed -i 's/TODO-YOUR-GCP-PROJECT-ID/'"$GCP_PROJECT_ID"'/g' */**

# start SSH agent and add id-rsa
source ../../helper-scripts/source-ssh-agent.sh

# deploy K1 cluster
make k1-tf-apply k1-apply
```

After everything is provisioned, check if nodes will get healthy:
```bash
export KUBECONFIG=`pwd`/kkp-master-kubeconfig
watch kubectl get machinedeployments.cluster.k8s.io,machinesets,machine,nodes -A
```
## (If needed) cleanup DNS Entries

Delete entries `*.DNS_ZONE.loodse.training.` at [Google Cloud DNS](https://console.cloud.google.com/net-services/dns/zones/)


