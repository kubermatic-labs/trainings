# Persistence

In this training you will learn how to make data persistent in your container.

## Inspect the Dockerfile and build the Docker image

```bash
docker build -t persistence:1.0.0 .
```

## Container layer

The container layer only makes changes persistent until the container gets removed.

```bash
# Create the container
docker run -it -d --name container-layer persistence:1.0.0

# Printout the content of the file
docker exec -it container-layer cat /data/file.txt

# Stop the container
docker stop container-layer

# Restart the container
docker start container-layer

# Printout the content of the file again
# Note that the file contains the timestamps from the first run
docker exec -it container-layer cat /data/file.txt

# Remove the container
# Note that all changes get lost
docker rm -f container-layer
```

## Volumes

Volumes are managed by docker.

```bash
# Create the container
docker run -it -d --name volumes -v /data persistence:1.0.0

# Printout the content of the file
docker exec -it volumes cat /data/file.txt

# Cleanup all pre-existing volumes
# Note that Docker will not delete volumes of running containers
docker volume prune

# List all volumes
docker volume ls

# Show the details of the volume via `volume inspect`
docker volume inspect <VOLUME-NAME>

# Show the details of the volume via `inspect`
docker inspect volumes | grep -A10 Mounts

# Change the content of the file on the host
sudo bash -c 'echo text from host >>  <HOST-VOLUME-PATH>/file.txt'

# Printout the content of the file
# Note that your change is also in
docker exec -it volumes cat /data/file.txt

# Delete the container
docker rm -f volumes 

# List the volumes
# Note that the volume is not deleted yet
docker volume ls

# Cleanup all volumes
docker volume prune

# Try to printout the content of the file
# Note that the file does not exist anymore
sudo cat <HOST-VOLUME-PATH>/file.txt
```

## Bind Mounts

Bind mount volumes let you manage the lifecycle of your data youself.

```bash
# Create the container
docker run -it -d --name bind-mounts -v $PWD/data:/data persistence:1.0.0

# Check the content of the file `file.txt` in the folder `data` in your current directory
cat data/file.txt

# Printout the volumes
# Note that the volume is not managed by docker
docker volume ls

# Delete the container
docker rm -f bind-mounts

# Cleanup all volumes
docker volume prune

# Check the content of the file `file.txt` again
# Note that the file still exists 
cat data/file.txt
```
