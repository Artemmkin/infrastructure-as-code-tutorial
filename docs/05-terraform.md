# Terraform

In the previous lab, you used Packer to make your system configuration faster and more reliable. But we still have a lot to improve.

In this lab, we're going to learn about another IaC tool by HashiCorp called [Terraform](https://www.terraform.io/).

## Intro

Think about your current operations...

Do you see any problems you may have, or any ways for improvement?

Remember, that each time we want to deploy an application, we have to `provision` compute resources first, that is to start a new VM.

We do it via a `gcloud` command like this:

```bash
$ gcloud compute instances create node-svc \
    --image-family node-svc-base \
    --boot-disk-size 10GB \
    --machine-type f1-micro
```

At this stage, it doesn't seem like there are any problems with this. But, in fact, there are.

Infrastructure for running your services and applications could be huge. You might have tens, hundreds or even thousands of virtual machines, hundreds of firewall rules, multiple VPC networks and load balancers. Additionally, the infrastructure could be split between multiple teams. Such infrastructure looks, and is, very complex and yet should be run and managed in a consistent and predictable way.

If we create and change infrastructure components using the Web User Interface (UI) Console or even the gcloud command ine interface (CLI) tool, over time we won't be able to describe exactly in which `state` our infrastructure is in right now, meaning `we lose control over it`.

This happens because you tend to forget what changes you've made a few months ago and why you made them. If multiple people across multiple teams are managing infrastructure, this makes things even worse.

So we see here 2 clear problems:

* we don't know the current state of our infrastructure
* we can't control the changes

The second problem is dealt by source control tools like `git`, while the first one is solved by using tools like Terraform. Let's find out how.

##  Terraform

Terraform is already installed on Google Cloud Shell. 

If you want to install it on a laptop or VM, you can [download here](https://www.terraform.io/downloads.html).

Make sure Terraform version is  => 0.11.0:

```bash
$ terraform -v
```

## Infrastructure as Code project

Create a new directory called `05-terraform` inside your `iac-tutorial` repo, which we'll use to save the work done in this lab.

## Describe VM instance

_Terraform allows you to describe the desired state of your infrastructure and makes sure your desired state meets the actual state._

Terraform uses [**resources**](https://www.terraform.io/docs/configuration/resources.html) to describe different infrastructure components. If you want to use Terraform to manage an infrastructure component, you should first make sure there is a resource for that component for that particular platform.

Let's use Terraform syntax to describe a VM instance that we want to be running.

Create a Terraform configuration file called `main.tf` inside the `05-terraform` directory with the following content:

```
resource "google_compute_instance" "node-svc" {
  name         = "node-svc"
  machine_type = "f1-micro"
  zone         = "us-central1-c"

  # boot disk specifications
  boot_disk {
    initialize_params {
      image = "node-svc-base" // use image built with Packer
    }
  }

  # networks to attach to the VM
  network_interface {
    network = "default"
    access_config {} // use ephemeral public IP
  }
}
```

Here we use [google_compute_instance](https://www.terraform.io/docs/providers/google/r/compute_instance.html) resource to manage a VM instance running in Google Cloud Platform.

## Define Resource Provider

One of the advantages of Terraform over other alternatives like [CloudFormation](https://aws.amazon.com/cloudformation/?nc1=h_ls) is that it's `cloud-agnostic`, meaning it can work with many different cloud providers like AWS, GCP, Azure, or OpenStack. It can also work with resources of different services like databases (e.g., PostgreSQL, MySQL), orchestrators (Kubernetes, Nomad) and [others](https://www.terraform.io/docs/providers/).

This means that Terraform has a pluggable architecture and the pluggable component that allows it to work with a specific platform or service is called **provider**.

So before we can actually create a VM using Terraform, we need to define a configuration of a [google cloud provider](https://www.terraform.io/docs/providers/google/index.html) and download it on our system.

Create another file inside `terraform` folder and call it `providers.tf`. Put provider configuration in it:

```
provider "google" {
  version = "~> 2.5.0"
  project = "YOU MUST PUT YOUR PROJECT NAME HERE"
  region  = "us-central1-c"
}
```

Make sure to change the `project` value in provider's configuration above to your project's ID. You can get your default project's ID by running the command:

```bash
$ gcloud config list project
```

Now run the `init` command inside `terraform` directory to download the provider:

```bash
$ terraform init
```

## Bring Infrastructure to a Desired State

Once we described a desired state of the infrastructure (in our case it's a running VM), let's use Terraform to bring the infrastructure to this state:

```bash
$ terraform apply
```

After Terraform ran successfully, use a gcloud command to verify that the machine was indeed launched:

```bash
$ gcloud compute instances describe node-svc
```

## Deploy Application

We did provisioning via Terraform, but we still need to install and start our application. Let's do this remotely this time, instead of logging into the machine:


```bash
$ INSTANCE_IP=$(gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe node-svc) # get IP of VM
$ scp -r install.sh node-user@${INSTANCE_IP}:/home/node-user # copy install script
$ rsh ${INSTANCE_IP} -l node-user chmod +x /home/node-user/install.sh # set permissions
$ rsh ${INSTANCE_IP} -l node-user /home/node-user/install.sh # install app
$ rsh ${INSTANCE_IP} -l node-user sudo nodejs /home/node-user/node-svc-v1/server.js & # run app
```

NOTE: If you get an offending ECDSA key error, use the suggested removal command.

NOTE: If you get the error `Permission denied (publickey).`, this probably means that your ssh-agent no longer has the node-user private key added. This easily happens if the Google Cloud Shell goes to sleep and wipes out your session. Check via issuing `ssh-add -l`. You should see something like `2048 SHA256:bII5VsQY3fCWXEai0lUeChEYPaagMXun3nB9U2eoUEM /home/betz4871/.ssh/node-user (RSA)`. If you do not, re-issue the command `ssh-add ~/.ssh/node-user` and re-confirm with `ssh-add -l`. 

Connect to the VM via SSH:

```bash
$ ssh node-user@${INSTANCE_IP}
```

Check that servce is running, and then exit:

```bash
node-user@node-svc:~$ curl localhost:3000
Successful request.
node-user@node-svc:~$ exit
```

## Access the Application Externally7

Manually create the firewall rule: 

```bash 
$ gcloud compute firewall-rules create allow-node-svc-tcp-3000 \
    --network default \
    --action allow \
    --direction ingress \
    --rules tcp:3000 \
    --source-ranges 0.0.0.0/0
```


Open another terminal and run the following command to get a public IP of the VM:

```bash
$ gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe node-svc
```

Access the application in your browser by its public IP (don't forget to specify the port 3000).


## Add other GCP resources into Terraform

Let's add ssh keys and the firewall rule into our Terraform configuration so that we know for sure those resources are present.

First, delete the SSH project key and firewall rule:

```bash
$ gcloud compute project-info remove-metadata --keys=ssh-keys
$ gcloud compute firewall-rules delete allow-node-svc-tcp-3000
```

Make sure that your application became inaccessible via port 3000 and SSH connection with a private key of `node-user` fails.

Then add appropriate resources into `main.tf` file. Your final version of `main.tf` file should look similar to this (change the ssh key file path, if necessary):


```bash
resource "google_compute_instance" "node-svc" {
  name         = "node-svc"
  machine_type = "f1-micro"
  zone         = "us-central1-c"

  # boot disk specifications
  boot_disk {
    initialize_params {
      image = "node-svc-base" // use image built with Packer
    }
  }

  # networks to attach to the VM
  network_interface {
    network = "default"
    access_config {} // use ephemaral public IP
  }
}

resource "google_compute_project_metadata" "node-svc" {
  metadata = {
    ssh-keys = "node-user:${file("~/.ssh/node-user.pub")}" // path to ssh key file
  }
}

resource "google_compute_firewall" "node-svc" {
  name    = "allow-node-svc-tcp-3000"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }
  source_ranges = ["0.0.0.0/0"]
}
```

Tell Terraform to apply the changes to bring the actual infrastructure state to the desired state we described:

```bash
$ terraform apply
```

Using the same techniques as above, verify that the application became accessible again on port 3000 (locally and remotely) and SSH connection with a private key works. Here's a new way to check it from the Google Cloud Shell (you don't ssh into the VM):

```bash
$ curl $INSTANCE_IP:3000
```

## Create an output variable

We have frequntly used this gcloud command to retrieve a public IP address of a VM:

```bash
$ gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe node-svc 
```

We can tell Terraform to provide us this information using [output variables](https://www.terraform.io/intro/getting-started/outputs.html).

Create another configuration file inside `terraform` directory and call it `outputs.tf`. Put the following content in it:

```json
output "node_svc_public_ip" {
  value = "${google_compute_instance.node-svc.network_interface.0.access_config.0.nat_ip}"
}
```

Run terraform apply again, this time with auto approve:

```bash
$ terraform apply -auto-approve

google_compute_instance.node-svc: Refreshing state... [id=node-svc]
google_compute_firewall.node-svc: Refreshing state... [id=allow-node-svc-tcp-3000]
google_compute_project_metadata.node-svc: Refreshing state... [id=proven-sum-252123]
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
Outputs:
node_svc_public_ip = 34.71.90.74
```

Couple of things to notice here.   First, we did not destroy anything, so terraform refreshes - it confirms that configurations are still as specified. During this Terraform run, no resources have been created or changed, which means that the actual state of our infrastructure already meets the requirements of a desired state. 

Secondly, under "Outputs:", you should see the public IP of the VM we created.

## Save and commit the work

Save and commit the `05-terraform` folder created in this lab into your `iac-tutorial` repo.

## Conclusion

In this lab, you saw a state of the art the application of Infrastructure as Code practice.

We used *code* (Terraform configuration syntax) to describe the *desired state* of the infrastructure. Then we told Terraform to bring the actual state of the infrastructure to the desired state we described.

With this approach, Terraform configuration becomes *a single source of truth* about the current state of your infrastructure. Moreover, the infrastructure is described as code, so we can apply to it the same practices we commonly use in development such as keeping the code in source control, use peer reviews for making changes, etc.

All of this helps us get control over even the most complex infrastructure.

Destroy the resources created by Terraform and move on to the next lab.

```bash
$ terraform destroy -auto-approve
```

Next: [Ansible](06-ansible.md)
