# Create Kubermatic DNS records

To get a trusted SSL certificate, and a proper DNS name we now need to set two DNS Records:
- `kubermatic.YOUR-DNS-ZONE.loodse.training` for the [Kubermatic Dashboard](https://github.com/kubermatic/dashboard)
- `*.kubermatic.YOUR-DNS-ZONE.loodse.training` for monitoring/logging components behind the `oauth` Dex/ingress

For reference see the Docs: [Kubermatic Docs - Install Kubermatic - Create DNS Records](https://docs.kubermatic.com/kubermatic/master/guides/installation/install_kkp_ce/#:~:text=create%20dns%20records)

**ATTENTION: some of the IP's can only be determined after the matching Helm chart / Load Balancer is deployed**

## Start DNS transaction

First of all start a DNS zone editing transaction.:

```bash
# get gcloud DNS_ZONE
gcloud dns managed-zones list
```
```
NAME                DNS_NAME                             DESCRIPTION  VISIBILITY
student-XX-xxxx     student-XX-xxxx.loodse.training.     k8c          public
```
```bash
## adjust to your zone NAME 
## WITHOUT loodse.training!
export DNS_ZONE=student-XX-xxxx
gcloud dns record-sets transaction start --zone=$DNS_ZONE
```

## Ingress DNS record
Then proceed to add the A record for the ingress controller:

```bash
kubectl get svc -n nginx-ingress-controller 
```
```
NAME                       TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)                      AGE
nginx-ingress-controller   LoadBalancer   10.103.3.87   XX.XX.XX.XX   80:31542/TCP,443:31806/TCP   16h
```
**Replace  XX.XX.XX.XX with the `nginx-ingress-controller` external IP**:
```
# define external IP as environment var for the later commands
export INGRESS_DNS_IP=XX.XX.XX.XX
```

### Dashboard DNS name
`kubermatic.student-00.loodse.training`  ---->  LoadBalancer IP address of the Nginx Service:

```bash
gcloud dns record-sets transaction add --zone=$DNS_ZONE --name="kubermatic.$DNS_ZONE.loodse.training" --ttl 300 --type A $INGRESS_DNS_IP
```
### Wildcard IAP components (Monitoring/Logging)
`*.kubermatic.student-00.loodse.training`  ---->  LoadBalancer IP address of the Nginx Service

```bash
gcloud dns record-sets transaction add --zone=$DNS_ZONE --name="*.kubermatic.$DNS_ZONE.loodse.training" --ttl 300 --type A $INGRESS_DNS_IP
```

## Execute DNS changes

Finally check and execute those changes.
```                    
cat transaction.yaml
gcloud dns record-sets transaction execute --zone $DNS_ZONE
```

Confirm the DNS records:

```
gcloud dns record-sets list --zone=$DNS_ZONE
```
```
NAME                                            TYPE  TTL    DATA
student-00.loodse.training.                  NS    21600  ns-cloud-e1.googledomains.com.,ns-cloud-e2.googledomains.com.,ns-cloud-e3.googledomains.com.,ns-cloud-e4.googledomains.com.
student-00.loodse.training.                  SOA   21600  ns-cloud-e1.googledomains.com. cloud-dns-hostmaster.google.com. 5 21600 3600 259200 300
kubermatic.student-00.loodse.training.       A     300    34.91.40.238
*.kubermatic.student-00.loodse.training.     A     300    34.91.40.238
```

## Verify DNS propagation

Wait for the DNS to propagate, then proceed to install the SSL certificate from Let's encrypt service:

### Ingress endpoint
```bash
## check if the DNS record are propagated
nslookup kubermatic.$DNS_ZONE.loodse.training
nslookup test.kubermatic.$DNS_ZONE.loodse.training
```
```
Server:		10.0.100.1
Address:	10.0.100.1#53

Non-authoritative answer:
Name:	kubermatic.student-00.loodse.training
Address: 34.91.40.238
```
Test if the ingress server is reachable:
```bash
## curl the http endpoind
curl http://kubermatic.$DNS_ZONE.loodse.training
```
```
<html>
<head><title>308 Permanent Redirect</title></head>
<body>
<center><h1>308 Permanent Redirect</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

Test if server is reachable by `https://`, which will validate that cert-manager created a valid SSL certificate:
```bash
## curl the https endpoint
curl https://kubermatic.$DNS_ZONE.loodse.training
```
If you see such an error:
```bash
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```
The output means that the SSL certificate has not been created. It may take several minutes to create the certificates though!

To check the status of the SSL certificate (ensure that the status is True and ready):
```bash
watch kubectl get certificates -A -o wide
```
first you will see
```
NAMESPACE   NAME   READY   SECRET    ISSUER             STATUS                                                       AGE
oauth       dex    False   dex-tls   letsencrypt-prod   Waiting for CertificateRequest "dex-302303659" to complete   69s
```
You can continue and check in a few minutes, you will see:
```
NAMESPACE   NAME   READY   SECRET    ISSUER             STATUS                                          AGE
oauth       dex    True    dex-tls   letsencrypt-prod   Certificate is up to date and has not expired   8m
```

### Verify

Now also verify if an `Ingress` and a valid `Certificate` were created:
```bash
kubectl -n kubermatic get ingress,certificate
```
```
NAME                            HOSTS                                      ADDRESS        PORTS     AGE
ingress.extensions/kubermatic   kubermatic.student-00.loodse.training      34.91.40.238   80, 443   15m

NAME                                     READY   SECRET           AGE
certificate.cert-manager.io/kubermatic   True    kubermatic-tls   15m
```
## Login to Kubermatic Dashboard

Youd should now be able to open the Dashboard in browser at `https://kubermatic.$DNS_ZONE.loodse.training` and login with your configured e-mail ID of user at your `values.yaml`, for example: `student-XX-xxx@loodse.training` and default password is `password`. You can check your password with below steps.
```bash
cd [training-repo] #kkp_fundamentals
cd src/kkp-setup/
grep -C 5 static values.yaml
```

![Kubermatic Login](../../.pics/k8c_login.png)

Now try to create a project `student-XX`. Before we can create cluster, we need to setup a `Seed` object for the Kubermatic seed cluster.

![Kubermatic Project](../../.pics/k8c_project.png)

This should also be visible in your master cluster:
```bash
kubectl get project
```
```
NAME         AGE    HUMANREADABLENAME   STATUS
vkhbtrph6s   2m1s   student-00          Active
```
