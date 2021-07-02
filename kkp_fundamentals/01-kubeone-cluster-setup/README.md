# KubeOne Cluster setup

KKP installs on pre-existing Kubernetes cluster. KubeOne is the open-source solution from Kubermatic to manage the entire lifecycle of the Kubernetes cluster, including installing and provisioning, upgrading, repairing, and unprovisioning using declarative way.

## Prepare Secrets

To begin with, we need a secret to authenticate with GCP. Steps are quite similar as described in [k1_fundamentals Training](../../k1_fundamentals):

**Option-1** - Copy existing secrets from K1 Fundamentals Training.

If you did the k1 fundamentals labs, feel free to copy the needed secrets to your KKP secret folder.

``` bash
### copy the secrets
cp -r ~/mnt/k1_fundamentals/.secrets ~/mnt/kkp_fundamentals/
```

**Note - If you did the K1 fundamentals labs, please ensure that you destroyed the former KubeOne Cluster and DNS records with [../../k1_fundamentals/99_cluster-cleanup-or-pause](../../k1_fundamentals/99_cluster-cleanup-or-pause)!**

**Option-2** - Create fresh credentials

```bash
##### Ensure that you execute below commands inside of the tooling container

cd ~/mnt/kkp_fundamentals/
mkdir ./.secrets && cd ./.secrets

# ensure your connected
gcloud projects list

# create new service account
gcloud iam service-accounts create k1-service-account

# get service account id
gcloud iam service-accounts list

# configure your IDs
export GCP_PROJECT_ID=__YOUR_GCP_PROJECT_ID__                  # student-XX-xxxx
export GCP_SERVICE_ACCOUNT_ID=__YOUR_GCP_SERVICE_ACCOUNT_ID__  # k1-service-account@student-XX-xxxx.iam.gserviceaccount.com 

# create policy binding
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID --member serviceAccount:$GCP_SERVICE_ACCOUNT_ID --role='roles/compute.admin'
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID --member serviceAccount:$GCP_SERVICE_ACCOUNT_ID --role='roles/iam.serviceAccountUser' 
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID --member serviceAccount:$GCP_SERVICE_ACCOUNT_ID --role='roles/viewer'
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID --member serviceAccount:$GCP_SERVICE_ACCOUNT_ID --role='roles/storage.admin'

# create a new json key for your service account
gcloud iam service-accounts keys create --iam-account $GCP_SERVICE_ACCOUNT_ID k8c-cluster-provisioner-sa-key.json

# create ssh keys for nodes
ssh-keygen -f id_rsa

#check if looks similar
ls -l

-rw-------  1 kubermatic root 2610 May 27 21:23 id_rsa
-rw-r--r--  1 kubermatic root  577 May 27 21:23 id_rsa.pub
-rw-------  1 kubermatic root 2333 May 27 21:23 k8c-cluster-provisioner-sa-key.json
```

---

## Create Master Cluster

For simplicity of training we have the predefined manifests at [`./kkp-master.template`](./kkp-master.template), refer below notes:

- Master Control Plan count is `1`, for production **HA control plan** at least `3` masters are recommend! *For the training we reduce some costs and only hold 1 master VM*
- Worker Nodes are using Autoscaler settings what are more reactive as it should used in production.
- Worker Node OS doesn't get updated on the startup (speed up at scaling)

Run the following to provision the kubeone cluster:

```bash
# copy the template to your source folder
cd ~/mnt/kkp_fundamentals/
mkdir src
cp -r 01-kubeone-cluster-setup/kkp-master.template src/kkp-master

export GCP_PROJECT_ID=__YOUR_GCP_PROJECT_ID__                  # student-XX-xxxx

# replace TODO-YOUR-GCP-PROJECT-ID with your project id 
cd ~/mnt/kkp_fundamentals/src/kkp-master
find . -type f -exec sed -i 's/TODO-YOUR-GCP-PROJECT-ID/'"$GCP_PROJECT_ID"'/g' {} +

# start SSH agent and add id-rsa
source ../../helper-scripts/source-ssh-agent.sh

# deploy K1 cluster
make k1-tf-apply k1-apply
```

After everything is provisioned, check if nodes will get healthy:

```bash
export KUBECONFIG=~/mnt/kkp_fundamentals/src/kkp-master/kkp-master-kubeconfig
watch kubectl get machinedeployments.cluster.k8s.io,machinesets,machine,nodes -A
```
