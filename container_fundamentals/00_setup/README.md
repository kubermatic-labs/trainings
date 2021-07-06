# Provision VM and install docker

## Run the setup.sh bash script

You wil be asked about the project name. 

```bash
./setup.sh
```

## SSH into the new VM

Visit https://console.cloud.google.com/compute/instances and click the `Connect SSH` button.

## Install docker

```bash
# Update the machine
sudo apt update
sudo apt upgrade -y

# Add mandatory packages for installing Docker
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Setup the stable repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package index and install Docker
sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io
```

## Add your user to the docker group

This is done not having to sudo each docker command. Note to put this change into effect you have to re-open the cloud shell.

```bash
sudo usermod -aG docker $USER
```
