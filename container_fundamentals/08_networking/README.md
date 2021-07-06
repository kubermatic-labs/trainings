# Networking

In this training you will learn how to make use of docker networks

## List all networks

Docker has pre-installed networks.

```bash
docker network ls
```

## Expose via bridge network

The bridge network will be used by default.

```bash
docker run -it -d -p 8080:80 --name bridge-network nginx:1.19.2
curl localhost:8080
```

## Expose via host network

You can use the network of your host. You can only use a port once. 

```bash
docker run -it -d --net host --name host-network nginx:1.19.2
curl localhost
```

## Create and use a custom network

```bash
# Create the new bridge network
docker network create --driver=bridge --subnet=192.168.0.0/16 my-network

# List all networks
docker network ls

# Run a webserver in the network
docker run -it -d --net my-network --name webserver nginx:1.19.2

# Verify that the ip of the container is contained by the subnet
docker inspect webserver | grep IPAddress

# Create a curl container and curl the webserver by its container name
docker run -it --rm --net my-network curlimages/curl:7.72.0 webserver

# Create a custom network alias for a container
docker rm -f webserver
docker run -it -d --net my-network --name webserver --net-alias my-nginx nginx:1.19.2

# Create a curl container and curl the webserver by its network alias
docker run -it --rm --net my-network curlimages/curl:7.72.0 my-nginx
```

## Cleanup

```bash
docker rm -f $(docker ps -qa)
```
