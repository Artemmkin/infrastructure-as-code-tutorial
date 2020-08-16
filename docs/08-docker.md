## Docker

In this lab, we will talk about managing containers for the first time in this tutorial. Particularly, we will talk about [Docker](https://www.docker.com/what-docker) which is the most widely used platform for running containers.

## Intro

Remember when we talked about packer, we mentioned a few words about `Immutable Infrastructure` model? The idea was to package all application dependencies and application itself inside a machine image, so that we don't have to configure the system after start. Containers implement the same model, but they do it in a more efficient way.

Containers allow you to create self-contained isolated environments for running your applications.

They have some significant advantages over VMs in terms of implementing Immutable Infrastructure model:

* `Containers are much faster to start than VMs.` Container starts in seconds, while a VM takes minutes. It's important when you're doing an update/rollback or scaling your service.
* `Containers enable better utilization of compute resources.` Very often computer resources of a VM running an application are underutilized. Launching multiple instances of the same application on one VM has a lot of difficulties: different application versions may need different versions of dependent libraries, init scripts require special configuration. With containers, running multiple instances of the same application on the same machine is easy and doesn't require any system configuration.
* `Containers are more lightweight than VMs.` Container images are much smaller than machine images, because they don't need a full operating system in order to run. In fact, a container image can include just a single binary and take just a few MBs of your disk space. This means that we need less space for storing the images and the process of distributing images goes faster.

Let's try to implement `Immutable Infrastructure` model with Docker containers, while paying special attention to the `Dockerfile` part as a way to practice `Infrastructure as Code` approach.

## (FOR PERSONAL LAPTOPS AND WORKSTATIONS ONLY) Install Docker Engine

_Docker is already installed on Google Cloud Shell._

The [Docker Engine](https://docs.docker.com/engine/docker-overview/#docker-engine) is the daemon that gets installed on the system and allows you to manage containers with simple CLI.

[Install](https://www.docker.com/community-edition) free Community Edition of Docker Engine on your system.

Verify that the version of Docker Engine is => 17.09.0:

```bash
$ docker -v
```

## (FOR ALL) Create Dockerfile

You describe a container image that you want to create in a special file called **Dockerfile**.

Dockerfile contains `instructions` on how the image should be built. Here are some of the most common instructions that you can meet in a Dockerfile:

* `FROM` is used to specify a `base image` for this build. It's similar to the builder configuration which we defined in a Packer template, but in this case instead of describing characteristics of a VM, we simply specify a name of a container image used for build. This should be the first instruction in the Dockerfile.
* `ADD` and `COPY` are used to copy a file/directory to the container. See the [difference](https://stackoverflow.com/questions/24958140/what-is-the-difference-between-the-copy-and-add-commands-in-a-dockerfile) between the two.
* `RUN` is used to run a command inside the image. Mostly used for installing packages.
* `ENV` sets an environment variable available within the container.
* `WORKDIR` changes the working directory of the container to a specified path. It basically works like a `cd` command on Linux.
* `CMD` sets a default command, which will be executed when a container starts. This should be a command to start your application.

Let's use these instructions to create a Docker container image for our node-svc application.

Inside your `my-iac-tutorial` directory, create a directory called `08-docker`, and in it a text file called `Dockerfile` with the following content:

```
FROM node:11
# Create app directory
WORKDIR /app
# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json ./
RUN npm install
RUN npm install express
# If you are building your code for production
# RUN npm ci --only=production
# Bundle app source
COPY . /app
EXPOSE 3000
CMD [ "node", "server.js" ]
```

This Dockerfile repeats the steps that we did multiple times by now to configure a running environment for our application and run it.

We first choose an image that already contains Node of required version:
```
# Use base image with node installed
FROM node:11
```

The base image is downloaded from Docker official registry (storage of images) called [Docker Hub](https://hub.docker.com/).

We then install required system packages and application dependencies:

```
# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)COPY package*.json ./
RUN npm install
RUN npm install express
```

Then we copy the application itself. 

```
# create application home directory and copy files
COPY . /app
```

Then we specify a default command that should be run when a container from this image starts:

```
CMD [ "node", "server.js" ]
```

## Build Container Image

Once you defined how your image should be built, run the following command inside your `my-iac-tutorial` directory to create a container image for the node-svc application:

```bash
$ docker build -t <yourGoogleID>/node-svc-v1 .
```

The resulting image will be named `node-svc`. Find it in the list of your local images:

```bash
$ docker images | grep node-svc
```
At your option, you can save your build command in a script, such as `build.sh`.

Now, run the container: 

```bash
$ docker run -d -p 8081:3000 <yourGoogleID>/node-svc-v1
```

Notice the "8081:3000" syntax. This means that while the container is running on port 3000 internally, it is externally exposed via port 8081. 

Again, you may wish to save this in a script, such as `run.sh`.

Now, test the container: 

```bash
$ curl localhost:8081
Successful request.
```

Again, you may wish to save this in a script, such as `test.sh`.

## Save and commit the work

Save and commit the files created in this lab.

## Conclusion

In this lab, you adopted containers for running your application. This is a different type of technology from what we used to deal with in the previous labs. Nevertheless, we use Infrastructure as Code approach here, too.

We describe the configuration of our container image in a Dockerfile using Dockerfile's syntax. We then save that Dockefile in our application repository. This way we can build the application image consistently across any environments.

Destroy the current playground before moving on to the next lab, through `docker ps`, `docker kill`, `docker images`, and `docker rmi`. In the example below, the container is named "beautiful_pascal". Yours will be different. Follow the example, substituting yours. 

```bash
$ docker ps
CONTAINER ID        IMAGE                      COMMAND                  CREATED             STATUS              PORTS                    NAMES
64e60b7b0c81        charlestbetz/node-svc-v1   "docker-entrypoint.s…"   10 minutes ago      Up 10 minutes       0.0.0.0:8081->3000/tcp   beautiful_pascal
$ docker kill beautiful_pascal 
$ docker images
# returns list of your images
$ docker rmi <one or more image names> -f
```

Next: [Docker Compose](09-docker-compose.md)
