## Docker Compose

In the last lab, we learned how to create Docker container images using Dockerfile and implementing Infrastructure as Code approach.

This time we'll learn how to describe in code and manage our local container infrastructure with [Docker Compose](https://docs.docker.com/compose/overview/).

## Intro

Remember how in the previous lab we had to use a lot of `docker` CLI commands in order to run our application locally? Specifically, we had to create a network for containers to communicate, a volume for container with MongoDB, launch MongoDB container, launch our application container.

This is a lot of manual work and we only have 2 containers in our setup. Imagine how much work it would be to run a microservices application which includes a dozen of services.

To make the management of our local container infrastructure easier and more reliable, we need a tool that would allow us to describe the desired state of a local environment and then it would create it from our description.

**Docker Compose** is exactly the tool we need. Let's see how we can use it.

## Install Docker Compose

Follow the official documentation on [how to install Docker Compose](https://docs.docker.com/compose/install/) on your system.

Verify that installed version of Docker Compose is => 1.18.0:

```bash
$ docker-compose -v
```

## Describe Local Container Infrastructure

Docker Compose could be compared to Terraform, but it manages only Docker container infrastructure. It allows to start containers, create networks and volumes, pass environment variables to containers, publish ports, etc.

Let's use Docker Compose [declarative syntax](https://docs.docker.com/compose/compose-file/) to describe what our local container infrastructure should look like.

Create a file called `docker-compose.yml` inside your `iac-tutorial` repo with the following content:

```yml
version: '3.3'

# define services (containers) that should be running
services:
  mongo-database:
    image: mongo:3.2
    # what volumes to attach to this container
    volumes:
      - mongo-data:/data/db
    # what networks to attach this container
    networks:
     - raddit-network

  raddit-app:
    # path to Dockerfile to build an image and start a container
    build: .
    environment:
      - DATABASE_HOST=mongo-database
    ports:
      - 9292:9292
    networks:
     - raddit-network
    # start raddit-app only after mongod-database service was started
    depends_on:
      - mongo-database

# define volumes to be created
volumes:
  mongo-data:
# define networks to be created
networks:
  raddit-network:
```

In this compose file, we define 3 sections for configuring different components of our container  infrastructure.

Under the **services** section we define what containers we want to run. We give each service a `name` and pass the options such as what `image` to use to launch container for this service, what `volumes` and `networks` should be attached to this container.

If you look at `mongo-database` service definition, you should find it to be very similar to the docker command that we used to start MongoDB container in the previous lab:

```bash
$ docker run --name mongo-database \
    --volume mongo-data:/data/db \
    --network raddit-network \
    --detach mongo:3.2
```

So the syntax of Docker Compose can be easily understood by a person not even familiar with it [the documentation](https://docs.docker.com/compose/compose-file/#service-configuration-reference).

`raddit-app` services configuration is a bit different from MongoDB service in a way that we specify a `build` option instead of `image` to build the container image from a Dockerfile before starting a container:

```yml
raddit-app:
  # path to Dockerfile to build an image and start a container
  build: .
  environment:
    - DATABASE_HOST=mongo-database
  ports:
    - 9292:9292
  networks:
    - raddit-network
  # start raddit-app only after mongod-database service was started
  depends_on:
    - mongo-database
```

Also, note the `depends_on` option which allows us to tell Docker Compose that this `raddit-app` service depends on `mongo-database` service and should be started after `mongo-database` container was launched.

The other two top-level sections in this file are  **volumes** and **networks**. They are used to define volumes and networks that should be created:

```yml
# define volumes to be created
volumes:
  mongo-data:
# define networks to be created
networks:
  raddit-network:
```

These basically correspond to the commands that we used in the previous lab to create a named volume and a network:

```bash
$ docker volume create mongo-data
$ docker network create raddit-network
```

## Create Local Infrastructure

Once you described the desired state of you infrastructure in `docker-compose.yml` file, tell Docker Compose to create it using the following command:

```bash
$ docker-compose up
```

or use this command to run containers in the background:

```bash
$ docker-compose up -d
```

## Access Application

The application should be accessible to your as before at http://localhost:9292

## Save and commit the work

Save and commit the `docker-compose.yml` file created in this lab into your `iac-tutorial` repo.

## Conclusion

In this lab, we learned how to use Docker Compose tool to implement Infrastructure as Code approach to managing a local container infrastructure. This helped us automate and document the process of creating all the necessary components for running our containerized application.

If we keep created `docker-compose.yml` file inside the application repository, any of our colleagues can create the same container environment on any system with just one command. This makes Docker Compose a perfect tool for creating local dev environments and simple application deployments.

To destroy the local playground, run the following command:

```bash
$ docker-compose down
```

Next: [Kubernetes](10-kubernetes.md)
