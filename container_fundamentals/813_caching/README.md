# Caching

In this training you will learn how to write Dockerfiles which will increase build time due to using caches.

## Inspect the Dockerfile and the server.js file

## Build and run the docker image

```bash
docker build -t node:1.0.0 .
docker run -it --rm -p 80:80 node:1.0.0
# Visit the site via the external IP of your node
```

## Re-build the docker image

```bash
docker build -t node:1.0.0 .
```

Note that all layers are taken from the cache.

## Adapt the application and re-build the docker image

Change the message to something different in the file `server.js`

```bash
docker build -t node:1.0.0 .
docker run -it --rm -p 80:80 node:1.0.0
# Visit the site via the external IP of your node
```

Note that all layers starting from the `RUN npm install` layer is not taken from the cache. On bigger projects this can increase your build times significantly. 

## Fix the Dockerfile

### Change the content of the Dockerfile to this

```docker
FROM node:12
WORKDIR /app
COPY package.json .
RUN npm install
COPY server.js .
CMD [ "npm", "start" ]
```

### Do the initial build

```bash
docker build -t node:2.0.0 .
```

### Re-build the docker image

Change the message to something different in the file `server.js`.

```bash
docker build -t node:2.0.0 .
docker run -it --rm -p 80:80 node:2.0.0
# Visit the site via the external IP of your node
```

Note the layers which are taken from the cache.

## Cleanup

```bash
docker rm -f $(docker ps -qa)
```
