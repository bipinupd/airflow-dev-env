## Setting up On-prem development environment for ETL pipelines

In this example, we use on-prem resources to create a ETL development environment (Airflow) usng docker and docker-compose.

 ![](image/OnPrem2GCP.jpg)
 
### Install docker and docker-compose

- Install [Docker](https://docs.docker.com/get-docker/)
- Install [Docker Compose](https://docs.docker.com/compose/install/)

### Download docker-compose file and make changes

```
curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.2.4/docker-compose.yaml'
```

- Replace the `AIRFLOW__CORE__LOAD_EXAMPLES` from `True` to `False`
- Add the volume `./data:/opt/airflow/data`

`docker-compose.yaml` is the modified file. 


### Run the script

Create secret in secret manager (secret-id `default`). Finally, decide to rotate the secrets.

Run the `run.sh` with project id and secret id. The script downloads the secret from the secret manager and creates a `google_cloud_default` 

```
sh run.sh -p <<project_id>> -s <<secret>>
```

The script creates `data`, `dag`, `logs` and `plugins` folder which are mounted to the airflow worker. Please copy your DAGs to `dags` folder.

- In case of long running containers and you get permission or service account related errors, run the following commands(to get new service account key):  `gcloud secrets versions access "latest" --secret="default" > data/default.json`

### Clean-up

Once you are done if you want to shutdown the services `docker-compose down` and clean the docker volumes with `docker volume prune -f`