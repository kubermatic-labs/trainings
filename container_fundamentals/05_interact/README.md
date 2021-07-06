# Interacting

In this training you will learn how to interact wit a container.

## Using the container id

Start some containers
```bash
docker run -d nginx:1.19.2
docker run -d nginx:1.19.2
docker run -d nginx:1.19.2
```

List all running containers
```
docker ps
```

Note that the containers got some generated names. You can use those names or you can the first letters of the container id to define the container in the commands.

## Starting an additional process in a container

Start a container in detached mode
```bash
docker run -it -d --name my-busybox busybox:1.32.0 sh -c "while true; do $(echo date); sleep 1; done"
```

Start a new shell process in the container
```bash
docker exec -it my-busybox sh
```

Take a look at the running processes in the container. There are additional processes beside the process with the PID 1.
```bash
ps aux
```

Exit the container.
```bash
exit
```

## Cleanup
```bash
docker rm -f my-busybox
```
