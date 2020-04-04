# Scripts

In the previous lab, you deployed the [raddit](https://github.com/Artemmkin/raddit) application by connecting to a VM via SSH and running commands in the terminal one by one. In this lab, we'll try to automate this process a little by using `scripts`.

## Intro

Now think about what happens if your application becomes so popular that one virtual machine can't handle all the load of incoming requests. Or what happens when your application somehow crashes? Debugging a problem can take a long time and it would most likely be much faster to launch and configure a new VM than trying to fix what's broken.

In all of these cases we face the task of provisioning new virtual machines, installing the required software and repeating all of the configurations we've made in the previous lab over and over again.

Doing it manually is boring, error-prone and time-consuming.

The most obvious way for improvement is using Bash scripts which allow us to run sets of commands put in a single file. So let's try this.

## Infrastructure as Code project

Starting from this lab, we're going to use a git repo for saving all the work done in this tutorial.

Go to your Github account and create a new repository called my-iac-repo. No README or .gitignore. Copy the URL. 

Clone locally: 

```bash
$ git clone <Github URL of your new repository>
```

Create a directory for this lab:

```bash
$ cd my-iac-repo
$ mkdir script
```

To push your changes up to Github: 

```bash
$ git add . -A
$ git commit -m "some message"
$ git push origin master
```

Always issue these commands several times during each session. 

## Provisioning script

We can automate the process of creating the VM and the firewall rule. 

In the `script` directory create a directory `provision`. 

Create a script `provision.sh`: 

```bash
#!/bin/bash
# add new VM
gcloud compute instances create raddit-instance-3 \
    --image-family ubuntu-1604-lts \
    --image-project ubuntu-os-cloud \
    --boot-disk-size 10GB \
    --machine-type n1-standard-1

# add firewall rule
gcloud compute firewall-rules create allow-raddit-tcp-9292 \
    --network default \
    --action allow \
    --direction ingress \
    --rules tcp:9292 \
    --source-ranges 0.0.0.0/0
```

Run it in the Google Cloud Shell: 

```bash
$ chmod +x provision/provision.sh
$ ./provision/provision.sh
```

You should see results similar to: 

```bash
WARNING: You have selected a disk size of under [200GB]. This may result in poor I/O performance. For more information, see: https://developers.google.com/compute/docs/disks#performance.
Created [https://www.googleapis.com/compute/v1/projects/proven-sum-252123/zones/us-central1-c/instances/raddit-instance-3].
NAME               ZONE           MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP   STATUS
raddit-instance-3  us-central1-c  n1-standard-1               10.128.0.58  34.71.103.20  RUNNING
Creating firewall...⠹Created [https://www.googleapis.com/compute/v1/projects/proven-sum-252123/global/firewalls/allow-raddit-tcp-9292].
Creating firewall...done.
NAME                   NETWORK  DIRECTION  PRIORITY  ALLOW     DENY  DISABLED
allow-raddit-tcp-9292  default  INGRESS    1000      tcp:9292        False
```


## Configuration script

Before we can run our application, we need to create a running environment for it by installing dependent packages and configuring the OS.

We are going to use the same commands we used before to do that, but this time, instead of running commands one by one, we'll create a `bash script` to save us some struggle.

In the `script` directory create a directory `config`.

Create a bash script to install Ruby, Bundler and MongoDB, and copy a systemd unit file for the application.

Save it to the `configuration.sh` file inside created `config` directory:

```bash
#!/bin/bash
set -e

echo "  ----- install ruby and bundler -----  "
apt-get update
apt-get install -y ruby-full build-essential
gem install --no-rdoc --no-ri bundler

echo "  ----- install mongodb -----  "
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list
apt-get update
apt-get install -y mongodb-org --allow-unauthenticated

echo "  ----- start mongodb -----  "
systemctl start mongod
systemctl enable mongod

echo "  ----- copy unit file for application -----  "
wget https://gist.githubusercontent.com/Artemmkin/ce82397cfc69d912df9cd648a8d69bec/raw/7193a36c9661c6b90e7e482d256865f085a853f2/raddit.service
mv raddit.service /etc/systemd/system/raddit.service
```

## Deployment script

Create a script for copying the application code from GitHub repository, installing dependent gems and starting it.

Save it into `deploy.sh` file inside `config` directory:

```bash
#!/bin/bash
set -e

echo "  ----- clone application repository -----  "
git clone https://github.com/Artemmkin/raddit.git

echo "  ----- install dependent gems -----  "
cd ./raddit
sudo bundle install

echo "  ----- start the application -----  "
sudo systemctl start raddit
sudo systemctl enable raddit
```

## Run the scripts

Copy the `config` directory to the created VM (you need to be in the `scripts` directory, or else make adjustments to your paths:

```bash
$ INSTANCE_IP=$(gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe raddit-instance-3)
$ scp -r ./config raddit-user@${INSTANCE_IP}:/home/raddit-user
```
NOTE: If you get an `offending ECDSA key` error, use the suggested removal command. 

NOTE: If you get the error `Permission denied (publickey).`, this probably means that your ssh-agent no longer has the raddit-user private key added. This easily happens if the Google Cloud Shell goes to sleep and wipes out your session. Check via issuing `ssh-add -l`. 

If you get a message to the effect that your agent is not running, type ``eval `ssh-agent` `` and then `ssh-add -l`.
You should see something like `2048 SHA256:bII5VsQY3fCWXEai0lUeChEYPaagMXun3nB9U2eoUEM /home/betz4871/.ssh/raddit-user (RSA)`. If you do not, re-issue the command `ssh-add ~/.ssh/raddit-user` and re-confirm with `ssh-add -l`.


Connect to the VM via SSH:
```bash
$ ssh raddit-user@${INSTANCE_IP}
```

Run the scripts:
```bash
$ chmod +x ./config/*.sh
$ sudo ./config/configuration.sh
$ ./config/deploy.sh
```

## Access the Application

Access the application in your browser by its public IP (don't forget to specify the port 9292).

Open another terminal and run the following command to get a public IP of the VM:

```bash
$ gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe raddit-instance-3
```

## Destroy (de-provision) the resources by script

In the `provision` directory create a script `deprovision.sh`. 

```bash
#!/bin/bash
gcloud compute instances delete -q raddit-instance-3
gcloud compute firewall-rules delete -q allow-raddit-tcp-9292 
```

Set permissions correctly (see previous) and execute. You should get results like:

```bash
Deleted [https://www.googleapis.com/compute/v1/projects/proven-sum-252123/zones/us-central1-c/instances/raddit-instance-3].
Deleted [https://www.googleapis.com/compute/v1/projects/proven-sum-252123/global/firewalls/allow-raddit-tcp-9292].
```

## Save and commit the work

Save and commit the scripts created in this lab into your `iac-tutorial` repo.


## Conclusion

Scripts helped us to save some time and effort of manually running every command one by one to configure the system and start the application.

The process of system configuration becomes more or less standardized and less error-prone, as you put commands in the order they should be run and test it to ensure it works as expected.

It's also a first step we've made in the direction of automating operations work.

But scripts are not suitable for every operations task and have many downsides. We'll discuss more on that in the next labs.

Destroy the current VM before moving onto the next step:

```bash
$ gcloud compute instances delete raddit-instance-3
```

Next: [Packer](04-packer.md)
