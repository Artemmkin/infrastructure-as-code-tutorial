## Kubernetes

In the previous labs, we learned how to run Docker containers locally. Running containers at scale is quite different and a special class of tools, known as **orchestrators**, is used for that task.

In this lab, we'll take a look at the most popular Open Source orchestration platform called [Kubernets](https://kubernetes.io/) and see how it implements Infrastructure as Code model.

## Intro

We used Docker Compose to consistently create container infrastructure on one machine (our local machine). However, our production environment may include tens or hundreds of VMs to have enough capacity to provide service to a large number of users. What do you do in that case?

Running Docker Compose on each VM from the cluster seems like a lot of work. Besides, if you want your containers running on different hosts to communicate with each other it requires creation of a special type of network called `overlay`, which you can't create using only Docker Compose.

Moreover, questions arise as to:
* how to load balance containerized applications?
* how to perform container health checks and ensure the required number of containers is running?

The world of containers is very different from the world of virtual machines and needs a special platform for management.

Kubernetes is the most widely used orchestration platform for running and managing containers at scale. It solves the common problems (some of which we've mentioned above) related to running containers on multiple hosts. And we'll see in this lab that it uses the Infrastructure as Code approach to managing container infrastructure.

Let's try to run our `raddit` application on a Kubernetes cluster.

## Install Kubectl

[Kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) is command line tool that we will use to run commands against the Kubernetes cluster.

You can install `kubectl` onto your system as part of Google Cloud SDK by running the following command:

```bash
$ gcloud components install kubectl
```

Check the version of kubectl to make sure it is installed:

```bash
$ kubectl version
```

## Infrastructure as Code project

Create a new directory called `kubernetes` inside your `iac-tutorial` repo, which we'll use to save the work done in this lab.

## Describe Kubernetes cluster in Terraform

We'll use [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) (GKE) service to deploy a Kubernetes cluster of 2 nodes.

We'll describe a Kubernetes cluster using Terraform so that we can manage it through code.

Create a directory named `terraform` inside `kubernetes` directory. Download a bundle of Terraform configuration files into the created `terraform` directory.

```bash
$ wget https://github.com/Artemmkin/gke-terraform/raw/master/gke-terraform.zip
$ unzip gke-terraform.zip -d kubernetes/terraform
$ rm gke-terraform.zip
```

We'll use this Terraform code to create a Kubernetes cluster.

## Create Kubernetes Cluster

`main.tf` which you downloaded holds all the information about the cluster that should be created. It's parameterized using Terraform [input variables](https://www.terraform.io/intro/getting-started/variables.html) which allow you to easily change configuration parameters.

Look into `terraform.tfvars` file which contains definitions of the input variables and change them if necessary. You'll most probably want to change `project_id` value.

```
// define provider configuration variables
project_id = "infrastructure-as-code"         # project in which to create a cluster
region = "europe-west1"                       # region in which to create a cluster

// define Kubernetes cluster variables
cluster_name = "iac-tutorial-cluster"        # cluster name
zone = "europe-west1-b"                      # zone in which to create a cluster nodes
```
After you've defined the variables, run Terraform inside `kubernetes/terraform` to create a Kubernetes cluster consisting of 2 nodes (VMs for running our application containers).

```bash
$ gcloud services enable container.googleapis.com # enable Kubernetes Engine API
$ terraform init
$ terraform apply
```

Wait until Terraform finishes creation of the cluster. It can take about 3-5 minutes.

Check that the cluster is running and `kubectl` is properly configured to communicate with it by fetching cluster information:

```bash
$ kubectl cluster-info

Kubernetes master is running at https://35.200.56.100
GLBCDefaultBackend is running at https://35.200.56.100/api/v1/namespaces/kube-system/services/default-http-backend/proxy
...
```

## Deployment manifest

Kubernetes implements Infrastructure as Code approach to managing container infrastructure. It uses special entities called **objects** to represent the `desired state` of your cluster. With objects you can describe

* What containerized applications are running (and on which nodes)
* The compute resources available to those applications
* The policies around how those applications behave, such as restart policies, upgrades, and fault-tolerance

By creating an object, you’re effectively telling the Kubernetes system what you want your cluster’s workload to look like; this is your cluster’s `desired state`. Kubernetes then makes sure that the cluster's actual state meets the desired state described in the object.

Most of the times, you describe the object in a `.yaml` file called `manifest` and then give it to `kubectl` which in turn is responsible for relaying that information to Kubernetes via its API.

**Deployment object** represents an application running on your cluster. We'll use it to run containers of our applications.

Create a directory called `manifests` inside `kubernetes` directory. Create a `deployments.yaml` file inside it with the following content:

```yaml
apiVersion: apps/v1beta1 # implies the use of kubernetes 1.7
                         # use apps/v1beta2 for kubernetes 1.8
kind: Deployment
metadata:
  name: raddit-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: raddit
  template:
    metadata:
      labels:
        app: raddit
    spec:
      containers:
      - name: raddit
        image: artemkin/raddit
        env:
        - name: DATABASE_HOST
          value: mongo-service
---
apiVersion: apps/v1beta1 # implies the use of kubernetes 1.7
                         # use apps/v1beta2 for kubernetes 1.8
kind: Deployment
metadata:
  name: mongo-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
      - name: mongo
        image: mongo:3.2
```

In this file we describe two `Deployment objects` which define what application containers and in what quantity should be run. The Deployment objects have the same structure so I'll briefly go over only one of them.

Each Kubernetes object has 4 required fields:
* `apiVersion` - Which version of the Kubernetes API you’re using to create this object. You'll need to change that if you're using Kubernetes API version different than 1.7 as in this example.
* `kind` - What kind of object you want to create. In this case we create a Deployment object.
* `metadata` - Data that helps uniquely identify the object. In this example, we give the deployment object a name according to the name of an application it's used to run.
* `spec` - describes the `desired state` for the object. `Spec` configuration will differ from object to object, because different objects are used for different purposes.

In the Deployment object's spec we specify, how many `replicas` (instances of the same application) we want to run and what those applications are (`selector`)

```yml
spec:
  replicas: 2
  selector:
    matchLabels:
      app: raddit
```

In our case, we specify that we want to be running 2 instances of applications that have a label `app=raddit`. **Labels** are used to give identifying attributes to Kubernetes objects and can be then used by **label selectors** for objects selection.

We also specify a `Pod template` in the spec configuration. **Pods** are lower level objects than Deployments and are used to run only `a single instance of application`. In most cases, Pod is equal to a container, although you can run multiple containers in a single Pod.

The `Pod template` which we use is a Pod object's definition nested inside the Deployment object. It has the required object fields such as `metadata` and `spec`, but it doesn't have `apiVersion` and `kind` fields as those would be redundant in this case. When we create a Deployment object, the Pod object(s) will be created as well. The number of Pods will be equal to the number of `replicas` specified. The Deployment object ensures that the right number of Pods (`replicas`) is always running.

In the Pod object definition (`Pod template`) we specify container information such as a container image name, a container name, which is used by Kubernetes to run the application. We also add labels to identify what application this Pod object is used to run, this label value is then used by the `selector` field in the Deployment object to select the right Pod object.

```yaml
  template:
    metadata:
      labels:
        app: raddit
    spec:
      containers:
      - name: raddit
        image: artemkin/raddit
        env:
        - name: DATABASE_HOST
          value: mongo-service
```

Notice how we also pass an environment variable to the container. `DATABASE_HOST` variable tells our application how to contact the database. We define `mongo-service` as its value to specify the name of the Kubernetes service to contact (more about the Services will be in the next section).

Container images will be downloaded from Docker Hub in this case.

## Create Deployment Objects

Run a kubectl command to create Deployment objects inside your Kubernetes cluster (make sure to provide the correct path to the manifest file):

```bash
$ kubectl apply -f manifests/deployments.yaml
```

Check the deployments and pods that have been created:

```bash
$ kubectl get deploy
$ kubectl get pods
```

## Service manifests

Running applications at scale means running _multiple containers spread across multiple VMs_.

This arises questions such as: How do we load balance between all of these application containers? How do we provide a single entry point for the application so that we could connect to it via that entry point instead of connecting to a particular container?

These questions are addressed by the **Service** object in Kubernetes. A Service is an abstraction which you can use to logically group containers (Pods) running in you cluster, that all provide the same functionality.

When a Service object is created, it is assigned a unique IP address called `clusterIP` (a single entry point for our application). Other Pods can then be configured to talk to the Service, and the Service will load balance the requests to containers (Pods) that are members of that Service.

We'll create a Service for each of our applications, i.e. `raddit` and `MondoDB`. Create a file called `services.yaml` inside `kubernetes/manifests` directory with the following content:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: raddit-service
spec:
  type: NodePort
  selector:
    app: raddit
  ports:
  - protocol: TCP
    port: 9292
    targetPort: 9292
    nodePort: 30100
---
apiVersion: v1
kind: Service
metadata:
  name: mongo-service
spec:
  type: ClusterIP
  selector:
    app: mongo
  ports:
  - protocol: TCP
    port: 27017
    targetPort: 27017
```

In this manifest, we describe 2 Service objects of different types. You should be already familiar with the general object structure, so I'll just go over the `spec` field which defines the desired state of the object.

The `raddit` Service has a NodePort type:

```yaml
spec:
  type: NodePort
```

This type of Service makes the Service accessible on each Node’s IP at a static port (NodePort). We use this type to be able to contact the `raddit` application later from outside the cluster.

`selector` field is used to identify a set of Pods to which to route packets that the Service receives. In this case, Pods that have a label `app=raddit` will become part of this Service.

```yaml
  selector:
    app: raddit
```

The `ports` section specifies the port mapping between a Service and Pods that are part of this Service and also contains definition of a node port number (`nodePort`) which we will use to reach the Service from outside the cluster.

```yaml
  ports:
  - protocol: TCP
    port: 9292
    targetPort: 9292
    nodePort: 30100
```

The requests that come to any of your cluster nodes' public IP addresses on the specified `nodePort` will be routed to the `raddit` Service cluster-internal IP address. The Service, which is listening on port 9292 (`port`) and is accessible within the cluster on this port, will then route the packets to the `targetPort` on one of the Pods which is part of this Service.

`mongo` Service is only different in its type. `ClusterIP` type of Service will make the Service accessible on the cluster-internal IP, so you won't be able to reach it from outside the cluster.

## Create Service Objects

Run a kubectl command to create Service objects inside your Kubernetes cluster (make sure to provide the correct path to the manifest file):

```bash
$ kubectl apply -f manifests/services.yaml
```

Check that the services have been created:

```bash
$ kubectl get svc
```

## Access Application

Because we used `NodePort` type of service for the `raddit` service, our application should accessible to us on the IP address of any of our cluster nodes.

Get a list of IP addresses of your cluster nodes:

```bash
$ gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances list --filter="tags.items=iac-kubernetes"
```

Use any of your nodes public IP addresses and the node port `30100` which we specified in the service object definition to reach the `raddit` application in your browser.

## Save and commit the work

Save and commit the `kubernetes` folder created in this lab into your `iac-tutorial` repo.

## Conclusion

In this lab, we learned about Kuberenetes - a popular orchestration platform which simplifies the process of running containers at scale. We saw how it implements the Infrastructure as Code approach in the form of `objects` and `manifests` which allow you to describe in code the desired state of your container infrastructure which spans a cluster of VMs.

To destroy the Kubernetes cluster, run the following command inside `kubernetes/terraform` directory:

```bash
$ terraform destroy
```

Next: [What is Infrastructure as Code](50-what-is-iac.md)
