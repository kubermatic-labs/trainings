# Docker Compose

In this course we will install a minimal Prometheus stack via Docker Compose. 

## Install Docker Compose

```bash
# Get Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# Make Docker Compose executable
sudo chmod +x /usr/local/bin/docker-compose
# Verify the installation
docker-compose version
```

## Inspect the file `prometheus.yml`

## Inspect the Docker Compose file called `docker-compose.yml`

## Start all containers

```bash
docker-compose up -d
# Verify everything is working
docker ps
# Check the exposed metrics of CAdvisor
curl localhost:8080/metrics
# Visit Grafana in your Browser (User admin, Password admin)
http://<EXTERNAL-IP>
```

## Create a Datasource

Create a Datasource of type `Prometheus` and the URL `http://prometheus:9090`

## Import a Dashboard

Import the Dashboard with id `193`. Set the Datasource to the previously generated.

## Cleanup

```bash
docker-compose down
```