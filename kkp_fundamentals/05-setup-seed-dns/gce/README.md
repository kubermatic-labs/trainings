# Configure  Kubermatic Seed DNS record for `europe-west` 

The Kubernetes API servers of all user cluster control planes running in the seed cluster are exposed by the NodePort Proxy. By default each user cluster gets a virtual domain name like `[cluster-id].[seed-name].[kubermatic-domain]`, e.g. `hdu328tr.europe-west.kubermatic.YOUR-DNS-ZONE.loodse.training`. For the Seed from the previous step `kubermatic.YOUR-DNS-ZONE.loodse.training` is the main domain where the Kubermatic dashboard and API are available.

To facilitate this, a wildcard DNS record `*.[seed-name].[kubermatic-domain]` must be created. As with the other DNS records the exact target depends on whether or not `LoadBalancer` services are supported on the seed Kubernetes cluster. For more Information see [Kubermatic Docs - Add Seed Cluster - Update DNS](https://docs.kubermatic.com/kubermatic/master/guides/installation/add_seed_cluster_ce/#:~:text=Update,Depending). In our example the seed cluster is also the master, but this might not be the case for every setup, see [Kubermatic Docs - Concepts - Architecture Large-Scale Deployments](https://docs.kubermatic.com/kubermatic/master/architecture/) for more info. 

## Start DNS transaction

First of all start a DNS zone editing transaction.:

```bash
# get gcloud DNS_ZONE
gcloud dns managed-zones list
```
```
NAME                DNS_NAME                             DESCRIPTION  VISIBILITY
student-XX-training student-XX-training.loodse.training. k8c          public
```
```bash
## adjust to your zone NAME 
## WITHOUT loodse.training!
export DNS_ZONE=student-XX-training

# Check existing record sets.
gcloud dns record-sets list --zone=$DNS_ZONE

gcloud config set project $DNS_ZONE
gcloud dns record-sets transaction start --zone=$DNS_ZONE
```

## NodePort Proxy DNS record
Now let's place the DNS record for the seed node-port service. In this example we named our seed cluster `europe-west` which results in a URL `USER_CLUSTER_ID.europe-west.$DNS_ZONE.loodse.training`:

**ATTENTION:** If you are using KKP CE version, seed name will be `Kubermatic` instead of `europe-west`. Which results in a URL `USER_CLUSTER_ID.kubermatic.$DNS_ZONE.loodse.training`:

```bash
kubectl -n kubermatic get svc nodeport-proxy
```
```
NAME          TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)          AGE
nodeport-lb   LoadBalancer   10.103.188.232   XX.XX.XX.XX     8002:31232/TCP   36m
```
**Replace  XX.XX.XX.XX with the `nodeport-lb` external IP**:
```bash
# define external IP as environment var for the later commands
export NODEPORT_DNS_IP=XX.XX.XX.XX
```

### Wildcard entry for node-port
`*.europe-west.kubermatic.$DNS_ZONE.loodse.training` ----> node-port proxy IP # For EE version 
`*.kubermatic.kubermatic.$DNS_ZONE.loodse.training` ----> node-port proxy IP # For CE version 

```bash
gcloud dns record-sets transaction add --zone=$DNS_ZONE --name="*.europe-west.kubermatic.$DNS_ZONE.loodse.training" --ttl 300 --type A  $NODEPORT_DNS_IP
```

**Optional - Only applicable for CE**:

```bash
gcloud dns record-sets transaction add --zone=$DNS_ZONE --name="*.kubermatic.kubermatic.$DNS_ZONE.loodse.training" --ttl 300 --type A  $NODEPORT_DNS_IP
```
## Execute DNS changes

Finally, check transaction file before executing changes.
```                    
cat transaction.yaml
```
Now, Execute changes.
```                    
gcloud dns record-sets transaction execute --zone $DNS_ZONE
```

Confirm the DNS records:
```
gcloud dns record-sets list --zone=$DNS_ZONE
```
```
NAME                                                     TYPE  TTL    DATA
student-00-training.loodse.training.                           NS    21600  ns-cloud-e1.googledomains.com.,ns-cloud-e2.googledomains.com.,ns-cloud-e3.googledomains.com.,ns-cloud-e4.googledomains.com.
student-00-training.loodse.training.                           SOA   21600  ns-cloud-e1.googledomains.com. cloud-dns-hostmaster.google.com. 6 21600 3600 259200 300
kubermatic.student-00-training.loodse.training.                A     300    34.91.40.238
*.kubermatic.student-00-training.loodse.training.              A     300    34.91.40.238
*.europe-west.kubermatic.student-00-training.loodse.training.  A     300    34.91.118.218
```

## Verify DNS propagation of NodePort Proxy DNS

Wait for the DNS to propagate, then proceed to install the SSL certificate from Let's encrypt service:
```bash
## check if the DNS record are propagated
nslookup test.europe-west.kubermatic.$DNS_ZONE.loodse.training # For EE
nslookup test.kubermatic.kubermatic.$DNS_ZONE.loodse.training # For CE
```
```
Server:		10.0.100.1
Address:	10.0.100.1#53

Non-authoritative answer:
Name:	test.europe-west.kubermatic.student-00-training.loodse.training
Address: 34.91.40.238
```

In the next step we will create a user cluster into our newly set up seed:
- [52_create_user_cluster.md](52_create_user_cluster.md)
