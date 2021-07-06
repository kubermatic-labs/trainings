# Master DNS Setup

KKP Master need two DNS Records:

- `kubermatic.YOUR-DNS-ZONE.loodse.training` for the [Kubermatic Dashboard](https://github.com/kubermatic/dashboard)
- `*.kubermatic.YOUR-DNS-ZONE.loodse.training` for monitoring/logging components behind the `oauth` Dex/ingress

For reference see the Docs: [Kubermatic Docs - Install Kubermatic - Create DNS Records](https://docs.kubermatic.com/kubermatic/v2.17/guides/installation/install_kkp_ce/#:~:text=create%20dns%20records)

## Start DNS transaction

First of all start a DNS zone editing transaction.:

```bash
cd ~/mnt/kkp_fundamentals/src/kkp-setup
# get your gcloud DNS_ZONE
gcloud dns managed-zones list
```

```bash
# Output
NAME                DNS_NAME                             DESCRIPTION  VISIBILITY
student-XX-xxxx     student-XX-xxxx.loodse.training.     k8c          public
```

```bash
## export variable to adjust your zone NAME 
export DNS_ZONE=student-XX-xxxx  #WITHOUT loodse.training!
gcloud dns record-sets transaction start --zone=$DNS_ZONE
```

---

## Prepare DNS records

Get the LoadBalancer External IP by following command.

```bash
kubectl get svc -n nginx-ingress-controller 
```

```bash
# Output
NAME                       TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)                      AGE
nginx-ingress-controller   LoadBalancer   10.103.3.87   X.X.X.X       80:31542/TCP,443:31806/TCP   16m
```

**Replace  X.X.X.X with the `nginx-ingress-controller` external IP**:

```bash
export INGRESS_DNS_IP=X.X.X.X
```

### Add DNS record sets for Dashboard

`kubermatic.student-XX.xxxx.loodse.training`  ---->  LoadBalancer IP address of the Nginx Service:

```bash
gcloud dns record-sets transaction add --zone=$DNS_ZONE --name="kubermatic.$DNS_ZONE.loodse.training" --ttl 300 --type A $INGRESS_DNS_IP
```

### Add DNS record sets for Wildcard IAP components (Monitoring/Logging)

`*.kubermatic.student-XX.xxxx.loodse.training`  ---->  LoadBalancer IP address of the Nginx Service

```bash
gcloud dns record-sets transaction add --zone=$DNS_ZONE --name="*.kubermatic.$DNS_ZONE.loodse.training" --ttl 300 --type A $INGRESS_DNS_IP
```

---

## Execute DNS changes

Finally check and execute those changes.

```bash
cat transaction.yaml
gcloud dns record-sets transaction execute --zone $DNS_ZONE
```

Confirm the executed DNS records:

```bash
gcloud dns record-sets list --zone=$DNS_ZONE
```

```bash
NAME                                            TYPE   TTL    DATA
student-XX.xxx.loodse.training.                 NS     21600  ns-cloud-e1.googledomains.com.,ns-cloud-e2.googledomains.com.,ns-cloud-e3.googledomains.com.,ns-cloud-e4.googledomains.com.
student-XX.xxxx.loodse.training.                SOA    21600  ns-cloud-e1.googledomains.com. cloud-dns-hostmaster.google.com. 5 21600 3600 259200 300
kubermatic.student-XX.xxxx.loodse.training.     A      300    x.x.x.x
*.kubermatic.student-XX.xxxx.loodse.training.   A      300    x.x.x.x
```

---

## Verify DNS propagation

Wait for the DNS to propagate and then verify it.

```bash
## check if the DNS record are propagated
nslookup kubermatic.$DNS_ZONE.loodse.training
nslookup test.kubermatic.$DNS_ZONE.loodse.training
```

```bash
# Output
Server: 10.0.100.1
Address: 10.0.100.1#53

Non-authoritative answer:
Name: kubermatic.student-XX.xxxx.loodse.training
Address: x.x.x.x
```

---

## Verify SSL Certificate

Test if server is reachable by `https://`, which will validate that cert-manager created a valid SSL certificate:

```bash
curl https://kubermatic.$DNS_ZONE.loodse.training
```

Output should be something like below:

```bash
<!doctype html>
<html>

<head>
  <meta charset="utf-8">
  <title>Kubermatic</title>
...
```

But if you see such an error:

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

```bash
NAMESPACE   NAME            READY   SECRET          ISSUER            STATUS                                                              AGE
kubermatic  kubermatic-tls  False   kubermatic-tls  letsencrypt-prod  Waiting for CertificateRequest "kubermatic-tls-ltbkp" to complete   69s
oauth       dex-tls         False   dex-tls         letsencrypt-prod  Waiting for CertificateRequest "dex-tls-hlktb" to complete          69s
```

You can continue and check in a few minutes and later you will see:

```bash
NAMESPACE    NAME             READY   SECRET           ISSUER             STATUS                                          AGE
kubermatic   kubermatic-tls   True    kubermatic-tls   letsencrypt-prod   Certificate is up to date and has not expired   8m
oauth        dex-tls          True    dex-tls          letsencrypt-prod   Certificate is up to date and has not expired   8m
```

**Note:** If after a while still certificates are not `Ready` you can delete them by command `kubectl delete certificate -n kubermatic kubermatic-tls` and wait for new certificate to be validated.

## Login to KKP Dashboard

You should now be able to open the KKP Dashboard and login with your configured e-mail ID of user at your `values.yaml`, for example: `student-XX-xxxx@loodse.training` and password `password`. You can check configured values by following command.

```bash
cd [training-repo]
cd ~/mnt/kkp_fundamentals/src/kkp-setup
grep -A 5 static values.yaml
```

![Kubermatic Login](../.pics/k8c_login.png)

Now try to create a project `student-XX`. Before we can create cluster, we need to setup a `Seed` object for the Kubermatic seed cluster, which we will do in a next chapter.

![Kubermatic Project](../.pics/k8c_project.png)

Validate thought command line.

```bash
kubectl get project
```

```bash
NAME         AGE    HUMANREADABLENAME   STATUS
vkhbtrph6s   2m1s   student-00          Active
```
