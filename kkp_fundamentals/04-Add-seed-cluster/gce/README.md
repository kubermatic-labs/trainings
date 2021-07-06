# Add nested Seed Cluster to Kubermatic Master Cluster

As we defined in the beginning of the lab, we want to use the current master cluster as a so called "nested seed" cluster. This does mean, that we run a combined master/seed setup, as this diagram shows:

![Combined Master/Seed Cluster Setup](https://docs.kubermatic.com/img/kubermatic/master/concepts/architecture/combined-master-seed.png)

To read more about this, take a look into our docs: [Kubermatic Docs > Concepts > Architecture](https://docs.kubermatic.com/kubermatic/master/architecture/)

## Seed Dependencies
A seed cluster has some dependencies as well. So before we can apply `Seed` configuration as CRD, we need to ensure that we have already set up the following components:

- [NodePort Proxy](https://github.com/kubermatic/kubermatic/tree/master/charts/nodeport-proxy) with matching DNS entries, see [Kubermatic Docs > Installation > Add Seed Cluster > NodePort Proxy](https://docs.kubermatic.com/kubermatic/master/installation/add_seed_cluster/#nodeport-proxy)
- S3 backup location for user cluster backups

### Cluster Backups

Kubermatic performs regular backups of user clusters by snapshotting the etcd of each cluster. By default these backups are stored in any S3 compatible storage location. To demonstrate an on-prem setup, we will use an in-cluster location provided by a PVC. The in-cluster storage is provided by [Minio S3 gateway](https://docs.min.io/docs/minio-gateway-for-s3.html) and the accompanying `minio` Helm chart.

#### Minio Backup Storage Class `kubermatic-backup`

If your cluster has no default storage class, it's required to configure a class explicitly for Minio. You can check the cluster's storage classes via:

```bash
kubectl get storageclasses
```
```
NAME                        PROVISIONER            AGE
kubermatic-fast             kubernetes.io/gce-pd   6d17h
```

**NOTE:** Minio does not need `kubermatic-fast` because it does not require SSD speeds. A larger HDD is preferred.

So we want to set up a dedicated `kubermatic-backup` storage class. See [`./manifests/gce.sc.kubermatic.backup.yaml`](./manifests/gce.sc.kubermatic.backup.yaml) and create a copy in your `kkp-setup` folder:

```bash
cd [training-repo] #kkp_fundamentals
cp .04-Add-seed-cluster/gce.sc.kubermatic.backup.yaml src/kkp-setup
```
Check the configuration. For more details about the storage class parameters of the Google CCM, see [Kubernetes Storage Class - GCE PD](https://kubernetes.io/docs/concepts/storage/storage-classes/#gce-pd).
```
cat ./src/kkp-setup/gce.sc.kubermatic.backup.yaml
```
When everything looks fine, apply the new storage class:
```bash 
kubectl apply -f ./src/kkp-setup/gce.sc.kubermatic.backup.yaml
```
Check that you now have a new storage class installed:
```bash
kubectl get sc
```
```
NAME                          PROVISIONER            AGE
kubermatic-backup (default)   kubernetes.io/gce-pd   16m
kubermatic-fast               kubernetes.io/gce-pd   6d17h
```

#### Install `minio` and `s3-exporter`

To configure the storage class and size, extend your `values.yaml` like so:

```yaml
minio:
  storeSize: '100Gi'
  storageClass: kubermatic-backup
  # access key/secret for the exposed minio S3 gateway
  credentials:
    # access key length should be at least 3 characters
    accessKey: "reoshe9Eiwei2ku5foB6owiva2Sheeth"
    # secret key length should be at least 8 characters
    secretKey: "rooNgohsh4ohJo7aefoofeiTae4poht0cohxua5eithiexu7quieng5ailoosha8"
```

It's also advisable to install the  [S3 Backup Exporter](https://github.com/kubermatic/kubermatic/tree/master/charts/s3-exporter) Helm chart, as it provides basic metrics about user cluster backups. Now let us install the charts:

```bash
helm upgrade --install --create-namespace --wait --values ./src/kkp-setup/values.yaml --namespace minio minio ./src/kkp-setup/releases/v2.17.1/charts/minio
helm upgrade --install --create-namespace --wait --values ./src/kkp-setup/values.yaml --namespace kube-system s3-exporter ./src/kkp-setup/releases/v2.17.1/charts/s3-exporter/
```
After that, verify that all components are installed:
```bash
kubectl get pod,pvc -n minio
```
```
NAME                         READY   STATUS    RESTARTS   AGE
pod/minio-6ddc95b967-q7xm4   2/2     Running   2          2m27s

NAME                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
persistentvolumeclaim/minio-data   Bound    pvc-0b86dfe0-02d0-4cf5-89b6-aab7b3fc1d49   100Gi      RWO            kubermatic-backup   2m27s
```
```bash
kubectl get pod -n kube-system | grep s3
```
```
NAME                           READY   STATUS    RESTARTS   AGE
s3-exporter-7d8f75d6d5-jfzsv   1/1     Running   0          21m
s3-exporter-7d8f75d6d5-shngw   1/1     Running   0          21m
```

## Create Seed Resource

To connect the new seed cluster to the Kubermatic master, you need to create a kubeconfig Secret and a Seed resource **in the master cluster**.

### Create `seed-kubeconfig` credentials

```bash
# create copy of current kubeconfig
cp $KUBECONFIG ./src/kkp-setup/temp-seed-kubeconfig
```

We need to convert the `temp-seed-kubeconfig` to a Kubernetes secret `seed-kubeconfig`. This will be used by the Kubermatic Operator to configure the seed cluster:
```bash
kubectl create secret generic seed-kubeconfig -n kubermatic --from-file kubeconfig=./src/kkp-setup/temp-seed-kubeconfig --dry-run=client -o yaml > ./src/kkp-setup/seed.kubeconfig.secret.yaml
``` 
Verify that the secret `seed-kubeconfig` has been created correctly by executing the following command and making sure the output looks similar to the example output afterwards:
```bash
cat ./src/kkp-setup/seed.kubeconfig.secret.yaml
```
```
apiVersion: v1
data:
  kubeconfig: #... base64 encoded string
kind: Secret
metadata:
  creationTimestamp: null
  name: seed-kubeconfig
  namespace: kubermatic
```
If everything looks fine, please apply the secret and delete the temp file:
```bash
 kubectl apply -n kubermatic -f ./src/kkp-setup/seed.kubeconfig.secret.yaml
## cleanup
rm ./src/kkp-setup/temp-seed-kubeconfig
```

**NOTE:** Make sure the kubeconfig contains static, long-lived credentials. Some cloud providers use custom authentication providers (like GKE using `gcloud` and EKS using `aws-iam-authenticator`). Those will not work in Kubermatic’s usecase because the required tools are not installed inside the cluster environment. You can use the `kubeconfig-serviceaccounts.sh` script from the Kubermatic repository to automatically create proper service accounts inside the seed cluster with static credentials.

### Create initial `Seed` configuration

The Seed resource needs to reference the new kubeconfig Secret like so:
```yaml
apiVersion: kubermatic.k8s.io/v1
kind: Seed
metadata:
  name: europe-west
  namespace: kubermatic
spec:
  # reference to the kubeconfig to use when connecting to this seed cluster
  kubeconfig:
    name: seed-kubeconfig   <<< REFERNCE the secret
    namespace: kubermatic
  ### Seed location
  # Optional: Country of the seed as ISO-3166 two-letter code, e.g. DE or UK.
  # For informational purposes in the Kubermatic dashboard only.
  country: EU
  location: "K1 Cluster"
  # Datacenters contains a map of the possible datacenters (DCs) in this seed.
  # Each DC must have a globally unique identifier (i.e. names must be unique
  # across all seeds).
  datacenters:
    #==================================
    #============== GCP ===============
    #==================================
    ### configs the GCE data center of this lab as an available region for the GCP provider
    gce-eu-west-3:
      country: DE
      location: "Frankfurt"
      spec:
        gcp:
          # Region to use, for example "europe-west3", for a full list of regions see
          # https://cloud.google.com/compute/docs/regions-zones/
          region: "europe-west3"
          # Optional: Regional clusters spread their resources across multiple availability zones.
          # Refer to the official documentation for more details on this:
          # https://cloud.google.com/kubernetes-engine/docs/concepts/regional-clusters
          regional: true
          # List of enabled zones, for example [a, c]. See the link above for the available
          # zones in your chosen region.
          zone_suffixes: [a,b,c]
```

Refer to the [Seed CRD documentation](https://docs.kubermatic.com/kubermatic/master/tutorials_howtos/project_and_cluster_management/seed_cluster/) for a complete example of the Seed CustomResource and all possible datacenter configurations. We will see additional datacenter examples in a later chapter.

Let's apply the manifest above in the master cluster. Kubermatic will pick up the new Seed and begin to reconcile it by installing the required Kubermatic components (for a nested seed in our case):

**ATTENTION:** If you are using KKP CE version, seed must be named as `Kubermatic` instead of `europe-west`.

```bash
# create copy of seed template
cp .04-Add-seed-cluster/seed.europe-west.yaml .src/kkp-setup/
# apply the config change
kubectl apply -n kubermatic -f ./src/kkp-setup/seed.europe-west.yaml
```
Verify the changes have been applied by the Kubermatic Operator
```bash
kubectl -n kubermatic get deployments,pods
``` 
``` 
NAME                                                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kubermatic-api                         2/2     2            2           5d23h
deployment.apps/kubermatic-dashboard                   2/2     2            2           5d23h
deployment.apps/kubermatic-master-controller-manager   2/2     2            2           5d23h
deployment.apps/kubermatic-operator                    1/1     1            1           6d12h
deployment.apps/kubermatic-seed-controller-manager     2/2     2            2           17h
deployment.apps/nodeport-proxy-envoy                   3/3     3            3           17h
deployment.apps/nodeport-proxy-updater                 1/1     1            1           17h
deployment.apps/seed-proxy-europe-west                 1/1     1            1           17h

NAME                                                        READY   STATUS    RESTARTS   AGE
pod/kubermatic-api-5d4c8b85-rcsbn                           1/1     Running   0          43m
pod/kubermatic-api-5d4c8b85-wjznz                           1/1     Running   0          43m
pod/kubermatic-dashboard-567bf59fc8-cldzx                   1/1     Running   0          43m
pod/kubermatic-dashboard-567bf59fc8-p694r                   1/1     Running   0          43m
pod/kubermatic-master-controller-manager-67779d4765-92n2s   1/1     Running   0          43m
pod/kubermatic-master-controller-manager-67779d4765-tkmcz   1/1     Running   0          43m
pod/kubermatic-operator-5f95566545-6s27s                    1/1     Running   0          43m
pod/kubermatic-seed-controller-manager-6bff66b7c9-jlsmh     1/1     Running   0          42m
pod/kubermatic-seed-controller-manager-6bff66b7c9-vckjq     1/1     Running   0          42m
pod/nodeport-proxy-envoy-6f8df6dcc9-bpbqb                   2/2     Running   0          43m
pod/nodeport-proxy-envoy-6f8df6dcc9-nvmgg                   2/2     Running   0          43m
pod/nodeport-proxy-envoy-6f8df6dcc9-qccw7                   2/2     Running   0          43m
pod/nodeport-proxy-updater-855f6cc689-vdl4z                 1/1     Running   0          43m
pod/seed-proxy-europe-west-695d8c499f-h9shb                 1/1     Running   0          3h14m
``` 
In addition to the pods, dedicated services should have been deployed as well. To ensure the connectivity:
```bash
kubectl -n kubermatic get svc
```
```
NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                          AGE
kubermatic-api           NodePort       10.100.250.104   <none>          80:32544/TCP,8085:30212/TCP                      5d23h
kubermatic-dashboard     NodePort       10.108.88.100    <none>          80:31330/TCP                                     5d23h
nodeport-proxy           LoadBalancer   10.101.167.84    34.91.118.218   31788:31208/TCP,31750:32647/TCP,8002:32321/TCP   17h
seed-proxy-europe-west   ClusterIP      10.101.137.118   <none>          8001/TCP                                         17h
seed-webhook             ClusterIP      10.97.36.255     <none>          443/TCP                                          5d23h
```

**NOTE:** If you encounter errors, take a look at the logs of the deployment `kubermatic-seed-controller-manager`. On success, it should look like this:
```bash
# take a look at both pods of the deployment
kubectl -n kubermatic logs kubermatic-seed-controller-manager-xxxx-xxxx
```
```
{"level":"info","time":"2020-07-08T09:23:08.710Z","caller":"util/hello.go:32","msg":"Starting Kubermatic Seed Controller-Manager (Enterprise Edition)...","worker-name":"","version":"weekly-2020-27-8-gd77a13c8e"}
W0708 09:23:08.710529       1 client_config.go:541] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
I0708 09:23:08.745574       1 leaderelection.go:241] attempting to acquire leader lease  kube-system/seed-controller-manager...
I0708 09:23:30.902394       1 leaderelection.go:251] successfully acquired lease kube-system/seed-controller-manager
{"level":"info","time":"2020-07-08T09:23:30.902Z","caller":"leaderelection/leaderelection.go:84","msg":"acquired the leader lease","worker-name":"","leader-name":"seed-controller-manager"}
{"level":"info","time":"2020-07-08T09:23:30.902Z","caller":"seed-controller-manager/main.go:266","msg":"Executing migrations...","worker-name":""}
{"level":"info","time":"2020-07-08T09:23:30.947Z","caller":"seed-controller-manager/main.go:270","msg":"Migrations executed successfully","worker-name":""}
{"level":"info","time":"2020-07-08T09:23:30.947Z","caller":"seed-controller-manager/main.go:272","msg":"Starting the controller-manager...","worker-name":""}
```

### NodePort Proxy `nodeport-proxy`

Since Kubermatic `2.14` the seed cluster automatically creates the so called [NodePort Proxy]. The NodePort Proxy will expose the containerized control plane components of every user cluster. So please be aware that the endpoint of the service `nodeport-proxy` is reachable for your end users.

To make the user cluster control plane API endpoint(s) workable, the IP address **MUST** match your seed cluster DNS entry `*.SEED_CLUSTER_NAME.kubermatic.YOUR-DNS-ZONE.loodse.training`. Let's set this up in the next chapter:
- [51_setup_seed_dns.md](./51_setup_seed_dns.md)
