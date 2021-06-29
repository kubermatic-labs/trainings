# Prepare Training LAB

## Prerequisites

Prerequisites what need to be fulfilled by the attendees of the trainings:

- Common understanding of Kubernetes architecture, API objects and principles.
- Basic compute infrastructure knowledge about networking, DNS and resource provisioning.
- Internet Access to GitHub, GoogleCloud, terraform provider, quay.io.
- Latest Docker Installed.
- git client- IDE / Editor
  (preferred with Kubernetes support e.g. [VSCode](https://code.visualstudio.com/) or [Intellij Plugin](https://plugins.jetbrains.com/plugin/10485-kubernetes/versions)).

## Setup Tooling Container

**Option-1** - Setup Tooling container on your local workstation

To speed up, the setup we will use the [KubeOne Tooling Container](https://github.com/kubermatic/community-components/tree/master/helper/kubeone-tool-container) container, where every needed tool is already setup.

If you have docker, git and a common IDE installed locally, you can quickly start with:

```bash
git clone https://github.com/kubermatic-labs/trainings.git
docker run --name  kubeone-tool-container -v $(pwd)/trainings:/home/kubermatic/mnt -t -d quay.io/kubermatic-labs/kubeone-tooling:1.2.3
docker exec -it kubeone-tool-container bash
```

**Option-2** - Use google cloud shell to setup Tooling container

Open the [Google Cloud Shell](https://shell.cloud.google.com) in a separate window: `https://shell.cloud.google.com`

You have to execute same above command to continue LAB.

## Verify setup

After you entered the container, verify the setup:

```bash
### executed inside the tooling container

#### list of training folders
cd mnt/kkp_fundamentals
ls -la

#### version json with kubeone v1.2.3 should be shown
kubeone version

#### a recent terraform version (>= 0.15) should be shown
terraform version

#### a recent gcloud SDK (>= 340.0.0)
gcloud version

#### a recent kubectl version (>= v.1.21.1)
kubectl version --short
```

## Authenticate your GCP account

Execute the setup script:

```bash
./00-prepare-training-lab/setup.sh

### should list your training projects
gcloud projects list
PROJECT_ID        NAME              PROJECT_NUMBER
student-XX-xxxx   student-XX-xxxx   999999999999
```

## Other helpful content

The most needed shortcuts and tooling helper are already installed in the tooling container, anyway you could look over the [helpful-commands.md](helpful-commands.md) section, to read how e.g. install auto-completion and [fubectl](https://github.com/kubermatic/fubectl) for fast Kubernetes Navigation

If you don't like to use the kubeone tooling container and install all tools directly locally, you can take a look at:

- [KubeOne Tooling Container - Dockerfile](https://github.com/kubermatic/community-components/blob/master/helper/kubeone-tool-container/Dockerfile)

As an opensource driven company, Kubermatic tries to contribute also a lot of helpful components, helper or information to the community, so feel free to take a look at the recent resources:

- [Official Documentation](https://docs.kubermatic.com/)
- [Kubermatic Community Components](https://github.com/kubermatic/community-components)
- [Kubermatic Forum](https://forum.kubermatic.com/)
