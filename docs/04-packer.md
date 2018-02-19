# Packer

Scripts helped us speed up the process of system configuration, and made it more reliable compared to doing everything manually, but there are still ways for improvement.

In this lab, we're going to take a look at the first IaC tool in this tutorial called [Packer](https://www.packer.io/) and see how it can help us improve our operations.

## Intro

Remember how in the second lab we had to make sure that the `git` was installed on the VM so that we could clone the application repo? Did it surprise you in a good way that the `git` was already installed on the system and we could skip the installation?

Imagine how nice it would be to have other required packages like Ruby and Bundler preinstalled on the VM we provision, or have necessary configuration files come with the image, too. This would require even less time and effort from us to configure the system and run our application.

Luckily, we can create custom machine images with required configuration and software installed using Packer. Let's check it out.

## Install Packer

[Download](https://www.packer.io/downloads.html) and install Packer onto your system.

Check the version to verify that it was installed:

```bash
$ packer -v
```

## Infrastructure as Code project

Create a new directory called `packer` inside your `iac-tutorial` repo, which we'll use to save the work done in this lab.

## Define image builder

The way Packer works is simple. It starts a VM with specified characteristics, configures the operating system and installs the software you specify, and then it creates a machine image from that VM.

The part of packer responsible for staring a VM and creating an image from it is called [builder](https://www.packer.io/docs/builders/index.html).

So before using packer to create images, we need to define a builder configuration in a JSON file (which is called **template** in Packer terminology).

Create a `raddit-base-image.json` file inside the `packer` directory with the following content (make sure to change the project ID and zone in case it's different):

```json
{
  "builders": [
    {
      "type": "googlecompute",
      "project_id": "infrastructure-as-code",
      "zone": "europe-west1-b",
      "machine_type": "g1-small",
      "source_image_family": "ubuntu-1604-lts",
      "image_name": "raddit-base-{{isotime `20060102-150405`}}",
      "image_family": "raddit-base",
      "image_description": "Ubuntu 16.04 with Ruby, Bundler and MongoDB preinstalled",
      "ssh_username": "raddit-user"
    }
  ]
}
```

This template describes where and what type of a VM to launch for image creation (`type`, `project_id`, `zone`, `machine_type`, `source_image_family`). It also defines image saving configuration such as under which name (`image_name`) and image family (`image_family`) the resulting image should be saved and what description to give it (`image_description`). SSH user configuration is used by provisioners which will talk about later.

Validate the template:

```bash
$ packer validate ./packer/raddit-base-image.json
```

## Define image provisioner

As we already mentioned, builders are only responsible for starting a VM and creating an image from that VM. The real work of system configuration and installing software on the running VM is done by another Packer component called **provisioner**.

Add a [shell provisioner](https://www.packer.io/docs/provisioners/shell.html) to your template to run the `configuration.sh` script you created in the previous lab.

Your template should look similar to this one:

```json
{
  "builders": [
    {
      "type": "googlecompute",
      "project_id": "infrastructure-as-code",
      "zone": "europe-west1-b",
      "machine_type": "g1-small",
      "source_image_family": "ubuntu-1604-lts",
      "image_name": "raddit-base-{{isotime `20060102-150405`}}",
      "image_family": "raddit-base",
      "image_description": "Ubuntu 16.04 with Ruby, Bundler and MongoDB preinstalled",
      "ssh_username": "raddit-user"
    }
  ],
  "provisioners": [
      {
          "type": "shell",
          "script": "{{template_dir}}/../scripts/configuration.sh",
          "execute_command": "sudo {{.Path}}"
      }
  ]
}
```

Make sure the template is valid:

```bash
$ packer validate ./packer/raddit-base-image.json
```

## Create custom machine image

Build the image for your application:

```bash
$ packer build ./packer/raddit-base-image.json
```

## Launch a VM with your custom built machine image

Once the image is built, use it as a boot disk to start a VM:

```bash
$ gcloud compute instances create raddit-instance-4 \
    --image-family raddit-base \
    --boot-disk-size 10GB \
    --machine-type n1-standard-1
```

## Deploy Application

Copy `deploy.sh` script to the created VM:

```bash
$ INSTANCE_IP=$(gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe raddit-instance-4)
$ scp ./scripts/deploy.sh raddit-user@${INSTANCE_IP}:/home/raddit-user
```

Connect to the VM via SSH:

```bash
$ ssh raddit-user@${INSTANCE_IP}
```

Verify Ruby, Bundler and MongoDB are installed:

```bash
$ ruby -v
$ bundle version
$ sudo systemctl status mongod
```

Run deployment script:

```bash
$ chmod +x ./deploy.sh
$ ./deploy.sh
```

## Access Application

Access the application in your browser by its public IP (don't forget to specify the port 9292).

Open another terminal and run the following command to get a public IP of the VM:

```bash
$ gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe raddit-instance-4
```

## Save and commit the work

Save and commit the packer template created in this lab into your `iac-tutorial` repo.

## Learning more about Packer

Packer configuration files are called templates for a reason. They often get parameterized with [user variables](https://www.packer.io/docs/templates/user-variables.html). This could be very helpful since you can create multiple machine images with different configuration and for different purposes using one template file.

Adding user variables to a template is easy, follow the [documentation](https://www.packer.io/docs/templates/user-variables.html) on how to do that.

## Immutable infrastructure

You may wonder why not to put everything inside the image including the application? Well, this approach is called an [immutable infrastructure](https://martinfowler.com/bliki/ImmutableServer.html). It is based on the idea `we build it once, and we never change it`.

It has advantages of spending less time (zero in this case) on system configuration after VM's start, and prevents **configuration drift**, but it's also not easy to implement.

## Conclusion

In this lab you've used Packer to create a custom machine image for running your application.

The advantages of its usage are quite obvious:

* `It requires less time and effort to configure a new VM for running the application`
* `System configuration becomes more reliable.` When we start a new VM to deploy the application, we know for sure that it has the right packages installed and configured properly, since we built and tested the image.

Destroy the current VM and move onto the next lab:

```bash
$ gcloud compute instances delete raddit-instance-4
```

Next: [Terraform](05-terraform.md)
