    1  sudo apt update
    2  apt upgrade -y
    3  sudo apt upgrade -y
    4  docker ps
    5  sudo apt install containerd
    6  ctr
    7  ctr image ls
    8  sudo ctr image ls
    9  sudo apt install crictl
   10  VERSION="v1.20.0"
   11  curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-${VERSION}-linux-amd64.tar.gz --output crictl-${VERSION}-linux-amd64.tar.gz
   12  sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
   13  rm -f crictl-$VERSION-linux-amd64.tar.gz
   14  crictl version
   15  sudo crictl version
   16  vi /etc/crictl.yaml
   17  sudo vi /etc/crictl.yaml
   18  crictl version
   19  sudo vi /etc/crictl.yaml
   20  crictl version
   21  ctr version
   22  sudo ctr version
   23  sudo ctr ls
   24  sudo ctr image ls
   25  sudo ctr --help
   26  sudo ctr containers ls
   27  history