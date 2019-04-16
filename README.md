# Grafana
Grafana ECS Image

### Build Grafana and Push to AWS ECR
To build a new Docker image of Grafana for ECS you need to update the Dockerfile to the desired version and run the build.

- Checkout the last version of the repo and create a new branch
- Update the **Dockerfile** to specify the version to build

`FROM grafana/grafana:6.0.2`

The versions available are listed on the [Grafana Docker Hub](https://hub.docker.com/r/grafana/grafana/tags).

- Create a Pull Request (this will build the image and validate it).
- Merge your Pull Request and the Jenkins Job will deploy it to the Management ECS Cluster.


## Required Environment Variables
In order to build and run Grafana ECS in AWS, you need to setup an RDS Mysql instance, with the `grafana` database. The [grafana mysql guide](https://grafana.com/docs/features/datasources/mysql/) has information on this setup.

This build utilizes the [aws-env tool](https://github.com/Droplr/aws-env) from [Droplr](https://github.com/Droplr) to grab values from the AWS Parameter store as environment variables that the ECS service will use. See the `ENTRYPOINT` in the [Dockerfile](Dockerfile)

```
GF_AUTH_DISABLE_LOGIN_FORM
GF_AUTH_GENERIC_OAUTH_ALLOWED_DOMAINS
GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP
GF_AUTH_GENERIC_OAUTH_API_URL
GF_AUTH_GENERIC_OAUTH_AUTH_URL
GF_AUTH_GENERIC_OAUTH_CLIENT_ID
GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET
GF_AUTH_GENERIC_OAUTH_ENABLED
GF_AUTH_GENERIC_OAUTH_NAME
GF_AUTH_GENERIC_OAUTH_SCOPES
GF_AUTH_GENERIC_OAUTH_TOKEN_URL
GF_DATABASE_NAME
GF_DATABASE_PASSWORD
GF_DATABASE_TYPE
GF_DATABASE_USER
GF_SERVER_ROOT_URL
```

For more information on the Grafana required values, see the [grafana docker guide](https://grafana.com/docs/installation/docker/). 








