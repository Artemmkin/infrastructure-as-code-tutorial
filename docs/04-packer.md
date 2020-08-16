# Packer

Scripts helped us speed up the process of system configuration, and made it more reliable compared to doing everything manually, but there are still ways for improvement.

In this lab, we're going to take a look at the first IaC tool in this tutorial called [Packer](https://www.packer.io/) and see how it can help us improve our operations.

## Intro

Remember how in the second lab we had to make install nodejs, npm, and even git on the VM so that we could clone the application repo? Did it surprise you that `git` was not already installed on the system?

Imagine how nice it would be to have required packages like nodejs and npm preinstalled on the VM we provision, or have necessary configuration files come with the image, too. This would require even less time and effort from us to configure the system and run our application.

Luckily, we can create custom machine images with required configuration and software installed using Packer, an IaC tool by Hashicorp. Let's check it out.

## Install Packer

[Download](https://www.packer.io/downloads.html) and install Packer onto your system (this means the Google Cloud Shell). You will need to figure this out. 

If you have issues, consult [this script](https://github.com/dm-academy/iac-tutorial-rsrc/blob/master/packer/install-packer.sh). 

Check the version to verify that it was installed:

```bash
$ packer -v
```

## Infrastructure as Code project

Create a new directory called `04-packer` inside your `iac-tutorial` repo, which we'll use to save the work done in this lab.

## Define image builder

The way Packer works is simple. It starts a VM with specified characteristics, configures the operating system and installs the software you specify, and then it creates a machine image from that VM.

The part of packer responsible for starting a VM and creating an image from it is called [builder](https://www.packer.io/docs/builders/index.html).

So before using packer to create images, we need to define a builder configuration in a JSON file (which is called **template** in Packer terminology).

Create a `node-svc-base-image.json` file inside the `packer` directory with the following content (make sure to change the project ID, and also the zone in case it's different):

```json
{
  "builders": [
    {
      "type": "googlecompute",
      "project_id": "YOUR PROJECT HERE. YOU MUST CHANGE THIS",
      "zone": "us-central1-c",
      "machine_type": "f1-micro",
      "source_image_family": "ubuntu-minimal-2004-lts",
      "image_name": "node-svc-base-{{isotime \"2006-01-02 03:04:05\"}}",
      "image_family": "node-svc-base",
      "image_description": "Ubuntu 16.04 with git, nodejs, npm preinstalled",
      "ssh_username": "node-user"
    }
  ]
}
```

This template describes where and what type of a VM to launch for image creation (`type`, `project_id`, `zone`, `machine_type`, `source_image_family`). It also defines image saving configuration such as under which name (`image_name`) and image family (`image_family`) the resulting image should be saved and what description to give it (`image_description`). SSH user configuration is used by provisioners which will talk about later.

Validate the template:

```bash
$ packer validate node-svc-base-image.json
```

## Define image provisioner

As we already mentioned, builders are only responsible for starting a VM and creating an image from that VM. The real work of system configuration and installing software on the running VM is done by another Packer component called **provisioner**.

Add a [shell provisioner](https://www.packer.io/docs/provisioners/shell.html) to your template to run the `deploy.sh` script you created in the previous lab.

Your template should look similar to this one:

```json
{
  "builders": [
    {
      "type": "googlecompute",
      "project_id": "YOUR PROJECT HERE. YOU MUST CHANGE THIS",
      "zone": "us-central1-c",
      "machine_type": "f1-micro",
      "source_image_family": "ubuntu-1604-lts",
      "image_name": "node-svc-base-{{isotime `20200901-000001`}}",
      "image_family": "node-svc-base",
      "image_description": "Ubuntu 16.04 with git, nodejs, npm, and node-svc preinstalled",
      "ssh_username": "node-user"
    }
  ],
  "provisioners": [
      {
          "type": "shell",
          "script": "{{template_dir}}/../03-script/config.sh",
          "execute_command": "sudo {{.Path}}"
      }
  ]
}
```

Make sure the template is valid:

```bash
$ packer validate ./packer/node-base-image.json
```

## Create custom machine image

Build the image for your application:

```bash
$ packer build node-svc-base-image.json
```

If you go to the [Compute Engine Images](https://console.cloud.google.com/compute/images) page you should see your new custom image. 

## Launch a VM with your custom built machine image

Once the image is built, use it as a boot disk to start a VM:

```bash
$ gcloud compute instances create node-svc \
    --image-family node-svc-base \
    --boot-disk-size 10GB \
    --machine-type f1-micro
```

## Deploy Application

Copy the installation script to the VM:

$ INSTANCE_IP=$(gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe node-svc)
$ scp -r ../03-script/install.sh node-user@${INSTANCE_IP}:/home/node-user

Connect to the VM via SSH:

```bash
$ ssh node-user@${INSTANCE_IP}
```

NOTE: If you get an offending ECDSA key error, use the suggested removal command.

NOTE: If you get the error `Permission denied (publickey).`, this probably means that your ssh-agent no longer has the node-user private key added. This easily happens if the Google Cloud Shell goes to sleep and wipes out your session. Check via issuing `ssh-add -l`. You should see something like `2048 SHA256:bII5VsQY3fCWXEai0lUeChEYPaagMXun3nB9U2eoUEM /home/betz4871/.ssh/node-user (RSA)`. If you do not, re-issue the command `ssh-add ~/.ssh/node-user` and re-confirm with `ssh-add -l`. 

Verify git, nodejs, and npmare installed. Do you understand how they got there? (Your results may be slightly different, but if you get errors, investigate or ask for help):

```bash
node-user@node-svc:~$ npm -v
6.14.4
node-user@node-svc:~$ node -v
v10.19.0
node-user@node-svc:~$ git --version
git version 2.25.1
```


Run the installation script, and then the server:

```bash
$ chmod +x *.sh
$ sudo ./install.sh 
$ sudo nodejs node-svc-v1/server.js &
```

## Access Application

Manually re-create the firewall rule: 

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

## De-provision
```bash
$ ../03-script/deprovision.sh  #notice path
``` 

## Save and commit the work

Save and commit the packer template created in this lab into your `iac-tutorial` repo.

## Learning more about Packer

Packer configuration files are called templates for a reason. They often get parameterized with [user variables](https://www.packer.io/docs/templates/user-variables.html). This could be very helpful since you can create multiple machine images with different configurations for different purposes using one template file.

Adding user variables to a template is easy, follow the [documentation](https://www.packer.io/docs/templates/user-variables.html) on how to do that.

## Immutable infrastructure

By putting everything inside the image including the application, we have achieved an [immutable infrastructure](https://martinfowler.com/bliki/ImmutableServer.html). It is based on the idea `we build it once, and we never change it`.

It has advantages of spending less time (zero in this case) on system configuration after VM's start, and prevents **configuration drift**, but it's also not easy to implement.

## Conclusion

In this lab you've used Packer to create a custom machine image for running your application.

Its advantages include:

* `It requires less time and effort to configure a new VM for running the application`
* `System configuration becomes more reliable.` When we start a new VM to deploy the application, we know for sure that it has the right packages installed and configured properly, since we built and tested the image.


Next: [Terraform](05-terraform.md)
