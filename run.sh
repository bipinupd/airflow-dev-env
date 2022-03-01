#!/bin/bash

: '
Gets the input from user
 p as PROJECT_ID and s as SECRET_ID
'
while getopts p:s: flag
do
    case "${flag}" in
        p) PROJECT_ID=${OPTARG};;
        s) SECRET_ID=${OPTARG};;
    esac
done

description="Usage: \n \tsh run -p <<project_id>> -s <<secret>> \n\t project-id: Project Id where the secret is stored \n\t secret: Secret name where service account json is stored"
if [ -z ${PROJECT_ID} ]; 
then
	echo "Project id is missing"
	echo $description
	exit 1
fi
if [ -z ${SECRET_ID} ];
then
	echo "Secret is missing"
	echo $description
	exit 1
fi

echo "Project Id: $PROJECT_ID";
echo "Secret Id $SECRET_ID"
mkdir -p ./dags ./logs ./plugins ./data
echo "AIRFLOW_UID=$(id -u)\nAIRFLOW_GID=0" > .env
gcloud secrets versions access "latest" --secret="${SECRET_ID}" > ./data/default.json

docker-compose up airflow-init

docker-compose up -d

container_id=`docker ps --format "{{.ID}}" --filter name=airflow-worker`
status=`docker container inspect -f '{{.State.Status}}' $container_id`

runtime="2 minute"
endtime=$(date -ud "$runtime" +%s)
while [ "$status" != "running"  ] && [ $(date -u +%s) -le $endtime ]
do
	status=`docker container inspect -f '{{.State.Status}}' $container_id`
	echo "Sleeping for 5 seconds ... Max wait time is 2 minutes"
	sleep 5
done

if [ "$status" != "running" ];
then
	echo "Airflow worker is not up .... Giving up after 2 min"
	exit 2
fi
: '
Create a default connection (google_cloud_default)
Provide the key path
'
docker exec -it $container_id airflow connections add google_cloud_default --conn-type=google_cloud_platform \
    --conn-extra='{"extra__google_cloud_platform__key_path": "/opt/airflow/data/default.json", "extra__google_cloud_platform__scope": "https://www.googleapis.com/auth/cloud-platform"}'