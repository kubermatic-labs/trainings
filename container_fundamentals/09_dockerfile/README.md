# Create a webserver image

In this training we will create an image with our own webserver.

## Inspect the webserver `main.go`

## Build the webserver

```bash
CGO_ENABLED=0 go build -a -installsuffix cgo -o my-webserver main.go
```

## Inspect the Dockerfile

## Build the image

```bash
docker build -t my-webserver:1.0.0 .
```

## Run a container from the image

```bash
docker run -it -d -p 80:80 my-webserver:1.0.0
```

Verify the output with curl:
```bash
curl localhost:80
```

## Cleanup

```bash
docker rm -f $(docker ps -qa)
```
