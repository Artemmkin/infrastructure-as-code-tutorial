# Scripts

In the previous lab, you deployed the [raddit](https://github.com/Artemmkin/raddit) application by connecting to a VM via SSH and running commands in the terminal one by one. In this lab, we'll try to automate this process a little by using `scripts`.

## Intro

Now think about what happens if your application becomes so popular that one virtual machine can't handle all the load of incoming requests. Or what happens when your application somehow crashes? Debugging a problem can take a long time and it would most likely be much faster to launch and configure a new VM than trying to fix what's broken.

In all of these cases we face the task of provisioning new virtual machines, installing the required software and repeating all of the configurations we've made in the previous lab over and over again.

Doing it manually is `boring`, `error-prone` and `time-consuming`.

The most obvious way for improvement is using Bash scripts which allow us to run sets of commands put in a single file. So let's try this.

## Provision Compute Resources

Start a new VM for this lab. The command should look familiar:

```bash
$ gcloud compute instances create raddit-instance-3 \
    --image-family ubuntu-1604-lts \
    --image-project ubuntu-os-cloud \
    --boot-disk-size 10GB \
    --machine-type n1-standard-1
```

## Infrastructure as Code project

Starting from this lab, we're going to use a git repo for saving all the work done in this tutorial.

Download a repo for the tutorial:

```bash
$ git clone https://github.com/Artemmkin/iac-tutorial.git
```

Delete git information about a remote repository:
```bash
$ cd ./iac-tutorial
$ git remote remove origin
```

Create a directory for this lab:

```bash
$ mkdir scripts
```

## Configuration script

Before we can run our application, we need to create a running environment for it by installing dependent packages and configuring the OS.

We are going to use the same commands we used before to do that, but this time, instead of running commands one by one, we'll create a `bash script` to save us some struggle.

Create a bash script to install Ruby, Bundler and MongoDB, and copy a systemd unit file for the application.

Save it to the `configuration.sh` file inside created `scripts` directory:

```bash
#!/bin/bash
set -e

echo "  ----- install ruby and bundler -----  "
apt-get update
apt-get install -y ruby-full build-essential
gem install --no-rdoc --no-ri bundler

echo "  ----- install mongodb -----  "
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E52529D4
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-4.0.list'
apt-get update
apt-get install -y mongodb-org

echo "  ----- start mongodb -----  "
systemctl start mongod
systemctl enable mongod

echo "  ----- copy unit file for application -----  "
wget https://gist.githubusercontent.com/Artemmkin/ce82397cfc69d912df9cd648a8d69bec/raw/7193a36c9661c6b90e7e482d256865f085a853f2/raddit.service
mv raddit.service /etc/systemd/system/raddit.service
```

## Deployment script

Create a script for copying the application code from GitHub repository, installing dependent gems and starting it.

Save it into `deploy.sh` file inside `scripts` directory:

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

Copy the `scripts` directory to the created VM:

```bash
$ INSTANCE_IP=$(gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe raddit-instance-3)
$ scp -r ./scripts raddit-user@${INSTANCE_IP}:/home/raddit-user
```

Connect to the VM via SSH:
```bash
$ ssh raddit-user@${INSTANCE_IP}
```

Run the scripts:
```bash
$ chmod +x ./scripts/*.sh
$ sudo ./scripts/configuration.sh
$ ./scripts/deploy.sh
```

## Access the Application

Access the application in your browser by its public IP (don't forget to specify the port 9292).

Open another terminal and run the following command to get a public IP of the VM:

```bash
$ gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe raddit-instance-3
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
