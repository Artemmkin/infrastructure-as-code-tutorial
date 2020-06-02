# Terraform

In the previous lab, you used Packer to make your system configuration faster and more reliable. But we still have a lot to improve.

In this lab, we're going to learn about another IaC tool by HashiCorp called [Terraform](https://www.terraform.io/).

## Intro

Think about your current operations...

Do you see any problems you may have, or any ways for improvement?

Remember, that each time we want to deploy an application, we have to `provision` compute resources first, that is to start a new VM.

We do it via a `gcloud` command like this:

```bash
$ gcloud compute instances create raddit-instance-4 \
    --image-family raddit-base \
    --boot-disk-size 10GB \
    --machine-type n1-standard-1
```

At this stage, it doesn't seem like there are any problems with this. But, in fact, there is.

Infrastructure for running your services and applications could be huge. You might have tens, hundreds or even thousands of virtual machines, hundreds of firewall rules, multiples VPC networks, and load balancers. In addition to that, the infrastructure could be split between multiple teams and managed separately. Such infrastructure looks very complex and yet should be run and managed in a consistent and predictable way.

If we create and change infrastructure components using gcloud CLI tool or Web UI Console, over time we won't be able to describe exactly in which `state` our infrastructure is in right now, meaning `we lose control over it`.

This happens because you tend to forget what changes you've made a few months ago and why you did it. If multiple people are managing infrastructure, this makes things even worse, because you can't know what changes other people are making even though your communication inside the team could be great.

So we see here 2 clear problems:

* we don't know the current state of our infrastructure
* we can't control the changes

The second problem is dealt by source control tools like `git`, while the first one is solved by using tools like Terraform. Let's find out how.

## Install Terraform

[Download](https://www.terraform.io/downloads.html) and install Terraform on your system.

Make sure Terraform version is  => 0.11.0:

```bash
$ terraform -v
```

## Infrastructure as Code project

Create a new directory called `terraform` inside your `iac-tutorial` repo, which we'll use to save the work done in this lab.

## Describe VM instance

_Terraform allows you to describe the desired state of your infrastructure and makes sure your desired state meets the actual state._

Terraform uses **resources** to describe different infrastructure components. If you want to use Terraform to manage some infrastructure component, you should first make sure there is a resource for that component for that particular platform.

Let's use Terraform syntax to describe a VM instance that we want to be running.

Create a Terraform configuration file called `main.tf` inside the `terraform` directory with the following content:

```
resource "google_compute_instance" "raddit" {
  name         = "raddit-instance"
  machine_type = "n1-standard-1"
  zone         = "europe-west1-b"

  # boot disk specifications
  boot_disk {
    initialize_params {
      image = "raddit-base" // use image built with Packer
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
  version = "~> 1.4.0"
  project = "infrastructure-as-code"
  region  = "europe-west1"
}
```

Note the `region` value, this is where terraform will provision resources (you may wish to change it).

Make sure to change the `project` value in provider's configuration above to your project's ID. You can get your default project's ID by running the command:

```bash
$ gcloud config list project
```

Now run the `init` command inside `terraform` directory to download the provider:

```bash
$ cd ./terraform
$ terraform init
```

## Bring Infrastructure to a Desired State

Once we described a desired state of the infrastructure (in our case it's a running VM), let's use Terraform to bring the infrastructure to this state:

```bash
$ terraform apply
```

After Terraform ran successfully, use a gcloud command to verify that the machine was indeed launched:

```bash
$ gcloud compute instances describe raddit-instance
```

## Deploy Application

We did provisioning via Terraform, but we still need to run a script to deploy our application.

Copy `deploy.sh` script to the created VM:

```bash
$ INSTANCE_IP=$(gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe raddit-instance)
$ scp ../scripts/deploy.sh raddit-user@${INSTANCE_IP}:/home/raddit-user
```

Connect to the VM via SSH:

```bash
$ ssh raddit-user@${INSTANCE_IP}
```

Run deployment script:

```bash
$ chmod +x ./deploy.sh
$ ./deploy.sh
```

## Access the Application

Access the application in your browser by its public IP (don't forget to specify the port 9292).

Open another terminal and run the following command to get a public IP of the VM:

```bash
$ gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe raddit-instance
```

## Add other GCP resources into Terraform

Do you remember how in previous labs we created some GCP resources like SSH project keys and a firewall rule for our application via `gcloud` tool?

Let's add those into our Terraform configuration so that we know for sure those resources are present.

First, delete the SSH project key and firewall rule:

```bash
$ gcloud compute project-info remove-metadata --keys=ssh-keys
$ gcloud compute firewall-rules delete allow-raddit-tcp-9292
```

Make sure that your application became inaccessible via port 9292 and SSH connection with a private key of `raddit-user` fails.

Then add appropriate resources into `main.tf` file. Your final version of `main.tf` file should look similar to this (change the ssh key file path, if necessary):

```
resource "google_compute_instance" "raddit" {
  name         = "raddit-instance"
  machine_type = "n1-standard-1"
  zone         = "europe-west1-b"

  # boot disk specifications
  boot_disk {
    initialize_params {
      image = "raddit-base" // use image built with Packer
    }
  }

  # networks to attach to the VM
  network_interface {
    network = "default"
    access_config {} // use ephemaral public IP
  }
}

resource "google_compute_project_metadata" "raddit" {
  metadata = {
    ssh-keys = "raddit-user:${file("~/.ssh/raddit-user.pub")}" // path to ssh key file
  }
}

resource "google_compute_firewall" "raddit" {
  name    = "allow-raddit-tcp-9292"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }
  source_ranges = ["0.0.0.0/0"]
}
```

Tell Terraform to apply the changes to bring the actual infrastructure state to the desired state we described:

```bash
$ terraform apply
```

Verify that the application became accessible again on port 9292 and SSH connection with a private key works.

## Create an output variable

Remember how we often had to use a gcloud command like this to retrive a public IP address of a VM?

```bash
$ gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe raddit-instance
```

We can tell Terraform to provide us this information using [output variables](https://www.terraform.io/intro/getting-started/outputs.html).

Create another configuration file inside `terraform` directory and call it `outputs.tf`. Put the following content in it:

```
output "raddit_public_ip" {
  value = "${google_compute_instance.raddit.network_interface.0.access_config.0.nat_ip}"
}
```

Run terraform apply again:

```bash
$ terraform apply
```

You should see the public IP of the VM we created.

Also note, that during this Terraform run, no resources have been created or changed, which means that the actual state of our infrastructure already meets the requirements of a desired state.

## Save and commit the work

Save and commit the `terraform` folder created in this lab into your `iac-tutorial` repo.

## Conclusion

In this lab, you saw in its most obvious way the application of Infrastructure as Code practice.

We used `code` (Terraform configuration syntax) to describe the `desired state` of the infrastructure. Then we told Terraform to bring the actual state of the infrastructure to the desired state we described.

With this approach, Terraform configuration becomes `a single source of truth` about the current state of your infrastructure. Moreover, the infrastructure is described as code, so we can apply to it the same practices we commonly use in development such as keeping the code in source control, use peer reviews for making changes, etc.

All of this helps us get control over even the most complex infrastructure.

Destroy the resources created by Terraform and move on to the next lab.

```bash
$ terraform destroy
```

Next: [Ansible](06-ansible.md)
