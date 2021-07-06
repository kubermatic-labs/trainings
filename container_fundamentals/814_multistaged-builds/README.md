# Multistaged builds

In this training you will learn how to build your applications.

## Inspect the Dockerfile and the main.go file

## Build and run the application

```bash
docker build -t go:1.0.0 . 
docker run -it go:1.0.0
```

## Make use of multistaged builds

Now we will create the same application with a multistaged build. This will decrease the image size and will shrink the images attack vector.

Adapt the Dockerfile to the following
```docker
# builder image
FROM golang:1.15.2-alpine3.12 as builder
RUN mkdir /build
ADD main.go /build/
WORKDIR /build
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# run image
FROM alpine:3.12
RUN mkdir /app
WORKDIR /app
COPY --from=builder /build/main .
ENTRYPOINT [ "./main" ]
```

## Build and run the application

```bash
docker build -t go:2.0.0 . 
docker run -it go:2.0.0
```

## Compare the size of the images

```bash
docker image ls go
```

# Cleanup

```bash
docker rm -f $(docker ps -qa)
```