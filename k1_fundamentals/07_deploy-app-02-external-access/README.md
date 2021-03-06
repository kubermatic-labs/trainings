# Deploy Sample Application (with external access)

The application stack with external access will be created with the following steps:

* Deploy an ingress controller as a reverse proxy to terminate the HTTP/HTTPS traffic and forward to the respective deployment
* CertManager will be used to create the necessary SSL certificate from LetsEncrypt 
* Deploy the hello-world application and try to access it

## Deploy [Nginx Ingress](https://github.com/kubernetes/ingress-nginx)

First we install the ingress controller (Nginx):
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud/deploy.yaml
```

### Verify the ingress load balancer

Check the loadbalancer service type for the Nginx ingress controller:
```bash
# change to the new ingress-nginx namespace
kubectl config set-context --current --namespace=ingress-nginx
# or
kcns ingress-nginx

kubectl get pod,svc,ep
```
```
NAME                                            READY   STATUS      RESTARTS   AGE
pod/ingress-nginx-admission-create-ddqn2        0/1     Completed   0          3m11s
pod/ingress-nginx-admission-patch-5kg9d         0/1     Completed   0          3m11s
pod/ingress-nginx-controller-86cbd65cf7-4s4jh   1/1     Running     0          3m21s

NAME                                         TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)                      AGE
service/ingress-nginx-controller             LoadBalancer   10.109.207.66    34.90.218.24   80:30075/TCP,443:32404/TCP   3m21s
service/ingress-nginx-controller-admission   ClusterIP      10.104.253.212   <none>         443/TCP                      3m21s

NAME                                           ENDPOINTS                      AGE
endpoints/ingress-nginx-controller             10.244.7.3:80,10.244.7.3:443   3m21s
endpoints/ingress-nginx-controller-admission   10.244.7.3:8443                3m21s
```

## Deploy the [Cert Manager](https://cert-manager.io/docs/)
Let's deploy the CertManager:

```bash
# Create a namespace to run cert-manager in
kubectl create namespace cert-manager
kubectl config set-context --current --namespace=cert-manager
# or
kcns cert-manager

# Install the CustomResourceDefinitions and cert-manager itself
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.3.1/cert-manager.yaml

### check the pods
kubectl get pods -n cert-manager
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-57f89dbdf6-448w8              1/1     Running   0          44m
cert-manager-cainjector-6c78fb8b77-jksrl   1/1     Running   0          44m
cert-manager-webhook-5567d8d596-k7szh      1/1     Running   0          44m
```

### Create the necessary DNS A records just like below

**HINT: some of the IP's can only be determined after the ingress controller's service is deployed**

First of all start a DNS zone editing transaction.:

```bash
# ensure gcloud use the correct project
gcloud projects list
gcloud config set project student-XX-xxxx

# set DNS_ZONE
gcloud dns managed-zones list
NAME                DNS_NAME                             DESCRIPTION  VISIBILITY
student-XX-XXXX     student-XX-XXXX.loodse.training.     k8c          public

## adjust to your zone name
export DNS_ZONE=student-XX-XXXX
gcloud dns record-sets transaction start --zone=$DNS_ZONE
```

Then proceed to add the A records:

`*.student-XX-XXXX.loodse.training`  ---->  LoadBalancer IP address of the Nginx Service

```bash
kubectl get svc -n ingress-nginx
### use your external service ip
export SERVICE_NGINX_EXT_IP=xx.xx.xx.xx 
gcloud dns record-sets transaction add --zone=$DNS_ZONE --name="*.$DNS_ZONE.loodse.training" --ttl 300 --type A $SERVICE_NGINX_EXT_IP
```

Finally execute those changes.

```bash
#check the DNS transaction yaml
cat transaction.yaml

gcloud dns record-sets transaction execute --zone $DNS_ZONE
```
*Hint: On Errors you can also modify the created `transaction.yaml` or fix the error over google console [Cloud DNS](https://console.cloud.google.com/net-services/dns/zones)*

Confirm the DNS records:

```bash
gcloud dns record-sets list --zone=$DNS_ZONE

NAME                                           TYPE   TTL    DATA
*.student-XX.loodse.XXXX.                      A      300    35.241.157.248
```
### Create a Cluster Issuer:
***ATTENTION: view and edit the .yaml files before you apply !!!**
```bash
cd [training-repo] #training-repo => folder 'k1_fundamentals'
cd 07_deploy-app-02-external-access
export TRAINING_EMAIL=student-XX.XXXX@loodse.training #Use email provided by trainer for training
sed -i "s/your-email@example.com/$TRAINING_EMAIL/g" manifests/lb.cluster-issuer.yaml
kubectl apply -f manifests/lb.cluster-issuer.yaml
## check the status
kubectl describe clusterissuers.cert-manager.io letsencrypt-issuer

```

***N.B - Since http01 is used to issue the certificate, ensure that you create a DNS A record for the domain, this A record should point to the IP address of the Nginx Ingress controller load balancer service.***

*Wait for the DNS to propagate, then proceed to install the SSL certificates from Let's encrypt:*

### Deploy the sample application

Let's deploy a sample application. This will entail creating a deployment, a service, an ingress and a certificate.

```bash
## create a new app-ext namespace
kubectl create ns app-ext
kubectl config set-context --current --namespace=app-ext
# or
kcns app-ext

# Deployment manifest:
kubectl apply -f manifests/app.deployment.yaml    

# Service manifest:
kubectl apply -f manifests/app.service.yaml    
```
Now let's configure a valid SSL certificate for you app. `sed` will replace `TODO-YOUR-DNS-ZONE` with your DNS ZONE, e.g.:`student-XX-XXXX.loodse.training`. Please ensure you will use **YOUR STUDENT ID**:
```bash
# check no certificate is present
kubectl get certificates

#Ingress manifest:
## update the DNS_ZONE to your dedicated student DNS zone
sed -i 's/TODO-YOUR-DNS-ZONE/'"$DNS_ZONE"'/g' manifests/app.ingress.yaml
kubectl apply -f manifests/app.ingress.yaml    

## Check the status of the SSL certificate (ensure that the status is True and ready):
kubectl get certificates -o yaml

```

**Check the status of the application components:**

```bash
kubectl get pods
```
```
NAME                        READY   STATUS    RESTARTS   AGE
helloweb-7f7f7474fc-rgwl6   1/1     Running   0          11s
```
```bash
kubectl describe svc helloweb
```
```
Name:              helloweb
Namespace:         default
Labels:            app=hello

Selector:          app=hello,tier=web
Type:              ClusterIP
IP:                10.102.189.51
Port:              <unset>  80/TCP
TargetPort:        8080/TCP
Endpoints:         10.244.3.8:8080
Session Affinity:  None
Events:            <none>
```
```bash
kubectl get ingresses.networking.k8s.io
```
```
NAME       HOSTS                                     ADDRESS          PORTS      AGE
helloweb   app-ext.student-XX-XXXX.loodse.training   34.76.142.126    80, 443    98s
```

Ensure that there are endpoints available for the service.

Test the application (this is being served via the ingress controller with the Let's encrypt SSL certificate):

```bash
echo https://app-ext.$DNS_ZONE.loodse.training
# your DNS zone should be displayed
# https://app-ext.YOUR-DNS-ZONE.loodse.training

curl https://app-ext.$DNS_ZONE.loodse.training

Hello, world!
Version: 1.0.0
Hostname: helloweb-7f7f7474fc-rgwl6
```

**Some ingress logs to show that the traffic is passing through it:**

```bash
kubectl logs -n ingress-nginx ingress-nginx-controller-XXXXX-xxxx
# or use the fuzzy way to follow the logs
klog -f
# type ingress, select the ingress controller pod
```
```
I0717 11:06:04.032365       6 status.go:296] updating Ingress default/helloweb status from [] to [{34.76.142.126 }]
I0717 11:06:04.039261       6 event.go:258] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"default", Name:"helloweb", UID:"c3748923-a882-11e9-aac8-42010af00003", APIVersion:"networking.k8s.io/v1beta1", ResourceVersion:"18930", FieldPath:""}): type: 'Normal' reason: 'UPDATE' Ingress default/helloweb


I0717 11:06:36.110931       6 event.go:258] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"default", Name:"helloweb", UID:"c3748923-a882-11e9-aac8-42010af00003", APIVersion:"networking.k8s.io/v1beta1", ResourceVersion:"19038", FieldPath:""}): type: 'Normal' reason: 'UPDATE' Ingress default/helloweb

I0717 11:06:36.110991       6 backend_ssl.go:58] Updating Secret "default/loodse-dev-tls" in the local store

I0717 11:06:36.111294       6 controller.go:133] Configuration changes detected, backend reload required.

I0717 11:06:36.212252       6 controller.go:149] Backend successfully reloaded.
[17/Jul/2019:11:06:36 +0000]TCP200000.000

10.240.0.5 - [10.240.0.5] - - [17/Jul/2019:11:07:12 +0000] "GET / HTTP/2.0" 200 65 "-" "curl/7.64.0" 39 0.001 [default-helloweb-80] [] 10.244.3.8:8080 65 0.000 200 336f1ccd6efbde55fc2505fee6dc7ab5
```
