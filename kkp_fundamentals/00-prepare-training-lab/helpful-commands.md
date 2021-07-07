# Helpful Commands

# git

## personal access token

To clone a private repository in the cloud shell you can generate a separate personal access token to ensure secure secrets:
1. Visit https://github.com/settings/tokens and click `Generate new token`   
2. Give a `Note` e.g. `Kubermatic Training`
3. Select the scope `repo (all)`
4. Click `Generate Token` - now you can use the token as password for `git clone https://...`

To save the token at the local shell, you can activate the git credential helper: `git config credential.helper store`

# Kubernetes

Start using Kubernets with `kubectl`.

Launch containers with `kubectl run my-nginx --image=nginx`. 

Expose the deployment inside of the cluster `kubectl expose deployment my-nginx --port 80`.

Now you have one type `deployment` (created by `kubectl run ...`) and one type `service` created. This maps in Kubernetes to the following components:

`kubectl get all`

## Install the latest kubectl

```bash
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
sudo mv kubectl /google/google-cloud-sdk/bin/kubectl
sudo chmod +x /google/google-cloud-sdk/bin/kubectl
```

## Enable auto completion

add the following lines to your `~/.bashrc` file:

```bash
# kubectl, k
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k

# kubeone (if installed already)
source <(kubeone completion bash)
```

## Install `kubens`, `kubetcx`, `fubectl`
***NOTE:*** on google cloud check if it is already installed first.

```bash
mkdir -p ~/bin && cd ~/bin
wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx
wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens
wget https://rawgit.com/kubermatic/fubectl/master/fubectl.source
chmod 755 kubectx kubens
wget https://github.com/junegunn/fzf-bin/releases/download/0.21.1/fzf-0.21.1-linux_amd64.tgz
tar xf fzf-0.21.1-linux_amd64.tgz
# → kubectx, kubens, fzf, fubectl
echo 'source ~/bin/fubectl.source' >> ~/.bashrc

#reload source file
source ~/.bashrc
```

## How to write the right spec?

* Take a look at the [Kubernets reference docs](https://kubernetes.io/docs/reference/)
* Use `kubectl explain pod.spec.containers` 

## Clean up the namespace

The implementation of `kubectl run` and `kubectl expose` creates automatically a label `run=<name>` to the deployment and the service. Execute the following command to see it:
`kubectl get svc,pods --show-labels` 

Now use `kubectl delete all -l run=my-nginx` to stop and remove the running container and the service.

## More?

Take a look at [github.com/loodse/kubectl-hacking](https://github.com/loodse/kubectl-hacking)
