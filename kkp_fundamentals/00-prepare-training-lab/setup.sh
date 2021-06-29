#!/bin/bash

## check if authenticated
if [ $(gcloud auth list --filter=status:ACTIVE --format='value(account)' | grep loodse.training) ]; then
  echo successfull authenticated!
else
  gcloud auth login
fi
gcloud auth list

echo "-------------------"

PROJECT_COUNT=$(gcloud projects list --format json | jq .[].name | tr -d \" | wc -l)
if (( PROJECT_COUNT == 1)); then
  PROJECT_NAME=$(gcloud projects list --format json | jq .[].name | tr -d \" )
  echo "Using project $PROJECT_NAME"
fi
if [[ -z $PROJECT_NAME ]]; then
  echo "INPUT: Type PROJECT_NAME (student-XX-project):" && read PROJECT_NAME
fi
export REGION=europe-west4
export ZONE=europe-west4-a

set -euxo pipefail

# set gcloud params
gcloud config set project $PROJECT_NAME
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# export PROJECT_ID
echo ">>> GCP_PROJECT_ID=$PROJECT_NAME"
